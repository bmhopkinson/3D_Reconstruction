%create data structures that map faces to camera images and the points where they appear in those images

addpath(genpath('~/Documents/MATLAB/Library/geom3d'));
addpath('~/Documents/MATLAB/Library/xml');
% 
% camFile  = '0441_simple_2_camera_agisoft.xml';
% camVersion = 'v1.2';
% meshFile = '0441_simple_2_model.off';
% fileBase = '0441_simple_2_';

camFile  = './data/Crescent_simple_cameras.xml';
camVersion = 'v1.4';
meshFile = './data/Crescent_simple_mesh.off';
fileBase = './data/Crescent_simple';

% camFile  = './data/0441_simple_3_cameras.xml';
% camVersion = 'v1.4';
% meshFile = './data/0441_simple_3_mesh.off';
% fileBase = './data/0441_simple_3';

% 
% camFile = './data/crescent_reef_refined_2017/crescent_reef_refined_20190125_cameras.xml';
% camVersion = 'v1.4';
% meshFile = './data/crescent_reef_refined_2017/crescent_reef_refined_20190125_mesh.off';
% fileBase = './data/crescent_reef_refined_2017/crescent_reef_refined_20190125';



[V, F] = readMesh_off(meshFile);

[Fcenters, visibleFC, imCoord_x, imCoord_y ] = facesVisibletoCameras_nanoRT_backkup(camFile, camVersion, V, F, fileBase);

outfile = strcat(fileBase,'_faceVisSparse.mat');
save(outfile,'Fcenters','imCoord_x','imCoord_y','visibleFC','-v7.3');

