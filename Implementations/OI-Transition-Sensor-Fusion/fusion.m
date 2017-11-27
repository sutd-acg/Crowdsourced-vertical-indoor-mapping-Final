%{
     Omidreza Moslehirad     Munich, Autumn 2017

Note 01:
 
During  data  collection,  sensors  collect  data  with  different sampling
rates. This is mainly  for battery power  management. This  lead to  having 
different time intervals for each sensor dataset. We interpolate each dataset
over the time array to reconstruct the signal over all  time  values,  then 
find the data intersection among different  sensors  via  itersection  time 
interval.

Note 02:
 
We used large edges of the light or GPS at transition points for definining
the ground truth of outdoor-indoor transition classification evaluations.
Generally, during  the day, if  the light  is  available,  we have  a  more
reliable ground truth via the light, while at night, we rely on large edges
of the GPS uncertainty signal at transition points as the ground truth.

Inputs: 

Binary classification results of outdoor-indoor transition for light, gps and
magnetic  sensors  (please see the  OITransitionGPS,  OITransitionLight and
OITransitionMagnetic  functions). For evaluating other datasets, you should
re-define the path to each  sensor dataset from similar directories. In our
example, we  selected  a  gps, light  and  magnetic dataset from a building
(Adel_13A).

    
Outputs:
 
final_fused_result:   The binary fusion result of light+magnetic+light sensors

intersected_gps:      The GPS uncertaity data over the intersection time
                      interval of all 3 sensor datasets.
intersected_light:    The light data over the intersection time interval of 
                      all 3 sensor datasets.
intersected_magnetic: The magnetic data over the intersection time interval 
                      of all 3 sensor datasets.
intersection_time_interval: Intersection time interval of all 3 sensors.
      
%}

final_interpolated_gps_with_flags = OITransitionGPS();
final_interpolated_light_with_flags = OITransitionLight();
final_interpolated_mag_with_flags = OITransitionMagnetic();
intersection_time_interval = intersect(final_interpolated_gps_with_flags(:,1) ,intersect(final_interpolated_light_with_flags(:,1),final_interpolated_mag_with_flags(:,1),'rows'),'rows');
start_flag=find(final_interpolated_light_with_flags==intersection_time_interval(1));
end_flag=find(final_interpolated_light_with_flags==intersection_time_interval(end));
current_flags_light = final_interpolated_light_with_flags(:,3);
intersected_flag = current_flags_light(start_flag:end_flag);
intersected_light_data = final_interpolated_light_with_flags(start_flag:end_flag,:);
start_flag_mag=find(final_interpolated_mag_with_flags==intersection_time_interval(1));
end_flag_mag=find(final_interpolated_mag_with_flags==intersection_time_interval(end));
current_flags_mag = final_interpolated_mag_with_flags(:,3);
intersected_flags_mag = current_flags_mag(start_flag_mag:end_flag_mag);
intersected_mag_data = final_interpolated_mag_with_flags(start_flag_mag:end_flag_mag,:);
start_flag_gps=find(final_interpolated_gps_with_flags==intersection_time_interval(1));
end_flag_gps=find(final_interpolated_gps_with_flags==intersection_time_interval(end));
current_flags_gps = final_interpolated_gps_with_flags(:,3);
intersected_flag_gps = current_flags_gps(start_flag_gps:end_flag_gps);
intersected_gps_data = final_interpolated_gps_with_flags(start_flag_gps:end_flag_gps,:);

for s = 1:length(intersected_gps_data)
    if intersected_gps_data(s,3)<0.5
     intersected_gps_data(s,3) =0;
    else
    intersected_gps_data(s,3) =1;
    end
end

for s = 1:length(intersected_light_data)
    if intersected_light_data(s,3)<0.5
     intersected_light_data(s,3) =0;
    else
    intersected_light_data(s,3) =1;
    end
end

for s = 1:length(intersected_mag_data)
    if intersected_mag_data(s,3)<0.5
     intersected_mag_data(s,3) =0;
    else
    intersected_mag_data(s,3) =1;
    end
end

final_fused_flag_tem = bitand(intersected_light_data(:,3),bitor(intersected_gps_data(:,3),intersected_mag_data(:,3)));     

final_fused_result = bitor(final_fused_flag_tem,bitand(intersected_gps_data(:,3),intersected_mag_data(:,3)));

intersected_gps = intersected_gps_data (:,2);
intersected_light = intersected_light_data(:,2);
intersected_magnetic = intersected_mag_data (:,2);


% If GPS Uncertainnty large edges at entrances is the ground truth:
figure
title('Fusion Result: GPS Edges as Ground Truth')
yyaxis('left')
plot(intersected_gps)
ylabel('GPS Uncertainty [m]')
xlabel('Number of Samples')
hold on
yyaxis('right')
plot(final_fused_result)
ylabel('Fusion Binary Classification')
legend('GPS Uncertainty','Fusion Binary Classification')
ylim([-0.01 2])

% If the light edges at entrances is the ground truth:
figure
title('Fusion Result: Light Edges as Ground Truth')
yyaxis('left')
plot(intersected_light)
ylabel('Light [lx]')
xlabel('Number of Samples')
hold on
yyaxis('right')
plot(final_fused_result)
ylabel('Fusion Binary Classification')
ylim([-0.01 2])
legend('GLight','Fusion Binary Classification')






