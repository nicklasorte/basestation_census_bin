clear;
clc;
close all;
app=NaN(1);  %%%%%%%%%This is to allow for Matlab Application integration.
format shortG
top_start_clock=clock;%datetime;
folder1='C:\Local Matlab Data\3.1GHz'; %%%%%Folder where all the matlab code is placed.
cd(folder1)
addpath(folder1)
addpath('C:\Local Matlab Data\Basic_Functions')
addpath('C:\Local Matlab Data\Census_Functions')
addpath('C:\Local Matlab Data')
pause(0.1)
load('us_cont.mat','us_cont')
load('state_lat.mat')
load('state_lon.mat')


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Find the number of base stations to
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%the nearest census centroid.



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Load in the base station locations
tic;
cell_rand_real=readcell('Rand_Real_LatLon.xlsx');
toc;
rr_latlon=unique(cell2mat(cell_rand_real),'rows');
size(rr_latlon)
img_label='RR'

%%%%%%%%%%%%%%Limit to US_Cont
tic;
[rr_inside_idx]=rough_find_points_inside_contour(app,us_cont,rr_latlon);
toc;
size(rr_inside_idx)
rr_latlon=rr_latlon(rr_inside_idx,:);

%%%%%%%%%%%Census Centroid (Much smaller than the census boundaries)
load('Cascade_new_full_census_2010.mat','new_full_census_2010')%%%%%%%Geo Id, Center Lat, Center Lon,  NLCD (1-4), Population
census_latlon=new_full_census_2010(:,[2,3]);
geo_id_latlon=new_full_census_2010(:,[1:3]);


%%%%%%%%%%%%%%%%%%Find the knn of the Base Stations and Census Centroid
[idx_knn]=knnsearch(census_latlon,rr_latlon,'k',1); %%%Find Nearest Neighbor
knn_array=census_latlon(idx_knn,:);
knn_dist_bound=deg2km(distance(knn_array(:,1),knn_array(:,2),rr_latlon(:,1),rr_latlon(:,2)));%%%%Calculate Distance
max_knn_dist=ceil(max(knn_dist_bound));
rr_latlon_distkm=horzcat(rr_latlon,ceil(knn_dist_bound));


close all;
Fig1=figure;
hold on;
histogram(knn_dist_bound)
grid on;
xlabel('Distance [km]')
ylabel('Number of Occurrences')
set(gca, 'YScale', 'log')
title('Histogram:Distance between Base Station and Census Centroid')
filename3=strcat('knn_histogram_distance.png');
saveas(Fig1,char(filename3))
pause(0.1)



%%%%%%%%%%%%%%%%%%%%%Heat Map It to see where the hot spots are at.
min_dist=min(rr_latlon_distkm(:,3));
max_dist=max(rr_latlon_distkm(:,3));
count_range_dist=min_dist:1:max_dist; %%%%%%%%%%Non-Zero
num_colors_dist=length(count_range_dist);
color_set_dist=flipud(plasma(num_colors_dist));


%%%%%%%%%%Need to sort
[~,sort_dist_idx]=sort(rr_latlon_distkm(:,3));
sort_rr_latlon_distkm=rr_latlon_distkm(sort_dist_idx,:);

[num_dist,~]=size(sort_rr_latlon_distkm);
color_matrix_dist=NaN(num_dist,3);
dot_size_dist=NaN(num_dist,1);
for i=1:1:num_dist
    %%%%%%%%%Find the count to the color
    color_idx=find(sort_rr_latlon_distkm(i,3)==count_range_dist);
    dot_size_dist(i)=color_idx;
    color_matrix_dist(i,:)=color_set_dist(color_idx,:);
end


close all;
f1=figure;
AxesH = axes;
hold on;
title('Distance km: Base Station from Census Centroid')
scatter(sort_rr_latlon_distkm(:,2),sort_rr_latlon_distkm(:,1),dot_size_dist,color_matrix_dist(:,:),'filled')
plot(us_cont(:,2),us_cont(:,1),'-k')
plot(state_lon,state_lat,'Color', [160/256 160/256 160/256])
grid on;
h=colorbar('Location','south')
num_ticks=min(horzcat(num_colors_dist,11))
color_tiks=round(linspace(min_dist,max_dist,num_ticks));

