%{
     Omidreza Moslehirad     Munich, Autumn 2017
     

 This function  performs four  different methodologies: Hysteresis, Otsu, 
 simple thresholding, and change point analysis methods  to  separate GPS 
 uncertainty  signal  into two  main parts:  INDOORs  and  'OUTDOORs'. 
 At the end, we select two of the methods for final classification, which
 are Otsu's method and change point analysis. We use the Otsu's result as
 a guiding  blueprint for  the  change  point analysis  method,  where we 
 assigne indoor or outdoor  to each   segment  of  change  point analysis
 method's result.
--------------------------------------------------------------------------

 Inputs: 
          The Geolocation Uncertainty *.csv file must be in the main
          folder.
          
          bounding_th:  To filter unnecessary high amplitude  geolocation 
                        uncertainties. The default value is 70m.
          level:        Input threshold for Otsu's method. Default is 15m.
          simple_th:    Threshold for simple thresholding.
          temp_numc:    Maximum number of expected  change  points in the
                        signal.
 Outputs:
          B1: Hysteresis Binary Classification. 
          B2: Otsu's Method Binary Classification.
          B3: Fusion of Hysteresis and Otsu Binary Classification.
          B4: Simple Thresholding Binary Classification.
          B5: Fusion of Hysteresis, Otsu, and Simple Thresholding.
          B6: Final classification result.

          uncertainty_raw: Raw GPS Uncertainty signal.
          somth:           Smoothed GPS uncertainty signal.
          xi,f:            Parameters  of  smoothed  kernel  density, used
                           for peak analysis of histogram.
--------------------------------------------------------------------------

 Example: 
 
 level = 15; 
 simple_th = 13;
 bounding_th = 70;
 temp_numc = 10;
 [B1, B2 ,B3, B4, B5, B6, uncertainty_raw, smoth ,xi,f] = ...
    OITransitionGPS(level,simple_th,bounding_th,temp_numc) 

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
 Simple Thresholding:
 We set a simple threshold of e.g. 13m to  separate  outdoor  from  indoor
 areas.
%}
function [B1, B2 ,B3, B4, B5, B6, uncertainty_raw, smoth ,xi,f] = ...
    OITransitionGPS(level,simple_th,bounding_th,temp_numc)

% If some inputs are not given by the user, set default values
switch nargin
    case 0
        level = 15; 
        simple_th = 13;
        bounding_th = 70;
        temp_numc = 10;
    case 1
        simple_th = 13;
        bounding_th = 70;
        temp_numc = 10;
    case 2
        bounding_th = 70;
        temp_numc = 10;
    case 3
        temp_numc = 10;
end
%% Read the Geolocation Dataset
% Read entire directory for *.csv files, store them in a struct.
% In this directory, you must put only the GPS file you want to process.
gps_file_name = dir('*.csv');
% Retrieve the file content, store it in an array.
raw_data = xlsread(gps_file_name.name);
% Extract the 'Uncertainty' column.
uncertainty_raw = raw_data(:,4);

% to avoid sudden large uncertainty error when app starts data collection.
uncertainty_raw(1:2)=7; 

% Definition of bounding box threshold:
% bounding_th = 70; 
uncert_bbxed = uncertainty_raw;
uncert_bbxed(uncertainty_raw > bounding_th) = bounding_th;

%% Plot 'Uncertainty'and its smoothed curve via Gaussian Filter
smoth = imgaussfilt(uncert_bbxed,2); % Apply Gaussian filter.

figure
plot(uncertainty_raw, 'LineWidth',1)
title('Geolocation Uncertainy','FontSize', 20)
xlabel('Number of Samples','FontSize', 20)
ylabel('Uncertainty [m]','FontSize', 20)
hold on
plot(smoth,'LineWidth',2)
legend({'GPS Raw','GPS Smoothed(Gaussian)'},'FontSize', 15)
set(gca,'fontsize',20)

%% Histogram Analysis of Geolocation Uncertainty
% Plot histogram, then fit a smoothed curve on the  histogram  via  Kernel-
% Smoothed Density.
% We need only to observe the 'first peak'  of the  density  signal,  which
% emphasize  on  outdoor  GPS  uncertainty. The reason  is that in outdoor,
% GPS uncertainty  is  usually  almost  stable. After identification of the
% first peak, we can determine the initial 'low' and 'high'  thresholds for
% hysteresis function.

figure
histogram(smoth,50,'Normalization','probability')
title('Histogram and Kernel Smoothing Density')
pts = 0 : 0.1 : max(smoth);
[f,xi] = ksdensity(smoth,pts);
hold on
f=imgaussfilt(f,2);
plot(xi,f,'LineWidth',2)
xlabel('Uncertainty [m]','FontSize',20)
ylabel('Probability','FontSize',20)
legend({'Frequency','KS Density'},'FontSize',20)
set(gca,'fontsize',20)

