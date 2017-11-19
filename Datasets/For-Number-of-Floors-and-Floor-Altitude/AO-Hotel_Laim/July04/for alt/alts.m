% Floor numbers and corresponding altitudes determinator for building
%  AO Second 6 datasets
%
%
% The true number of floors in this building is 6. We want to run the
% algorithm on aggregated datasets and see how elbow method works for
% Determining number of floors and floors altitude in unsupervised manner
%
%
% Current directory contains pressure datasets and we want to estimate
% floor numbers using elbow method and corresponding altitudes by k-means 
% clustering method and barometric formula
% 
% Variables and functions:
%
%    K2: The final estimated number of floors of this building from aggregated altitude datasets
%    C2: cluster centers of aggregated altitude datasets, they tell us
%         about overall altitude of each floor
%    cluster_1,...,cluster_7: are for evaluation of altitude clusters of aggregated
%                             altitudes(evaluate floor altitudes)
%
%    temps: temperatures of datasets
%
%    best_kmeans: implements the elbow method. At the last line of this function,
%                  there is the k-means function which uses the output of
%                  elbow method for clustering  
% 
% OMID REZA MOSLEHI RAD, 2017

%% read data files from current directory

file_names = dir('*.csv');
nummber_of_files = length(file_names);
Raw_datasets = cell(1,length(file_names));
my_data_smoothed = cell(1,length(file_names));
all_altitudes =NaN;

%% File temperature list
count =1;
% Corresponding temperatures for the 4 pressure datasets 
temps = [15,16,9,28,30,25,21,17,8,14];

%% movingSTD threshold for removing stairs
STD_threshold = 0.019;
sliding_win_size_movstd = 28.5;

%% Main for-loop
% This is a loop to call each dataset and determines the number of floors
% and clustering it

for a=1:length(file_names)
  
  % Loading datasets   
  fname = file_names(a).name;
  Raw_pressure = xlsread(file_names(a).name);
  
  % Smooth each raw pressure signal using median filter
  smoothed = medfilt1(Raw_pressure(1:end,2), 81);
  
  % Altitude of smoothed pressure:
  
  
  % First is determination of reference pressure from overall ground floor pressure
  % values
  % To do so, we temporarily run movstd algorithm to remove all stair pressure
  % values, then run best_kmeans on the pressure signal to find pressure
  % values of each floor
 
  % Moving STD: run movstd algorithm which moves a sliding window size of 28.5 seen at top of script 
  moved = movstd(smoothed,sliding_win_size_movstd ,1); 
  
  % Take those values from smoothed signal where SDT at that point is less
  % than threshold. Those with STD higher than threshold are considered as
  % stair data, while the residuals are for the floors data
  
  Datasets_STDs{a}=moved;
  smoothed_without_stairs=NaN;
  for b = 1:length(smoothed)
      if moved(b)< STD_threshold
          smoothed_without_stairs(b)=smoothed(b);
      else
          smoothed_without_stairs(b)=NaN; 
      end
  end
  
  figure
   subplot(2,1,1)
  plot(Raw_pressure(1:end,2),'LineWidth',2)
  hold on
  plot(smoothed,'LineWidth',1.5)
  title('Raw and Smoothed pressure')
  legend('Raw','Smoothed')
   subplot(2,1,2)
  plot(smoothed_without_stairs,'LineWidth',2)
  hold on
  yyaxis('right')
  plot(moved,'LineWidth',1.5)
  title('Smoothed pressure without stairs')
  legend('Smoothed without stairs','movstd of smoothed')
  
  
