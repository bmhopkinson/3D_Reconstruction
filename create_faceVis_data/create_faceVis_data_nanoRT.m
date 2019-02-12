%create data structures that map faces to camera images and the points where they appear in those images

addpath(genpath('~/Documents/MATLAB/Library/matGeom/matGeom'));
addpath('~/Documents/MATLAB/Library/xml');
%
% camFile  = '0441_simple_2_camera_agisoft.xml';
% camVersion = 'v1.2';
% meshFile = '0441_simple_2_model.off';
% fileBase = '0441_simple_2_';

% camFile  = './data/Crescent_simple_cameras.xml';
% camVersion = 'v1.4';
% meshFile = './data/Crescent_simple_mesh.off';
% fileBase = './data/Crescent_simple';

camFile  = './data/0441_simple_3_cameras.xml';
camVersion = 'v1.4';
meshFile = './data/0441_simple_3_mesh.off';
fileBase = './data/0441_simple_3';

%
% camFile = './data/crescent_reef_refined_20190129/crescent_reef_refined_20190129_cameras.xml';
% camVersion = 'v1.4';
% meshFile = './data/crescent_reef_refined_20190129/crescent_reef_refined_20190129_mesh.off';
% fileBase = './data/crescent_reef_refined_20190129/crescent_reef_refined_20190129';



[V, F] = readMesh_off(meshFile);
[Cam, pCamCalib] = loadCameraData(camFile,camVersion);
[Fcenters, visibleFC, imCoord_x, imCoord_y ] = facesVisibletoCameras_nanoRT(Cam, pCamCalib, V, F, fileBase);

outfile = strcat(fileBase,'_faceVisSparse.mat');
save(outfile,'Fcenters','imCoord_x','imCoord_y','visibleFC','-v7.3');
