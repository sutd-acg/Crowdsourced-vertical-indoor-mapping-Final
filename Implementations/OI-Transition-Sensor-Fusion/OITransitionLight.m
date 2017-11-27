%{
     Omidreza Moslehirad
     Munich, Autumn 2017

     Inputs: 

          bounding_th:    Bounding Threshold for rejecting very high light
                          values.
          temp_numc:      Temporary predicted number of change points.

     Outputs:

   final_interpolated_light_with_flags:  nx3  matrix of time,
                                         interpolated light uncertainty and
                                         binary classification result.
%}

function [final_interpolated_light_with_flags] = ...
   OITransitionLight(bounding_th, temp_numc)
% If some inputs are not given by the user, set default values:

switch nargin
    case 0
        bounding_th = 2000; 
        temp_numc = 10;
    case 1
        temp_numc = 10;
end

%% Read the Light dataset
% Please note that there must be only one light *.csv in the main folder.
light_file_name = dir('./OI_Light/Adel13_A/Build4Light.csv');
temp = xlsread(light_file_name.name);
temp2= unique(temp,'rows');
%temp2= unique(temp,'rows');
light_raw = temp2(:,2);

%% Smooth the light by Gaussian filter
% Sometimes,  due to very high amount of light illumination by the sun, the
% light sensor records sudden high values, which are  not very necessary to
% observe for OI Transitions.  We  reduce all values higher than 2000 lx to
% default value of 2000 lx. This can also increase  the  performance of the 
% algorithm. 
corrected_raw_light = light_raw;
corrected_raw_light(corrected_raw_light >= bounding_th) = bounding_th;
original_smoth = imgaussfilt(light_raw, 150);
smoth = imgaussfilt(corrected_raw_light, 150);

%% Alternative to Hysteresis: Global image threshold using Otsu's method
% We look at the light signal as a one dimensional gray image.
% We want to convert it into a binary image using a threshold.
I = mat2gray(smoth,[0 max(smoth)]);
gray_th = graythresh(I);
level = gray_th * max(smoth);


histogram_raw = histogram(smoth);
hist_width = histogram_raw.BinLimits;

% Night:
if hist_width(2)<= 600 
  Otsu_Binary_Result = imbinarize(smoth,10);
  B2 = Otsu_Binary_Result;
end

% Day
if hist_width(2)>600
  Otsu_Binary_Result = imbinarize(smoth,level); 
  B2 = ~Otsu_Binary_Result;
end

%% Change point analysis
% If from the beginning,we know how many times user entered and  exit  from
% the building, we can determine transition points with high accuracies via
% findchangepts() function. However, it is not known in  practice unless  a
% human supervision becomes  involved.  For example, the  data  analyst can
% observe  gps  and  light  data sets  visually  and  tells  how  many  the 
% trnsition ponts are. In this code, we automated the estimation of change
% points via the result of Otsu's method.
% 
%
% Example: if usere entered or exit from the building in total 2 times:
%
% numc = 2;
% [q,r] = findchangepts(light_raw,'Statistic','rms','MaxNumChanges',numc);
%
% where, 'q' is the vector of detected change points along the signal.
%
% To automate estimation of number of change points, as  mentioned  before, 
% we run the findchangepts() on B2 with maximum default change point number
% of temp_numc. The  default   value is 10,  but e.g.  if the B1 has only 4
% transition points, the findchangepts function will find  exactly 4 change
% points because it works very well over binary signals.
[q_temp,r_temp] = findchangepts(double(B2),'Statistic','rms','MaxNumChanges',temp_numc);

% After estimating number of transitions from Otsu's method, we run
% findchangepts() again, but over the main light signal, based on estimated
% number of transition points
numc = length(q_temp); % to find number of change points
smt = imgaussfilt(light_raw,30);
findchangepts(smt,'Statistic','rms','MaxNumChanges',numc); % only for plot
[q,r]=findchangepts(smt,'Statistic','rms','MaxNumChanges',numc); % to save the results

% We need to use 'q' for computation of final binary classification. 

% Night:
if hist_width(2)<= 600 
    Binary_light = zeros(size(smoth));
    
    switch length(q)
        case 1
          s1 = smt(1:q(1));
          w1 = mean(s1);
          s2 = smt(q(1)+1:end);
          w2 = mean(s2);
          if w1 > w2
              Binary_light(1:q(1)) = 1;
          else
              Binary_light(q(1)+1:end) = 1;
          end
        case 2
          if mean(Otsu_Binary_Result(1:q(1))) > 0.5
              Binary_light(1:q(1)) = 1;
          end
          if mean(Otsu_Binary_Result(q(1)+1:q(2))) > 0.5
              Binary_light(q(1)+1:q(2)) = 1;
          end
          if mean(Otsu_Binary_Result(q(2)+1:end)) > 0.5
              Binary_light(q(2):end) = 1;
          end 
    end
    
    if length(q) > 2
       if mean(Otsu_Binary_Result(1:q(1))) > 0.5
              Binary_light(1:q(1)) = 1;
       end
           for i = 1 : length(q)-1
              if mean(Otsu_Binary_Result(q(i)+1:q(i+1))) > 0.5
                 Binary_light(q(i)+1:q(i+1)) = 1;
              end 
           end
       if mean(Otsu_Binary_Result(q(i+1)+1:end)) > 0.5
              Binary_light(q(i+1)+1:end) = 1;
       end  
       
   end
end

% Day
if hist_width(2)>600
    
   Binary_light = ones(size(smoth));
   
   switch length(q)
        case 1
          s1 = smt(1:q(1));
          w1 = mean(s1);
          s2 = smt(q(1)+1:end);
          w2 = mean(s2);
          if w1 > w2
              Binary_light(1:q(1)) = 0;
          else
              Binary_light(q(1)+1:end) = 0;
          end
         case 2
          if mean(Otsu_Binary_Result(1:q(1))) > 0.5
              Binary_light(1:q(1)) = 0;
          end
          if mean(Otsu_Binary_Result(q(1)+1:q(2))) > 0.5
              Binary_light(q(1)+1:q(2)) = 0;
          end
          if mean(Otsu_Binary_Result(q(2)+1:end)) > 0.5
              Binary_light(q(2)+1:end) = 0;
          end    
   end 
   
   if length(q) > 2
       if mean(Otsu_Binary_Result(1:q(1))) > 0.5
              Binary_light(1:q(1)) = 0;
       end
           for i = 1 : length(q)-1
              if mean(Otsu_Binary_Result(q(i)+1:q(i+1))) > 0.5
                 Binary_light(q(i)+1:q(i+1)) = 0;
              end 
           end
       if mean(Otsu_Binary_Result(q(i+1)+1:end)) > 0.5
              Binary_light(q(i+1)+1:end) = 0;
       end  
       
   end
    
end



x_temp_light = temp2(:,1);
v_temp_light = temp2(:,2);
xq_temp_light = temp2(1,1):1:temp2(length(temp2),1); 
 
interpolated_light = interp1(x_temp_light,v_temp_light,xq_temp_light');

interpolated_flag_light = interp1(x_temp_light,Binary_light,xq_temp_light');

final_interpolated_light_with_flags = horzcat(xq_temp_light',interpolated_light);
final_interpolated_light_with_flags = horzcat(final_interpolated_light_with_flags,interpolated_flag_light);


figure
plot(final_interpolated_light_with_flags(:,1),final_interpolated_light_with_flags(:,2))
hold on
yyaxis('right')
plot(final_interpolated_light_with_flags(:,1),final_interpolated_light_with_flags(:,3))




end