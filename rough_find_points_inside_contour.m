function [inside_idx]=rough_find_points_inside_contour(app,contour_latlon,points_latlon)

%%%%%%%%Functionalize: Find points inside contour
        %tic;
        temp_con_lat=contour_latlon(:,1);
        temp_con_lon=contour_latlon(:,2);
        temp_latlon=horzcat(temp_con_lat,temp_con_lon);
        temp_latlon=temp_latlon(~isnan(temp_latlon(:,1)),:);
        k_idx=convhull(temp_latlon(:,2),temp_latlon(:,1));
        temp_contour=temp_latlon(k_idx,:);

        %%%%%%%%%%Convex hull to simplify
        if ~isempty(temp_contour)
            %%%%%Rough cut first to speed it up.
            min_lat=min(temp_contour(:,1));
            max_lat=max(temp_contour(:,1));
            min_lon=min(temp_contour(:,2));
            max_lon=max(temp_contour(:,2));

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            lon_idx1=find(min_lon<points_latlon(:,2));
            lon_idx2=find(max_lon>points_latlon(:,2));
            cut_lon_idx=intersect(lon_idx1,lon_idx2);

            lat_idx1=find(min_lat<points_latlon(:,1));
            lat_idx2=find(max_lat>points_latlon(:,1));
            cut_lat_idx=intersect(lat_idx1,lat_idx2);

            inside_idx=intersect(cut_lon_idx,cut_lat_idx);

        else
            inside_idx=NaN(1,1);
        end
        %toc;
