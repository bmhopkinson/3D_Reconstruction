function [  meshDists ] = meshDistances(imgFile, stereoDists,stereoPoints,V, F, T, camPos, pCamCalib)

%determines distances between feature points in an image in an uncalibrated 3D mesh
addpath(genpath('/home/brian/Documents/MATLAB/Library/geom2d'));

nPoints = size(stereoPoints,1);
xyzMesh = zeros(nPoints,3);

for i = 1:nPoints
    ximg = stereoPoints(i,1);
    yimg = stereoPoints(i,2);
    [ xyzMesh(i,:), faceIdx(i) ] = projectImagePointToMesh( ximg, yimg, V, F, T, camPos, pCamCalib);
end

nDists = size(stereoDists,1);
meshDists = zeros(nDists,1); 
for i = 1:nDists
    p1 = xyzMesh(stereoDists(i,1),:);
    p2 = xyzMesh(stereoDists(i,2),:);
    if isnan([p1 p2])
        meshDists(i) = NaN;
    else
        meshDists(i) = distancePoints(p1,p2);
    end
end

% distRatio = meshDists./stereoDists(:,3);
% 
% inFile = strcat('./input/photos/',imgFile);
% image = imread(inFile);
% %% Display Mesh with faces colored
%     ClassColorsList = uint8([  0,   0,   0;...  %0 unclassified -  black
%                          127,  51,   0;...  % 1 Apalm - brown
%                          198,  99,  33;...  % 2 Acerv - light brown   
%                          100, 255, 25;...% 106, 175,  26;...  % 3 Orbicella - medium green  
%                          255, 255, 0 ;...  % 4 Siderastrea siderea-   yellow
%                          201, 249, 138;...  % 5 Porites astreoides - lime green
%                          180,   0, 200;...  % 6 Gorgonian - purple
%                          255,   0,   0;...  % 7 Antillogorgia - red
%                          255, 170, 238;...  % 8 Plexaurella- pink
%                           50, 150, 50;...  % 9 algae -  green
%                           90, 200, 255;...  % 10 rubble - medium blue
%                            0, 255, 255]);    %11 sand - light blue
%                        
% MyColorMap = double(ClassColorsList)./255;
% MyColorMap = [MyColorMap; MyColorMap];
% 
% figure(1)
% for i = 1:nPoints
%   %  image = insertMarker(image,stereoPoints(i,1:2), 'o','color',MyColorMap(i+1,:),'size',10);
%     image = insertShape(image,'Circle',[stereoPoints(i,1:2) 10],'Color',MyColorMap(i+1,:),'LineWidth',5);
%     image = insertText(image,stereoPoints(i,1:2),i,'FontSize',20);
% end
% 
% 
% 
% for i = 1:length(distRatio)
%     if distRatio(i) < 0.25
%         p1 = stereoPoints(stereoDists(i,1),1:2);
%         p2 = stereoPoints(stereoDists(i,2),1:2);
%         image = insertShape(image,'Line', [p1 p2],'Color','red');
%     end
% end         
% 
% imshow(image);  
% 
% Fclass = zeros(size(F,1),1);
% for i = 1:length(faceIdx)
%     Fclass(faceIdx(i)) = i+1;
% end
% 
% figure(2)
% 
% colormap(MyColorMap);
% trisurf(F, V(:,1), V(:,2), V(:,3),Fclass);
% axis image;
% shading flat;

end
