%{
     Omidreza Moslehirad
     Munich, Autumn 2017
     
 Inputs: 

    The magnetic *.csv file must be in the main folder.
          
    w1 :   The small window size
    w2:    The second window size
       
                   
 Outputs:
      final_interpolated_mag_with_flags:   nx3  matrix of time,
                                           interpolated magnetic and
                                           binary classification result.
 
%}

function [final_interpolated_mag_with_flags] = OITransitionMagnetic(w1, w2)

% Set defaults
switch nargin
    case 0
        w1 = 20;
        w2 = 200;
    case 1
        w2 = 20;
end



% Read the data
magn = xlsread('./OI_Magnetic/TUM/My_TUM_MAY27Magnetic.csv');

% temp_mag = unique(magn,'rows');
[~,idu] = unique(magn(:,1));
temp_mag = magn(idu,:);

% Select the data from desired axis 
mgn = temp_mag(:,3);


% Select a small window for moving standard deviation algorithm
w1 = 20; 
moved = movstd(mgn,w1);


% Select a moving window with a larger size, run the algorithm over
% the previous output.
w2 = 200;
moved2 = movstd(moved,w2);

% Apply Gaussian filter over previous output
softed = imgaussfilt(moved2,500);

% Definition of the threshold for binary classification ad mean of Gaussian
% result.
mag_th = mean(softed);

% Binary Classification
Binary_mag=zeros(1,length(softed))';
for t = 1:length(softed)
    if softed(t) < mag_th
        Binary_mag(t)=0;
    else
        Binary_mag(t)=1;
    end
end

x_temp_mag = temp_mag(:,1);
v_temp_mag = temp_mag(:,3);
xq_temp_mag = temp_mag(1,1):1:temp_mag(length(temp_mag),1); 
 
interpolated_mag = interp1(x_temp_mag,v_temp_mag,xq_temp_mag');

interpolated_flag_mag = interp1(x_temp_mag,Binary_mag,xq_temp_mag');

final_interpolated_mag_with_flags = horzcat(xq_temp_mag',interpolated_mag);
final_interpolated_mag_with_flags = horzcat(final_interpolated_mag_with_flags,interpolated_flag_mag);


figure
plot(final_interpolated_mag_with_flags(:,1),final_interpolated_mag_with_flags(:,2))
hold on
yyaxis('right')
plot(final_interpolated_mag_with_flags(:,1),final_interpolated_mag_with_flags(:,3))



end