[p1,p2]=findpeaks(f); % Find peaks over the smoothed density.
p2 = p2./10;

%% Hysteresis Analysis
% Select the first peak of the density signal for determination  of initial 
% 'low' and 'high' thresholds.
% We do not care about other peaks! Only first peak! 
% If the first peak of density occures between 5m and 20m, then we probably
% have outdoor samples  in  the signal, otherwise it is only indoor signal.
% We add (subtract) 5m to (from) this peak to identify  initial thresholds. 
% For instance, if  the  first  peak  happens  at  uncertainty of 14m, then 
% initial 'low = 14 - 5' and 'high = 14 + 5'. 
% At each loop of the following For-Loop, we increase the  distance between 
% low and high thresholds by 1m  for each thereshold. At the last loop, the 
% high thereshold will reach to maximum  uncertainty and low threshold will
% reach to zero uncertainty. Finally,indoor parts of the output signal will
% be equal to zero. We can simply  define  a binary classifier by setting a
% threshold of 1m to find indoor areas.

% The smoth will be morphed to a binary signal in the following.
morphed = smoth; 

% if the first peak of density  signal is  between 5 and  20m, then perform
% the hysteresis analysis recursively:
if p2(1)<20 && p2(1)> 5 
    gap = 5; % to be Added and subtracted from first peak
    ii = (p2(1) - gap);
   for jj = (p2(1) + gap):ceil(max(smoth))
    if ii> 0
      morphed_Uncert = hysteresis(morphed,ii,jj);
      ii = ii-1;
      morphed = morphed_Uncert;
    else
      morphed_Uncert = hysteresis(morphed,1,jj);
      morphed = morphed_Uncert;  
    end
   end
else 
    morphed = zeros(size(smoth)); % if the entire signal is from only indoor.
end

% Now the resulting signal (morphed) would have values of  '0'  for  indoor 
% areas. This can help us to detect edges at transition  points  with  good 
% accuracies.
% In the morphed vactor:
   % No zero: only outdoor
   % Only zero: only indoor
% This will be reversed later!

figure
title('Hysteresis Method','FontSize',20)
yyaxis('left')
plot(morphed,'black--','LineWidth',2.1)
hold on
plot(smoth,'LineWidth',1)
% We use values of zero in the variable 'morphed' as logical '1' for 
% indication of indoor areas. 
B1 = zeros(size(morphed)); % initialize binary classification.
% Set threshold of 1m to find indoor areas on  the  output  of  hysteresis-
% method (the signal 'morphed'):
th = 1; % 1m threshold
B1(morphed < th)=1; % indoor areas get  value of 1, while outdoors  stay 0.
yyaxis('right')
plot(B1,'LineWidth',2)
legend({'Hysteresis Result', 'GPS Uncertainty', 'Binary Hysteresis'},'FontSize',20)
ylim([-0.01 2])
ylabel('Binary Classification')
set(gca,'fontsize',20)

%% Alternative to Hysteresis: Global image threshold using Otsu's method
% We look at the Uncertainty signal as a one dimensional gray image
% We want to convert it into a binary image using a threshold
% The default level (threshold) is 15m

% level =15;
B2 = imbinarize(smoth,level); 

figure
yyaxis('left')
title('Otsu Methood','FontSize', 20)
plot(uncertainty_raw, 'LineWidth',1)
xlabel('Number of Samples','FontSize', 20)
ylabel('Uncertainty [m]','FontSize', 20)
hold on
yyaxis('right')
plot(B2,'LineWidth',2)
legend({'GPS Raw','Binary Result of Otsu Method'},'FontSize', 20)
ylabel('Binary Classification','FontSize', 20)
ylim([-0.01 2])
set(gca,'fontsize',20)
hold off

%% Now if we fuse the hysteresis result with Otsu's method result using AND operator:
B3=and(B1,B2);

figure
title('Fusion of Hysteresis and Otsu Methods (AND Operator)','FontSize',20)
xlabel('Number of samples','FontSize',20)
yyaxis('left')
plot(smoth,'LineWidth',2)
ylabel('Uncertainty [m]', 'FontSize',20)
hold on
yyaxis('right')
plot(B1,'g*','LineWidth',2.1)
plot(B2, 'black--','LineWidth',3)
plot(B3,'LineWidth',2.1)
ylabel('Binary Classification','FontSize',20)
ylim([-0.01 2])
legend({'Smoothed GPS', 'Only Hysteresis Method' 'Only Otsu Method', 'Fusion of Hysteresis and Otsu'},'Location','northwest','FontSize', 15)
set(gca,'fontsize',20)

%% Third method is simple thresholding
% We define a simple threshold of 13m
% Any values over this level is considered as indoor

% simple_th = 13;
B4 = zeros(size(smoth));
for k = 1:size(smoth)
    if smoth(k) > simple_th
        B4(k) = 1;
    end
end