if num_ticks<11
    h.Ticks=linspace(0,1,num_ticks+1);
    h. TickLabels=horzcat(cell(1),num2cell(color_tiks),cell(1));
else
    h.Ticks=[0:0.1:1];
    h. TickLabels=num2cell(color_tiks);
end
colormap(f1,color_set_dist)
max_lon=-65;
min_lon=-125;
max_lat=50;
min_lat=25;
xlim([min_lon,max_lon])
ylim([min_lat,max_lat])
%plot_google_map('maptype','terrain','APIKey','AIzaSyCgnWnM3NMYbWe7N4svoOXE7B2jwIv28F8') %%%Google's API key made by nick.matlab.error@gmail.com
%%%%%%Center the plot and make the x/y span equal
if max_lon-min_lon>=max_lat-min_lat %%%%%%%%%%Add Buffer to y/lat
    graph_span=max_lat-min_lat;
    add_buff=((max_lon-min_lon)-graph_span)/6;
    ylim([min_lat-(add_buff*1.25),max_lat+(add_buff*.5)])
else %%%%%%%%%%Add Buffer to x/lon
    graph_span=max_lon-min_lon;
    add_buff=((max_lat-min_lat)-graph_span)/7;
    xlim([min_lon-add_buff,max_lon+add_buff])
end

InSet = get(AxesH, 'TightInset');
set(AxesH, 'Position', [InSet(1:2), 1-InSet(1)-InSet(3)-0.01, 1-InSet(2)-InSet(4)])
%%%%%%%%Make the x/y axis invisible
ax = gca;
%ax.Visible = 'off';
%print(gcf,strcat('HD_Scatter_BS_Dist.png'),'-dpng','-r600')
filename3=strcat('Scatter_BS_Dist.png');
saveas(f1,char(filename3))
pause(0.1)







