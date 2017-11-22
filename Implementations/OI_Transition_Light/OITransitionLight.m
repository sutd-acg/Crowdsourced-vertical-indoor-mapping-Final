%{
     Omidreza Moslehirad
     Munich, Autumn 2017
     

 This function  performs  three   methodologies:  Hysteresis  thresholding,
 Otsu's method, and finding abrupt changes  via findchangepts() function to 
 separate light signal into two main  parts: INDOORs and 'OUTDOORs'. 
 At the end, we notice that the third method gives more  accurate  results. 
 We used the Otsu's result as  a guiding  blueprint for  the  third method, 
 where we assigned indoor or outdoor to each segment of the  third method's
 binary classification result. In case of  sparse  light  signal (in pocket
 scenario),  we  can  use  Otsu result of geolocation uncertainty as a blue 
 print.
--------------------------------------------------------------------------

 Inputs: 

    The light *.csv file must be in the main folder.
          
    bounding_th:    To reduce all the light values over  this  threshold to 
                    bounding_th. The default value is 2000 lx.
    in_out_filt:    To filter low amplitude outliers  from indoor / outdoor 
                    parts of the  signal. For  example, when we are indoor,
                    we receive some unwanted outliers from the light coming
                    from the windows. To  increase  accuracy  of hysteresis 
                    thresholding, it is better to find a simple  threshold.
                    The  default  threshold  is  1.9  in the max(smoth)/1.9
                    formula, where smoth is the  smoothed   version of  the 
                    signal after applying the bounding_th on the raw signal.
    
    temp_numc:      Maximum number of expected change points in the signal. 
                  

 Outputs:
          B1: Hysteresis Binary Classification Result. 
          B2: Otsu's Method Binary Classification Result.
          B3: Fusion of Hysteresis and Otsu Binary Classification.
          B4: Final classification result! (change point analysis).

          light_raw:             Raw light signal.
          corrected_raw_light:   Raw light below the bounding_th.
          original_smoth:        Smooth of light_raw.
          somth:                 Smooth of corrected_raw_light.
          smoth_2:               smoth after removal of indoor outliers 
                                 using in_out_filt.
          xi,f:                  Parameters  of  smoothed  kernel  density,
                                 used for peak analysis of histogram.
          I, gray_th, level:     Light signal is converted to 1D gray image
                                 for estimation of binary threshold via the
                                 Otsu's method. 'I' is the image, 'gray_th'
                                 is the estimated threshold, and 'level' is
                                 scaled version of the gray_th in the light
                                 signal.
    
--------------------------------------------------------------------------

 Example: 

 [light_raw,corrected_raw_light,original_smoth,smoth,smoth_2,xi,f,B1,B2,B3,B4,I,gray_th,level] = ...
   OITransitionLight();

--------------------------------------------------------------------------
 Hysteresis Thresholding:

 We  need   to find  an  effective  way  of  detecting  major edges in the 
 uncertainty signal. We usually have very large  edge in  the  uncertainty 
 signal during outdoor-indoor transitions.

 Hysteresis needs two thresholds: high and low.

 In a recursive manner, any value in the input signal over 'high' as  well
 as 'low' will be assigned as '0', while  the rest of the  signal  will be
 preserved or stretched. This means that for  indoor parts,  we would have
 '0' values. However, for binary classification, we prefer to have logical
 'True' values for indoors. The solution is simple. We just need to define
 a Zero vector and set its corresponding  indexes  for  indoors to 1. This
 will produce the binary classifier, where indoors  have '1s' and outdoors
 '0s'.

--------------------------------------------------------------------------
 Otsu's Method:

 It is an image  processing  method, which  converts a gray  image  into a 
 binary image. We need to give it an intial threshold (level). 
 
 We  can  look  at   the  uncertainty  signal  like a gray image, but with 
 different scale. Since outdoor parts of uncertainty signal is more stable
 than  indoor  parts, we  set a  simple  threshold  of 'level = 15m'. This
 function  will  assign '0' to  values lower than the threshold and '1' to
 the  higher  values  in an efficient way. As a result, we directly obtain
 the binary classifier for separation of signal into outdoors and indoors.

--------------------------------------------------------------------------
Find Change Points:
 
 For estimation of abrupt  changes in light signal.  For our classification
 problem, first we estimate number of change points  in  the  final  binary
 classification result of Otsu's method. This can  help to  estimate number
 of change points (numc) in the light signal. In another words,  we do this
 because we do not know from the beginning how many times user  has entered
 or exited from the  building. After finding the change points in the light
 signal, we segment the  binary  result  of Otsu's  method via  the  change
 points of light signal. If the mean value of a segment is smaller than 0.5,
 then corresponding segment in the light signal is indoor (day).

%}

function [light_raw,corrected_raw_light,original_smoth,smoth,smoth_2,xi,f,B1,B2,B3,B4,I,gray_th,level] = ...
   OITransitionLight(bounding_th, in_out_filt, temp_numc)
% If some inputs are not given by the user, set default values:

clc
clear variables;
close all;

