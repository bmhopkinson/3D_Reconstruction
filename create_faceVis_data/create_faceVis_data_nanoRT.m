%create data structures that map faces to camera images and the points where they appear in those images

addpath(genpath('~/Documents/MATLAB/Library/geom3d'));
addpath('~/Documents/MATLAB/Library/xml');
%
camFile = './test_data/crescent_reef_refined_2017/crescent_reef_refined_20190125_cameras.xml';
camVersion = 'v1.4';
meshFile = './test_data/crescent_reef_refined_2017/crescent_reef_refined_20190125_mesh.off';
fileBase = './test_data/crescent_reef_refined_2017/crescent_reef_refined_20190125';

% camFile  = './test_data/crescent_simple/Crescent_simple_cameras.xml';
% camVersion = 'v1.4';
% meshFile = './test_data/crescent_simple/Crescent_simple_mesh.off';
% fileBase = './test_data/crescent_simple/Crescent_simple';

% camFile  = './data/0441_simple_3_cameras.xml';
% camVersion = 'v1.4';
% meshFile = './data/0441_simple_3_mesh.off';
% fileBase = './data/0441_simple_3';

%
% camFile = './test_data/crescent_reef_refined_20190129/crescent_reef_refined_20190129_cameras.xml';
% camVersion = 'v1.4';
% meshFile = './test_data/crescent_reef_refined_20190129/crescent_reef_refined_20190129_mesh.off';
% fileBase = './test_data/crescent_reef_refined_20190129/crescent_reef_refined_20190129';



[V, F] = readMesh_off(meshFile);

[Fcenters, visibleFC, imCoord_x, imCoord_y ] = facesVisibletoCameras_nanoRT(camFile, camVersion, V, F, fileBase);

outfile = strcat(fileBase,'_faceVisSparse.mat');
save(outfile,'Fcenters','imCoord_x','imCoord_y','visibleFC','-v7.3');
