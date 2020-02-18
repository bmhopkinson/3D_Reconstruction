
%% apply a manual calibration factor to scale a mesh - obtained from scale objects in images

addpath(genpath('/home/brian/Documents/MATLAB/Library/geom3d'));
addpath('/home/brian/Documents/MATLAB/Library');

SCALE_FACTOR = 1/0.469;  %ratio of arb_units in raw mesh to actual dimension (meters)

meshFile = './input/215_ML_v3_mesh.off';
outMeshFile = './output/215_ML_v3_mesh_metric.stl';  %can only write stl files currently - convert to .off in Meshlab

[V, F] = readMesh_off(meshFile);  %load mesh

Vmet = V./SCALE_FACTOR;
stlwrite(outMeshFile,F, Vmet);

pcshow(Vmet);