switch nargin
    case 0
        bounding_th = 2000; 
        in_out_filt = 1.9;
        temp_numc = 10;
    case 1
        in_out_filt = 1.9;
        temp_numc = 10;
    case 2
        temp_numc = 10;
end

%% Read the Light dataset
% Please note that there must be only one light *.csv in the main folder.
light_file_name = dir('*.csv');
temp = xlsread(light_file_name.name);
%temp2= unique(temp,'rows');
light_raw = temp(:,2);

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

% Plot raw light and its smoothed curve
figure
plot(light_raw, 'LineWidth',1)
title('Light','FontSize', 20)
xlabel('Number of Samples','FontSize', 20)
ylabel('light [lx]','FontSize', 20)
hold on
plot(original_smoth,'LineWidth',2)
legend({'Light Raw','Light Smoothed(Gaussian)'},'FontSize', 15)
set(gca,'fontsize',20)
%% Histogram Analysis
% During the day: The first peak of the histogram (ks density), is an
% emphasize on indoor part of the signal.
%
% During Night: The first peak is an emphasize on outdoor part of signal.
%
% We do not need to analyse the other peaks, only the first peak!

figure
histogram_raw = histogram(smoth);

% Plot the histogram
figure
yyaxis('left')
histogram(smoth,50,'Normalization','probability')
title('Histogram and Kernel Smoothing Density')
pts = 0 : 1 : max(smoth);
[f,xi] = ksdensity(smoth,pts);
ylabel('Frequency','FontSize',20 )
hold on
f=imgaussfilt(f,2);
yyaxis('right')
plot(xi,f,'LineWidth',2)
xlabel('Uncertainty [m]','FontSize',20)
ylabel('Probability','FontSize',20)
legend({'Frequency','KS Density'},'FontSize',20)
set(gca,'fontsize',20)

[p1,p2]=findpeaks(f); % Find peaks over the smoothed density

% This can be used later to determine if the dataset is from day or night:
hist_width = histogram_raw.BinLimits; 

%% Hysteresis Analysis of Light Signal
% We  need  to determine  initial low  and  high  thresholds for hysteresis
% function.
%
% Initial low: This can be determined from the first peak of the histogram. 
% 
% Initial high: about 1/1.9 of maximum value of somth. 

% To remove some small outliers from indoor areas(day) or outdoor areas(night)
% we replace any sample lower than 1/1.9 * max(smoth) with '0'.
smoth_2 = smoth;
smoth_2(smoth < (max(smoth)/in_out_filt))=0;

init_low = p1(1); % Initial low, first peak of density signal
init_high = ceil(max(smoth)/in_out_filt); % Initial high

% Recursive hysteresis analysis. We increase the gap between low and high
% thresholds by 2 at each loop.
test = smoth_2; % output of recursive hyszeresis
 ii = init_low;
   for jj = init_high : ceil(max(smoth_2))
    if ii> 0
      morphed_light = hysteresis(test,ii,jj);
      ii = ii-1;
      test = morphed_light;
    else
      morphed_light = hysteresis(test,1,jj);
      test = morphed_light;  
    end
   end
   
% Night: If the dataset is from night time
if hist_width(2) <= 600 % along horizontal axis of histogram 
  test(test >=1) = 1;
  B1 = test; % final binary classification result of hysteresis method
end

% Day: if the dataset is from day time
if hist_width(2)>600
  test(test >=1) = 1;
  B1 = ones(size(test));
  B1(test ==1) = 0; % final binary classification result of hysteresis method
end
  
figure
title('Hysteresis of Light','FontSize',20)
yyaxis('left')
plot(original_smoth, 'LineWidth',2)
ylabel('Light [lx]', 'FontSize',20)
xlabel('Number of samples','FontSize',20)
hold on
yyaxis('right')
plot(B1,'black','LineWidth',2);
ylabel('Binary Classification', 'FontSize',20)
legend({'Smoothed Light','Binary Classification'},'FontSize',20)
ylim([-0.01 2])
set(gca,'fontsize',20)

%% Alternative to Hysteresis: Global image threshold using Otsu's method
% We look at the light signal as a one dimensional gray image.
% We want to convert it into a binary image using a threshold.
I = mat2gray(smoth,[0 max(smoth)]);
gray_th = graythresh(I);
level = gray_th * max(smoth);