smoothed_without_stairs(isnan(smoothed_without_stairs))=[];
 
  % Determination of reference pressure from ground floor pressure values
  % We cluster entire smoothed pressure signal to floor pressures, then
  % select the maximum cluster center as reference pressure
  % K-Means, elbow on each dataset
  % K gives the number of floors and in this case C is a vector for overall pressure of each
  % floor as a cluster center. The clustering of pressure signal helps to
  % find the maximum of vector C as reference pressure 
  
  
  warning('off','all')
  [IDX,C,SUMD,K,distorted]= best_kmeans(smoothed_without_stairs');
  ref_pressure = max(C);
  
  % increase the length of each clustered floor pressure by interpolation
  % to help Kmeans
  
  %store each cluster separately
  
  
 aggregated_increased_clusts = cell(1,K);
  for g = 1:K
       % a floor pressure cluster with index g
       clust = find(IDX==g);
       floor_clust = smoothed_without_stairs(clust);
       % increase length of each floor cluster by Fourier interpolation
       
       
         if length( floor_clust)>80
         increased_clust=interpft(floor_clust,300);
       else
         increased_clust=[];
         end
       aggregated_increased_clusts{g}=increased_clust;
  end 
     
     increased_smooth = cell2mat(aggregated_increased_clusts);
     
   switch a
       case 1
       TUM_Main_1_altitude_increased=sort(((power(ref_pressure./increased_smooth,1/5.257)-1)*(temps(a)+273.15))/0.0065,'ascend');
       figure
       plot (TUM_Main_1_altitude_increased)
       title('TUM Main: altitude of dataset 1')
       case 2
       TUM_Main_2_altitude_increased=sort(((power(ref_pressure./increased_smooth,1/5.257)-1)*(temps(a)+273.15))/0.0065,'ascend');
       figure
       plot (TUM_Main_2_altitude_increased)
       title('TUM Main: altitude of dataset 2')
       case 3
       TUM_Main_3_altitude_increased=sort(((power(ref_pressure./increased_smooth,1/5.257)-1)*(temps(a)+273.15))/0.0065,'ascend');
       plot (TUM_Main_3_altitude_increased)
       title('TUM Main: altitude of dataset 3')
       case 4
       TUM_Main_4_altitude_increased=sort(((power(ref_pressure./increased_smooth,1/5.257)-1)*(temps(a)+273.15))/0.0065,'ascend');
       plot (TUM_Main_4_altitude_increased)
       title('TUM Main: altitude of dataset 4')
       case 5
       TUM_Main_5_altitude_increased=sort(((power(ref_pressure./increased_smooth,1/5.257)-1)*(temps(a)+273.15))/0.0065,'ascend');
       plot (TUM_Main_5_altitude_increased)
       title('TUM Main: altitude of dataset 5')
       case 6
       TUM_Main_6_altitude_increased=sort(((power(ref_pressure./increased_smooth,1/5.257)-1)*(temps(a)+273.15))/0.0065,'ascend');
       plot (TUM_Main_6_altitude_increased)
       title('TUM Main: altitude of dataset 6')
       case 7
       TUM_Main_7_altitude_increased=sort(((power(ref_pressure./increased_smooth,1/5.257)-1)*(temps(a)+273.15))/0.0065,'ascend');
       plot (TUM_Main_7_altitude_increased)
       title('TUM Main: altitude of dataset 7')
       case 8
       TUM_Main_8_altitude_increased=sort(((power(ref_pressure./increased_smooth,1/5.257)-1)*(temps(a)+273.15))/0.0065,'ascend');
       plot (TUM_Main_8_altitude_increased)
       title('TUM Main: altitude of dataset 8')
       case 9
       TUM_Main_9_altitude_increased=sort(((power(ref_pressure./increased_smooth,1/5.257)-1)*(temps(a)+273.15))/0.0065,'ascend');
       plot (TUM_Main_9_altitude_increased)
       title('TUM Main: altitude of dataset 9')
       case 10
       TUM_Main_10_altitude_increased=sort(((power(ref_pressure./increased_smooth,1/5.257)-1)*(temps(a)+273.15))/0.0065,'ascend');
       plot (TUM_Main_10_altitude_increased)
       title('TUM Main: altitude of dataset 10')
       case 11
       TUM_Main_11_altitude_increased=sort(((power(ref_pressure./increased_smooth,1/5.257)-1)*(temps(a)+273.15))/0.0065,'ascend');
       plot (TUM_Main_11_altitude_increased)
       title('TUM Main: altitude of dataset 11')
       case 12
       TUM_Main_12_altitude_increased=sort(((power(ref_pressure./increased_smooth,1/5.257)-1)*(temps(a)+273.15))/0.0065,'ascend');
       plot (TUM_Main_12_altitude_increased)
       title('TUM Main: altitude of dataset 12')
       case 13
       TUM_Main_13_altitude_increased=sort(((power(ref_pressure./increased_smooth,1/5.257)-1)*(temps(a)+273.15))/0.0065,'ascend');
       plot (TUM_Main_13_altitude_increased)
       title('TUM Main: altitude of dataset 13')
       case 14
       TUM_Main_14_altitude_increased=sort(((power(ref_pressure./increased_smooth,1/5.257)-1)*(temps(a)+273.15))/0.0065,'ascend');
       plot (TUM_Main_14_altitude_increased)
       title('TUM Main: altitude of dataset 14')
       case 15
       TUM_Main_15_altitude_increased=sort(((power(ref_pressure./increased_smooth,1/5.257)-1)*(temps(a)+273.15))/0.0065,'ascend');
       plot (TUM_Main_15_altitude_increased)
       title('TUM Main: altitude of dataset 15')
       case 16
       TUM_Main_16_altitude_increased=sort(((power(ref_pressure./increased_smooth,1/5.257)-1)*(temps(a)+273.15))/0.0065,'ascend');
       plot (TUM_Main_16_altitude_increased)
       title('TUM Main: altitude of dataset 16')
       case 17
       TUM_Main_17_altitude_increased=sort(((power(ref_pressure./increased_smooth,1/5.257)-1)*(temps(a)+273.15))/0.0065,'ascend');
       plot (TUM_Main_17_altitude_increased)
       title('TUM Main: altitude of dataset 17')
       case 18
       TUM_Main_18_altitude_increased=sort(((power(ref_pressure./increased_smooth,1/5.257)-1)*(temps(a)+273.15))/0.0065,'ascend');
       plot (TUM_Main_18_altitude_increased)
       title('TUM Main: altitude of dataset 18')
       case 19
       TUM_Main_19_altitude_increased=sort(((power(ref_pressure./increased_smooth,1/5.257)-1)*(temps(a)+273.15))/0.0065,'ascend');
       plot (TUM_Main_19_altitude_increased)
       title('TUM Main: altitude of dataset 19')
       case 20
       TUM_Main_20_altitude_increased=sort(((power(ref_pressure./increased_smooth,1/5.257)-1)*(temps(a)+273.15))/0.0065,'ascend');
       plot (TUM_Main_20_altitude_increased)
       title('TUM Main: altitude of dataset 20')
       case 21
       TUM_Main_21_altitude_increased=sort(((power(ref_pressure./increased_smooth,1/5.257)-1)*(temps(a)+273.15))/0.0065,'ascend');
       plot (TUM_Main_21_altitude_increased)
       title('TUM Main: altitude of dataset 21')
       case 22
       TUM_Main_22_altitude_increased=sort(((power(ref_pressure./increased_smooth,1/5.257)-1)*(temps(a)+273.15))/0.0065,'ascend');
       plot (TUM_Main_22_altitude_increased)
       title('TUM Main: altitude of dataset 22')
       case 23
       TUM_Main_23_altitude_increased=sort(((power(ref_pressure./increased_smooth,1/5.257)-1)*(temps(a)+273.15))/0.0065,'ascend');
       plot (TUM_Main_23_altitude_increased)
       title('TUM Main: altitude of dataset 23')
       case 24
       TUM_Main_24_altitude_increased=sort(((power(ref_pressure./increased_smooth,1/5.257)-1)*(temps(a)+273.15))/0.0065,'ascend');
       plot (TUM_Main_24_altitude_increased)
       title('TUM Main: altitude of dataset 24')
       case 25
       TUM_Main_25_altitude_increased=sort(((power(ref_pressure./increased_smooth,1/5.257)-1)*(temps(a)+273.15))/0.0065,'ascend');
       plot (TUM_Main_25_altitude_increased)
       title('TUM_main: altitude of dataset 25')
       
       
   end
  % Store the distortion percents of elbow method in a cell array to use
  % the array for final plot of elbows for each dataset
  TUM_Main{a}=distorted;
  
end % end of main for loop

 % Aggregate altitude datasets into one aggregated altitude dataset
 
 switch a
     
     case 1
         TUM_Main_Aggregated_Altitudes = horzcat(TUM_Main_1_altitude_increased);   
     case 2
         TUM_Main_Aggregated_Altitudes = horzcat(TUM_Main_1_altitude_increased,TUM_Main_2_altitude_increased);   
     case 3
         TUM_Main_Aggregated_Altitudes = horzcat(TUM_Main_1_altitude_increased,TUM_Main_2_altitude_increased, TUM_Main_3_altitude_increased);   
     case 4
         TUM_Main_Aggregated_Altitudes = horzcat(TUM_Main_1_altitude_increased,TUM_Main_2_altitude_increased, TUM_Main_3_altitude_increased,TUM_Main_4_altitude_increased);   
     case 5
        TUM_Main_Aggregated_Altitudes = horzcat(TUM_Main_1_altitude_increased,TUM_Main_2_altitude_increased, TUM_Main_3_altitude_increased,TUM_Main_4_altitude_increased,TUM_Main_5_altitude_increased);
     case 6
        TUM_Main_Aggregated_Altitudes = horzcat(TUM_Main_1_altitude_increased,TUM_Main_2_altitude_increased, TUM_Main_3_altitude_increased,TUM_Main_4_altitude_increased,TUM_Main_5_altitude_increased,TUM_Main_6_altitude_increased);
     case 7
        TUM_Main_Aggregated_Altitudes = horzcat(TUM_Main_1_altitude_increased,TUM_Main_2_altitude_increased, TUM_Main_3_altitude_increased,TUM_Main_4_altitude_increased,TUM_Main_5_altitude_increased,TUM_Main_6_altitude_increased,TUM_Main_7_altitude_increased);
     case 8
        TUM_Main_Aggregated_Altitudes = horzcat(TUM_Main_1_altitude_increased,TUM_Main_2_altitude_increased, TUM_Main_3_altitude_increased,TUM_Main_4_altitude_increased,TUM_Main_5_altitude_increased,TUM_Main_6_altitude_increased,TUM_Main_7_altitude_increased,TUM_Main_8_altitude_increased);
     case 9
        TUM_Main_Aggregated_Altitudes = horzcat(TUM_Main_1_altitude_increased,TUM_Main_2_altitude_increased, TUM_Main_3_altitude_increased,TUM_Main_4_altitude_increased,TUM_Main_5_altitude_increased,TUM_Main_6_altitude_increased,TUM_Main_7_altitude_increased,TUM_Main_8_altitude_increased,TUM_Main_9_altitude_increased);
     case 10
        TUM_Main_Aggregated_Altitudes = horzcat(TUM_Main_1_altitude_increased,TUM_Main_2_altitude_increased, TUM_Main_3_altitude_increased,TUM_Main_4_altitude_increased,TUM_Main_5_altitude_increased,TUM_Main_6_altitude_increased,TUM_Main_7_altitude_increased,TUM_Main_8_altitude_increased,TUM_Main_9_altitude_increased,TUM_Main_10_altitude_increased);
        case 11
        TUM_Main_Aggregated_Altitudes = horzcat(TUM_Main_1_altitude_increased,TUM_Main_2_altitude_increased, TUM_Main_3_altitude_increased,TUM_Main_4_altitude_increased,TUM_Main_5_altitude_increased,TUM_Main_6_altitude_increased,TUM_Main_7_altitude_increased,TUM_Main_8_altitude_increased,TUM_Main_9_altitude_increased,TUM_Main_10_altitude_increased,TUM_Main_11_altitude_increased);
         case 12
        TUM_Main_Aggregated_Altitudes = horzcat(TUM_Main_1_altitude_increased,TUM_Main_2_altitude_increased, TUM_Main_3_altitude_increased,TUM_Main_4_altitude_increased,TUM_Main_5_altitude_increased,TUM_Main_6_altitude_increased,TUM_Main_7_altitude_increased,TUM_Main_8_altitude_increased,TUM_Main_9_altitude_increased,TUM_Main_10_altitude_increased,TUM_Main_11_altitude_increased,TUM_Main_12_altitude_increased);
         case 13
        TUM_Main_Aggregated_Altitudes = horzcat(TUM_Main_1_altitude_increased,TUM_Main_2_altitude_increased, TUM_Main_3_altitude_increased,TUM_Main_4_altitude_increased,TUM_Main_5_altitude_increased,TUM_Main_6_altitude_increased,TUM_Main_7_altitude_increased,TUM_Main_8_altitude_increased,TUM_Main_9_altitude_increased,TUM_Main_10_altitude_increased,TUM_Main_11_altitude_increased,TUM_Main_12_altitude_increased,TUM_Main_13_altitude_increased);
     case 14
        TUM_Main_Aggregated_Altitudes = horzcat(TUM_Main_1_altitude_increased,TUM_Main_2_altitude_increased, TUM_Main_3_altitude_increased,TUM_Main_4_altitude_increased,TUM_Main_5_altitude_increased,TUM_Main_6_altitude_increased,TUM_Main_7_altitude_increased,TUM_Main_8_altitude_increased,TUM_Main_9_altitude_increased,TUM_Main_10_altitude_increased,TUM_Main_11_altitude_increased,TUM_Main_12_altitude_increased,TUM_Main_13_altitude_increased,TUM_Main_14_altitude_increased);
     case 25
        TUM_Main_Aggregated_Altitudes = horzcat(TUM_Main_1_altitude_increased,TUM_Main_2_altitude_increased, TUM_Main_3_altitude_increased,TUM_Main_4_altitude_increased,TUM_Main_5_altitude_increased,TUM_Main_6_altitude_increased,TUM_Main_7_altitude_increased,TUM_Main_8_altitude_increased,TUM_Main_9_altitude_increased,TUM_Main_10_altitude_increased,TUM_Main_11_altitude_increased,TUM_Main_12_altitude_increased,TUM_Main_13_altitude_increased,TUM_Main_14_altitude_increased,TUM_Main_15_altitude_increased,TUM_Main_16_altitude_increased,TUM_Main_17_altitude_increased,TUM_Main_18_altitude_increased,TUM_Main_19_altitude_increased,TUM_Main_20_altitude_increased,TUM_Main_21_altitude_increased,TUM_Main_22_altitude_increased,TUM_Main_23_altitude_increased,TUM_Main_24_altitude_increased,TUM_Main_25_altitude_increased);
 end
 
figure
plot(TUM_Main{1,1},'b*--')
title('TUM Main elbows')
hold on
for j=2:length(file_names)
    plot(TUM_Main{1,j},'b*--')
end
hold off


figure
plot(TUM_Main_Aggregated_Altitudes)
title('TUM Main: aggregated altitudes')



%% Now we run elbow algorithm on aggregated altitude datasets
[IDX2,C2,SUMD2,K2,distorted2,distortion_percent_seccond_6]= best_kmeans_2(TUM_Main_Aggregated_Altitudes');

sorted_centroids = sort(C2,'ascend')
diff_centroids = diff(sorted_centroids)

K_mean_Try = 1


check_if_not_possible = 0;

% usually no consequent 2 floors have distance of less than 2.2m
while diff_centroids(find(diff_centroids<2))<2.2
  
            % repeat clustering of aggregated altitudes!
            [IDX2,C2,SUMD2,K2,distorted2,distortion_percent_seccond_6]= best_kmeans_2(TUM_Main_Aggregated_Altitudes');
            sorted_centroids = sort(C2,'ascend')
            diff_centroids = diff(sorted_centroids)
            K_mean_Try = K_mean_Try + 1
            check_if_not_possible=check_if_not_possible+1;
            if check_if_not_possible == 5
                break;
            end
             
                
end

% Finally the plot of  clustering result on aggregated altitude dataset

       figure
       plot(find(IDX2==1),TUM_Main_Aggregated_Altitudes(IDX2==1),'*')
       hold on
       plot(find(IDX2==2),TUM_Main_Aggregated_Altitudes(find(IDX2==2)),'*')
       plot(find(IDX2==3),TUM_Main_Aggregated_Altitudes(find(IDX2==3)),'*')
       plot(find(IDX2==4),TUM_Main_Aggregated_Altitudes(find(IDX2==4)),'*')
       plot(find(IDX2==5),TUM_Main_Aggregated_Altitudes(find(IDX2==5)),'*')
       plot(find(IDX2==6),TUM_Main_Aggregated_Altitudes(find(IDX2==6)),'*')
       plot(TUM_Main_Aggregated_Altitudes)
       title('clustering result')
      
    

% To evaluate accurycy of each floor, you can use the resulting clusters of
% aggregated datasets


      cluster_1 = TUM_Main_Aggregated_Altitudes(IDX2==1)';
      cluster_2 = TUM_Main_Aggregated_Altitudes(IDX2==2)';
      cluster_3 = TUM_Main_Aggregated_Altitudes(IDX2==3)';
      cluster_4 = TUM_Main_Aggregated_Altitudes(IDX2==4)';
      cluster_5 = TUM_Main_Aggregated_Altitudes(IDX2==5)';
      cluster_6 = TUM_Main_Aggregated_Altitudes(IDX2==6)';