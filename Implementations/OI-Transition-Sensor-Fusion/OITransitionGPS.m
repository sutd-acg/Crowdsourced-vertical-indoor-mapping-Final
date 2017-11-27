%{
     Omidreza Moslehirad     Munich, Autumn 2017
     
     inputs:
       level:          Otsu's level
       bounding_th:    Bounding threshold of 70m
       temp_numc:      temporary predicted number of change points


     outputs:
       final_interpolated_gps_with_flags:  nx3  matrix of time,
                                           interpolated GPS uncertainty and
                                           binary classification result.

%}

function [final_interpolated_gps_with_flags] = ...
    OITransitionGPS(level,bounding_th,temp_numc)

% If some inputs are not given by the user, set default values
switch nargin
    case 0
        level = 15; 
        bounding_th = 70;
        temp_numc = 10;
    case 1
        bounding_th = 70;
        temp_numc = 10;
    case 2
        temp_numc = 10;
end


%% Read the Geolocation Dataset
% Read entire directory for *.csv files, store them in a struct.
% In this directory, you must put only the GPS file you want to process.
% Retrieve the file content, store it in an array.
raw_data = xlsread('./OI_GPS/TUM/My_TUM_MAY27Geolocation.csv');
% Extract the 'Uncertainty' column.
% uncertainty_raw = raw_data(:,4);
unique_raw_GPS= unique(raw_data,'rows'); % using unique here looses lots of data!

% Definition of bounding box threshold:
% bounding_th = 70; 
uncertainty_raw = unique_raw_GPS(:,4);
uncert_bbxed = uncertainty_raw;
uncert_bbxed(uncertainty_raw > bounding_th) = bounding_th;

smoth = imgaussfilt(uncert_bbxed,2); % Apply Gaussian filter.

%% Alternative to Hysteresis: Global image threshold using Otsu's method
% We look at the Uncertainty signal as a one dimensional gray image
% We want to convert it into a binary image using a threshold
% The default level (threshold) is 15m

% level =15;
B2 = imbinarize(smoth,level); 




%% Change point analysis
% If from the beginning,we know how many times user entered and  exit  from
% the building, we can determine transition points with high accuracies via
% findchangepts() function. However, it is not known in  practice unless  a
% human supervision becomes  involved.  For example, the  data  analyst can
% observe  gps  and  light  data sets  visually  and  tells  how  many  the 
% trnsition ponts are. In this code, we automated the estimation of  change
% points via the result of Otsu's method.
% 
%
% Example: if user entered or exit from the building in total 2 times:
%
% numc = 2;
% [q,r] = findchangepts(smoth,'Statistic','rms','MaxNumChanges',numc);
%
% where, 'q' is the vector of detected change points along the signal.
%
% To automate estimation of number of change points, as  mentioned  before, 
% we run the findchangepts() on B2 with maximum default change point number
% of temp_numc. The  default   value is 10,  but e.g.  if the B2 has only 4
% transition points, the findchangepts function will find  exactly 4 change
% points because it works very well over binary signals.
% temp_numc = 10;
[q_temp,r_temp] = findchangepts(double(B2),'Statistic','rms','MaxNumChanges',temp_numc);

% After estimating number of transitions from Otsu's method, we run 
% findchangepts() again, but over the main  gps  signal, based on estimated
% number of transition points
numc = length(q_temp); % to find number of change points.
findchangepts(smoth,'Statistic','rms','MaxNumChanges',numc); % only for plot.
[q,r]=findchangepts(smoth,'Statistic','rms','MaxNumChanges',numc); % to save the outputs.
% We need to use 'q' for computation of final binary classification. 

% Final classification result initialization:
Binary_gps = zeros(size(smoth)); 
    
    switch length(q)
        case 1
          s1 = smoth(1:q(1));
          w1 = mean(s1);
          s2 = smoth(q(1)+1:end);
          w2 = mean(s2);
          if w1 > w2
              Binary_gps(1:q(1)) = 1;
          else
              Binary_gps(q(1)+1:end) = 1;
          end
        case 2
          if mean(B2(1:q(1))) > 0.5 % A kind of fuzzy decision
              Binary_gps(1:q(1)) = 1;
          end
          if mean(B2(q(1)+1:q(2))) > 0.5
              Binary_gps(q(1)+1:q(2)) = 1;
          end
          if mean(B2(q(2)+1:end)) > 0.5
              Binary_gps(q(2):end) = 1;
          end 
    end   
    if length(q) > 2
       if mean(B2(1:q(1))) > 0.5
              Binary_gps(1:q(1)) = 1;
       end
           for i = 1 : length(q)-1
              if mean(B2(q(i)+1:q(i+1))) > 0.5
                 Binary_gps(q(i)+1:q(i+1)) = 1;
              end 
           end
       if mean(B2(q(i+1)+1:end)) > 0.5
              Binary_gps(q(i+1)+1:end) = 1;
       end         
   end


 x_temp_gps = unique_raw_GPS(:,1);
 v_temp_gps = unique_raw_GPS(:,4);
 xq_temp_gps = unique_raw_GPS(1,1):1:unique_raw_GPS(length(unique_raw_GPS),1); 
 
interpolated_gps = interp1(x_temp_gps,v_temp_gps,xq_temp_gps');

interpolated_flag_gps = interp1(x_temp_gps,Binary_gps,xq_temp_gps');

final_interpolated_gps_with_flags = horzcat(xq_temp_gps',interpolated_gps);
final_interpolated_gps_with_flags = horzcat(final_interpolated_gps_with_flags,interpolated_flag_gps);


figure
plot(final_interpolated_gps_with_flags(:,1),final_interpolated_gps_with_flags(:,2))
hold on
yyaxis('right')
plot(final_interpolated_gps_with_flags(:,1),final_interpolated_gps_with_flags(:,3))


end