figure
subplot(2,1,1)
plot(I, 'LineWidth',2)
xlabel('Number of samples')
ylabel('Gray Value')
hold on
om = ones(size(smoth)).*gray_th;
plot(om')
legend('1D gray image','Gray level')
subplot(2,1,2)
plot(smoth, 'LineWidth',2)
xlabel('Number of samples')
ylabel('Light lx')
hold on
om2 = ones(size(smoth)).*level;
plot(om2')
legend('Smoothed Light', 'Otsu Method Level')



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

figure
yyaxis('left')
title('Otsu Methood','FontSize', 20)
plot(original_smoth, 'LineWidth',1)
xlabel('Number of Samples','FontSize', 20)
ylabel('light [lx]','FontSize', 20)
hold on
yyaxis('right')
plot(B2,'LineWidth',2)
legend({'Light Raw','Binary Result of Otsu Method'},'FontSize', 20)
ylabel('Binary Classification','FontSize', 20)
ylim([-0.01 2])
set(gca,'fontsize',20)

%% We fuse the results of Hysteresis and Otsu
% For fusion, AND operator is used because the results of these two methods
% are similar.

B3 = and(B1 , B2);

figure
yyaxis('left')
title('Fusion of Hysteresis and Otsu','FontSize', 20)
plot(original_smoth,'LineWidth',2)
yyaxis('left')
ylabel('Log2(light[lx])')
xlabel('Number of samples','FontSize', 20)
hold on
yyaxis('right')
plot(B3)
ylabel('Binary Classification','FontSize', 20)
legend({'Smoothed Light','Binary Classification'},'FontSize', 15)
ylim([-0.01 2])


%% Plot all results in subplots

figure
subplot(3,1,1)
title('Hysteresis')
yyaxis('left')
plot(log2(smoth),'blue-','LineWidth',2.5)
ylabel('Log2(light[lx])')
xlabel('Number of samples','FontSize', 13)
hold on
yyaxis('right')
plot(B1,'r-','LineWidth',1)
ylabel('Bin. Cl.')
xlabel('Number of samples','FontSize', 13)
ylim([-0.01 2])
subplot(3,1,2)
title('Otsu')
yyaxis('left')
plot(log2(smoth),'blue-','LineWidth',2.5)
ylabel('Log2(light[lx])')
hold on
yyaxis('right')
plot(B2,'r-','LineWidth',1)
ylabel('Bin. Cl.')
xlabel('Number of samples','FontSize', 13)
ylim([-0.01 2])
subplot(3,1,3)
title('Fusion of Hyster. and Otsu')
yyaxis('left')
plot(log2(smoth),'blue-','LineWidth',2.5)
ylabel('Log2(light[lx])')
hold on
yyaxis('right')
plot(B3,'r-','LineWidth',1)
ylabel('Bin. Cl.')
xlabel('Number of samples','FontSize', 13)
ylim([-0.01 2])

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
    B4 = zeros(size(smoth));
    
    switch length(q)
        case 1
          s1 = smt(1:q(1));
          w1 = mean(s1);
          s2 = smt(q(1)+1:end);
          w2 = mean(s2);
          if w1 > w2
              B4(1:q(1)) = 1;
          else
              B4(q(1)+1:end) = 1;
          end
        case 2
          if mean(Otsu_Binary_Result(1:q(1))) > 0.5
              B4(1:q(1)) = 1;
          end
          if mean(Otsu_Binary_Result(q(1)+1:q(2))) > 0.5
              B4(q(1)+1:q(2)) = 1;
          end
          if mean(Otsu_Binary_Result(q(2)+1:end)) > 0.5
              B4(q(2):end) = 1;
          end 
    end
    
    if length(q) > 2
       if mean(Otsu_Binary_Result(1:q(1))) > 0.5
              B4(1:q(1)) = 1;
       end
           for i = 1 : length(q)-1
              if mean(Otsu_Binary_Result(q(i)+1:q(i+1))) > 0.5
                 B4(q(i)+1:q(i+1)) = 1;
              end 
           end
       if mean(Otsu_Binary_Result(q(i+1)+1:end)) > 0.5
              B4(q(i+1)+1:end) = 1;
       end  
       
   end
end

% Day
if hist_width(2)>600
    
   B4 = ones(size(smoth));
   
   switch length(q)
        case 1
          s1 = smt(1:q(1));
          w1 = mean(s1);
          s2 = smt(q(1)+1:end);
          w2 = mean(s2);
          if w1 > w2
              B4(1:q(1)) = 0;
          else
              B4(q(1)+1:end) = 0;
          end
         case 2
          if mean(Otsu_Binary_Result(1:q(1))) > 0.5
              B4(1:q(1)) = 0;
          end
          if mean(Otsu_Binary_Result(q(1)+1:q(2))) > 0.5
              B4(q(1)+1:q(2)) = 0;
          end
          if mean(Otsu_Binary_Result(q(2)+1:end)) > 0.5
              B4(q(2)+1:end) = 0;
          end    
   end 
   
   if length(q) > 2
       if mean(Otsu_Binary_Result(1:q(1))) > 0.5
              B4(1:q(1)) = 0;
       end
           for i = 1 : length(q)-1
              if mean(Otsu_Binary_Result(q(i)+1:q(i+1))) > 0.5
                 B4(q(i)+1:q(i+1)) = 0;
              end 
           end
       if mean(Otsu_Binary_Result(q(i+1)+1:end)) > 0.5
              B4(q(i+1)+1:end) = 0;
       end  
       
   end
    
end

figure
title('Final Binary Classification', 'FontSize',20)
yyaxis('left')
plot (light_raw)
xlabel('Number of Samples','FontSize',20)
ylabel('Light [lx]','FontSize',20)
hold on
yyaxis('right')
plot(B4)
ylabel('Binary Classification','FontSize',20)
ylim([-0.01 2])
set(gca,'fontsize',20)
legend({'Light Signal','Binary Result'},'FontSize',15)
end