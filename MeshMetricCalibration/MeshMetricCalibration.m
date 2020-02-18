%% creates a metric 3D mesh from an mesh determined up to a scale in photoscan
% uses stereopairs to produce individual reconstructions and get metric distances in these crude reconstructions 
% then compares those metric distances with relative distances bewteen the same points in the uncalibrated mesh to produce a scale factor 
addpath(genpath('/home/brian/Documents/MATLAB/Library/geom3d'));
addpath('/home/brian/Documents/MATLAB/Library');


%load image file names
% infile = 'stereopairs_0552_infile.txt';
% cameraFile = './input/FL_Keys_2016_0552_1_cameras.xml';
% meshFile = './input/FL_Keys_2016_0552_1_mesh.off';

ReconFiles = 2; %1 = Right camera files used to build 3D reconstruction, 2 = Left camera files used.
infile = './input/stereopairs_ML_215.txt';
cameraFile = './input/215_ML_v3_cameras.xml';
meshFile = './input/215_ML_v3_mesh.off';
outMeshFile = './output/215_ML_v3_mesh_metric_20200123.stl';  %can only write stl files currently - convert to .off in Meshlab

fin = fopen(infile);
C = textscan(fin,'%s\t%s\n');
Lfiles = C{1,1};
Rfiles = C{1,2};

if ReconFiles == 1
    Mfiles = Rfiles;
elseif ReconFiles ==2
    Mfiles = Lfiles;
end


%load sterocamera parameters
load('stereoParams_underwater10272015.mat');  %imports stereoParams object which contains stereo rig caliabration information

%processes stereopairs to obtain metric distances between feature points
nPairs = size(Mfiles,1);
for i = 1:nPairs
    Mfiles{i}
     I1 = imread(strcat('./input/photos/',Lfiles{i}));  %image 1 should be from the left camera
     I2 = imread(strcat('./input/photos/',Rfiles{i}));  % image 2 from the right camera (corresponds with calibration designations of camera 1 and 2);
    [stereoDists, stereoPoints] = stereopair_featurept_dists(I1, I2, stereoParams);

    [pathstr, name, ext ] = fileparts(Mfiles{i});
    outfile = strcat('./data/',name, '_stereodists.mat');
    save(outfile','stereoDists','stereoPoints');
end

[V, F] = readMesh_off(meshFile);  %load mesh
[Label, T, Tinv,camPos, pCamCalib ] = loadCameraData( cameraFile ); %load corresponding camera data

corrDists = [];
for i = 1:nPairs
%for i = 4
    fileIdxs = strfind(Label, Mfiles{i});
    thisIdx = find(~cellfun(@isempty,fileIdxs)); %should only be one nonempty element
    if isempty(thisIdx)
        warning('could not match imagefile to camera: check if left or right files were used to build 3D reconstruction');
        continue;
    end
    
    Mfiles{i}
    
    %import stereodata
    [pathstr, name, ext] = fileparts(Mfiles{i});
    stereoFile = strcat('./data/',name,'_stereodists.mat');
    load(stereoFile); %loads stereoDists and stereoPoints
    if isempty(stereoDists) || isempty(stereoPoints)
        continue
    else
    meshDists = meshDistances(Mfiles{i},stereoDists, stereoPoints, V, F, T{thisIdx}, camPos{thisIdx}, pCamCalib);
    theseCorrDists = [stereoDists(:,3), meshDists];
    corrDists = [corrDists; theseCorrDists];
    end
    
end

nanIdx = isnan(corrDists(:,2));
corrDists = corrDists(~nanIdx,:);

%determine scalefactor and calibrate mesh.
figure(1)
plot(corrDists(:,1),corrDists(:,2),'or'),xlabel('Stereo distance (m)'),ylabel('Mesh Distance (arb)');
Fit = [ones(size(corrDists,1),1) corrDists(:,1)]\corrDists(:,2);
ScaleFactor = Fit(2);
Vcal = V./ScaleFactor;

stlwrite(outMeshFile,F, Vcal);
dlmwrite('distances.txt',corrDists);

figure(2)
pcshow(Vcal);

