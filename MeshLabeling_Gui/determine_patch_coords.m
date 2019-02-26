function [img_nums, x, y] = determine_patch_coords(idx, handles)
% determine coordinates of patches for a given face id for plotting
    img_nums = find(handles.imgCoordseen_x(idx,:));
    x = full(handles.imgCoordseen_x(idx,:));
    x = x(x~=0);
    y = full(handles.imgCoordseen_y(idx,:));
    y = y(y~=0);
    
    n_views = size(img_nums,2);
    MAX_VIEWS = 6;
    if n_views > MAX_VIEWS
        draw = rand(1,n_views);
        [ranked, idx_rank] = sort(draw);
        img_nums = img_nums(idx_rank(1:MAX_VIEWS));
        x = x(idx_rank(1:MAX_VIEWS));
        y = y(idx_rank(1:MAX_VIEWS));
    end
    
    
end

