function [patches, pts] = extract_patches(img_nums,imgFilePath, imgFiles,x,y)
%extract patches from images

n_patches = size(img_nums,2);

patches = {};
pts = [];

for i = 1:n_patches
    I = imread(strcat(imgFilePath,imgFiles{img_nums(i)}));
    
    %trim image around point
    imRange = 150;
    [this_patch, thisPointTrim] = trimImage(I, [x(i) y(i)], imRange);
    patches{i} = this_patch;
    pts(i,:) = thisPointTrim;
    
end



end