%%%%%%%%%%%%%%%Find the number of Base Stations Per Census Centroid
[num_census,~]=size(census_latlon)
hist_edge=0.5:1:(num_census+0.5);
[hist_count,~]=histcounts(idx_knn,hist_edge);
array_census_count=horzcat(geo_id_latlon,hist_count');

%%%%%%Find the non-zero counts
non_zero_idx=find(array_census_count(:,4)>0);
nonzero_census_count=array_census_count(non_zero_idx,:);
table_census_count=array2table(nonzero_census_count);


%%%%%%%%%%%%%Plot
close all;
Fig2=figure;
hold on;
histogram(nonzero_census_count(:,4))
grid on;
xlabel('Number of Base Stations per Census Tract')
ylabel('Number of Occurrences')
title('   Histogram: Number of Base Stations per Census Tract')
filename3=strcat('histogram_census_count.png');
saveas(Fig2,char(filename3))
pause(0.1)


%%%%%%%%%%%%%%%%%%%%%Heat Map It to see where the hot spots are at.
min_non_zero=min(nonzero_census_count(:,4));
max_non_zero=max(nonzero_census_count(:,4));
count_range=min_non_zero:1:max_non_zero; %%%%%%%%%%Non-Zero
num_colors=length(count_range);
color_set=flipud(plasma(num_colors));


%%%%%%%%%%Need to sort
[~,sort_idx]=sort(nonzero_census_count(:,4));
sort_nonzero_census_count=nonzero_census_count(sort_idx,:);

[num_nonzero,~]=size(sort_nonzero_census_count);
color_matrix=NaN(num_nonzero,3);
dot_size=NaN(num_nonzero,1);
for i=1:1:num_nonzero
    %%%%%%%%%Find the count to the color
    color_idx=find(sort_nonzero_census_count(i,4)==count_range);
    dot_size(i)=color_idx;
    color_matrix(i,:)=color_set(color_idx,:);
end


close all;
f1=figure;
AxesH = axes;
hold on;
title('Number of Base Station per Centroid')
scatter(sort_nonzero_census_count(:,3),sort_nonzero_census_count(:,2),dot_size,color_matrix(:,:),'filled')
plot(us_cont(:,2),us_cont(:,1),'-k')
plot(state_lon,state_lat,'Color', [160/256 160/256 160/256])
grid on;
h=colorbar('Location','south')
num_ticks=min(horzcat(num_colors,11))
color_tiks=round(linspace(min_non_zero,max_non_zero,num_ticks));

if num_ticks<11
    h.Ticks=linspace(0,1,num_ticks+1);
    h. TickLabels=horzcat(cell(1),num2cell(color_tiks),cell(1));
else
    h.Ticks=[0:0.1:1];
    h. TickLabels=num2cell(color_tiks);
end
colormap(f1,color_set)
max_lon=-65;
min_lon=-125;
max_lat=50;
min_lat=25;
xlim([min_lon,max_lon])
ylim([min_lat,max_lat])
%plot_google_map('maptype','terrain','APIKey','AIzaSyCgnWnM3NMYbWe7N4svoOXE7B2jwIv28F8') %%%Google's API key made by nick.matlab.error@gmail.com
%%%%%%Center the plot and make the x/y span equal
if max_lon-min_lon>=max_lat-min_lat %%%%%%%%%%Add Buffer to y/lat
    graph_span=max_lat-min_lat;
    add_buff=((max_lon-min_lon)-graph_span)/6;
    ylim([min_lat-(add_buff*1.25),max_lat+(add_buff*.5)])
else %%%%%%%%%%Add Buffer to x/lon
    graph_span=max_lon-min_lon;
    add_buff=((max_lat-min_lat)-graph_span)/7;
    xlim([min_lon-add_buff,max_lon+add_buff])
end

InSet = get(AxesH, 'TightInset');
set(AxesH, 'Position', [InSet(1:2), 1-InSet(1)-InSet(3)-0.01, 1-InSet(2)-InSet(4)])
%%%%%%%%Make the x/y axis invisible
ax = gca;
%ax.Visible = 'off';
%print(gcf,strcat('HD_Scatter_BS_Centroid.png'),'-dpng','-r600')
filename3=strcat('Scatter_BS_Centroid.png');
saveas(f1,char(filename3))
pause(0.1)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Make the 2D Scatter plot
%%%%%%%%%%Distance vs Number

%%%%%%For each census tract, find the number of base stations and the max
%%%%%%distance from its centroid

uni_idx_knn=unique(idx_knn);
num_uni=length(uni_idx_knn);
array_num_dist=NaN(num_uni,2); %%%%%%1)Dist, 2)Num
tic;
for i=1:1:num_uni
    temp_idx=find(uni_idx_knn(i)==idx_knn);
    array_num_dist(i,1)=max(knn_dist_bound(temp_idx));
    array_num_dist(i,2)=length(temp_idx);
end
toc;

sum(array_num_dist(:,2))
size(idx_knn)


close all;
Fig1=figure;
hold on;
scatter(array_num_dist(:,2),array_num_dist(:,1),5,'filled')
xlabel('Number of Base Stations per Census Tract')
ylabel('Distance [km] between Base Station and Census Centroid')
grid on;
filename3=strcat('Scatter_histogram_census_count_km.png');
saveas(Fig1,char(filename3))
pause(0.1)



close all;
Fig2=figure;
hold on;
hist3(fliplr(array_num_dist),'Nbins',[1 1]*ceil(max(max(array_num_dist))),'CdataMode','auto')
grid on;
view(2)
title('2D Histogram')
xlabel('Number of Base Stations per Census Tract')
ylabel('Distance [km] between Base Station and Census Centroid')
h=colorbar;
filename3=strcat('2D_histogram_census_count_km.png');
saveas(Fig2,char(filename3))
pause(0.1)