figure 
title('Simple Thresholding: th = 13m', 'FontSize', 20)
yyaxis('left')
plot(smoth, 'LineWidth' , 2)
ylabel('Uncertainty [m]', 'FontSize', 20)
hold on
yyaxis('right')
plot(B4, 'LineWidth' , 2)
ylabel('Binary Classification', 'FontSize', 20)
ylim([-0.01 2])
set(gca,'fontsize',20)
legend({'Smoothed GPS', 'Binarry Classification'},'FontSize', 20)

%% Finally, the fusion of these 3 methods
% We use following formula:
% fusion = method1 AND (method2 OR method3) OR (method2 AND method3).
% This is a ranking formula based on what the majority of  these  3 methods
% suggest. For example, if at least 2 of the methods tell a sample  is  for 
% indoor, then it is indoor.
tem = bitand(B1,bitor(B2,B3));     
B5 = bitor(tem,bitand(B2,B3));

figure
title('Fusion of 3 Methods: Hysteresis, Otsu, and Simple Thresholding', 'FontSize', 15)
yyaxis('left')
plot(smoth, 'LineWidth',2)
ylabel('Uncertainty [m]', 'FontSize', 20)
hold on
yyaxis('right')
plot(B5, 'LineWidth',2)
ylim([-0.01 2])
ylabel('Binary Classification', 'FontSize', 20)
set(gca,'fontsize',20)
legend({'Smoothed GPS', 'Binarry Classification'},'FontSize', 20)

% Plot all classifier results:
figure
subplot(5,1,1)
title('Hysteresis')
yyaxis('left')
plot(log2(smoth),'blue-','LineWidth',2.5)
ylabel('Log2(Uncer.[m])')
hold on
yyaxis('right')
plot(B1,'r-','LineWidth',1)
ylabel('Bin. Cl.')
ylim([-0.01 2])
subplot(5,1,2)
title('Otsu')
yyaxis('left')
plot(log2(smoth),'blue-','LineWidth',2.5)
ylabel('Log2(Uncer.[m])')
hold on
yyaxis('right')
plot(B2,'r-','LineWidth',1)
ylabel('Bin. Cl.')
ylim([-0.01 2])
subplot(5,1,3)
title('Fusion of Hysteresis and Otsu')
yyaxis('left')
plot(log2(smoth),'blue-','LineWidth',2.5)
ylabel('Log2(Uncer.[m])')
hold on
yyaxis('right')
plot(B3,'r-','LineWidth',1)
ylabel('Bin. Cl.')
ylim([-0.01 2])
subplot(5,1,4)
title('Simple Thresholding')
yyaxis('left')
plot(log2(smoth),'blue-','LineWidth',2.5)
ylabel('Log2(Uncer.[m])')
hold on
yyaxis('right')
plot(B3,'r-','LineWidth',1)
ylabel('Bin. Cl.')
ylim([-0.01 2])
subplot(5,1,5)
title('Fusion of Hysteresis, Otsu, and Simple Thresholding')
yyaxis('left')
plot(log2(smoth),'blue-','LineWidth',2.5)
ylabel('Log2(Uncer.[m])')
hold on
yyaxis('right')
plot(B5,'r-','LineWidth',1 )
ylabel('Bin. Cl.')
ylim([-0.01 2])


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
B6 = zeros(size(smoth)); 
    
    switch length(q)
        case 1
          s1 = smoth(1:q(1));
          w1 = mean(s1);
          s2 = smoth(q(1)+1:end);
          w2 = mean(s2);
          if w1 > w2
              B6(1:q(1)) = 1;
          else
              B6(q(1)+1:end) = 1;
          end
        case 2
          if mean(B2(1:q(1))) > 0.5 % A kid of fuzzy decision
              B6(1:q(1)) = 1;
          end
          if mean(B2(q(1)+1:q(2))) > 0.5
              B6(q(1)+1:q(2)) = 1;
          end
          if mean(B2(q(2)+1:end)) > 0.5
              B6(q(2):end) = 1;
          end 
    end   
    if length(q) > 2
       if mean(B2(1:q(1))) > 0.5
              B6(1:q(1)) = 1;
       end
           for i = 1 : length(q)-1
              if mean(B2(q(i)+1:q(i+1))) > 0.5
                 B6(q(i)+1:q(i+1)) = 1;
              end 
           end
       if mean(B2(q(i+1)+1:end)) > 0.5
              B6(q(i+1)+1:end) = 1;
       end         
   end



figure
title('Final Binary Classification', 'FontSize',20)
yyaxis('left')
plot (uncertainty_raw)
xlabel('Number of Samples','FontSize',20)
ylabel('Uncertainty [m]','FontSize',20)
hold on
yyaxis('right')
plot(B6)
ylabel('Binary Classification','FontSize',20)
ylim([-0.01 2])
set(gca,'fontsize',20)
legend({'Geolocation Uncertainty Signal','Binary Result'},'FontSize',15)

end

