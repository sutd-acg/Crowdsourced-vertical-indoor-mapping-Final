%{
     Omidreza Moslehirad
     Munich, Autumn 2017
     

 This function performs multiple moving-standard-deviationto  algorithm  to 
 divide magnetic signal into two main  parts: INDOORs and 'OUTDOORs'. 
 
--------------------------------------------------------------------------

 Inputs: 

    The magnetic *.csv file must be in the main folder.
          
    w1 :   The small window size
    w2:    The second window size
       
                   
 Outputs:
   
      mgn:      Magnetic data
    moved:      First STD
   moved2:      Second STD
   softed:      Gaussian Result
    flags:      Binary Classification Result
        
       
 
%}

function [mgn, moved, moved2, softed, flags] = OITransitionMagnetic(w1, w2)

% Set defaults
switch nargin
    case 0
        w1 = 20;
        w2 = 200;
    case 1
        w2 = 20;
end

% Magnetic file directory
magn_file_names = dir('*.csv');

% Read the data
magn = xlsread(magn_file_names.name);

% p = unique(magn,'rows');

% Select the data from desired axis 
mgn = magn(:,3);

% Plot raw data
figure
plot(mgn)
title('Magnetic Data','FontSize',20)
xlabel('Number of samples')
ylabel('Micro Tesla')

% Select a small window for moving standard deviation algorithm
w1 = 20; 
moved = movstd(mgn,w1);

% Plot the data with the moving standard deviation result together
figure
plot(mgn)
yyaxis('left')
title('Magnetic and First STD','FontSize',20)
xlabel('Number of samples','FontSize',20)
ylabel('Micro Tesla','FontSize',20)
hold on
yyaxis('right')
plot(moved)
ylabel('STD','FontSize',20)
legend('Magnetic Data','STD')

% Select a moving window with a larger size, run the algorithm over
% the previous output.
w2 = 200;
moved2 = movstd(moved,w2);

% Plot magnetic data together with the second moving STD
figure
plot(mgn)
yyaxis('left')
title('Magnetic and Second STD','FontSize',20)
xlabel('Number of samples','FontSize',20)
ylabel('Micro Tesla','FontSize',20)
hold on
yyaxis('right')
plot(moved2)
ylabel('STD of STD','FontSize',20)
legend('Magnetic Data','STD of STD')

% Apply Gaussian filter over previous output
softed = imgaussfilt(moved2,500);

% Plot magnetic data with the result of Gaussian filter
figure
plot(mgn)
yyaxis('left')
title('Magnetic and Gaussian','FontSize',20)
xlabel('Number of samples','FontSize',20)
ylabel('Micro Tesla','FontSize',20)
hold on
yyaxis('right')
plot(softed)
ylabel('Gaussian','FontSize',20)
legend('Magnetic Data','Gaussian')

% Definition of the threshold for binary classification ad mean of Gaussian
% result.
mag_th = mean(softed);

% Binary Classification
flags=zeros(1,length(softed))';
for t = 1:length(softed)
    if softed(t) < mag_th
        flags(t)=0;
    else
        flags(t)=1;
    end
end

% Plot binary classification result with magnetic data together
figure
plot(mgn)
yyaxis('left')
title('Magnetic: OITransition Classification','FontSize',20)
xlabel('Number of samples','FontSize',20)
ylabel('Micro Tesla','FontSize',20)
hold on
yyaxis('right')
plot(flags)
ylabel('Binary Classification','FontSize',20)
legend('Magnetic Data','Binary Classification')
ylim([-0.01 2])
set(gca,'fontsize',20)

end



