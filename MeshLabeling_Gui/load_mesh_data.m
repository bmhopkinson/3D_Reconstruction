function handles = load_mesh_data(handles,varargin)
%load input data needed for MeshLabling_Gui, varargin can hold path to
%infile

addpath(genpath('/home/cv-bhlab/Documents/MATLAB/Library/matGeom/matGeom/'));
%load input data

if(isempty(varargin))
    fprintf(1,'Select infile\n');
    [infile_name, pathname] = uigetfile({'*.txt'}, 'Select infile');
    infile_fullname = fullfile(pathname,infile_name);
else
    infile_fullname = varargin{1};
end

fid = fopen(infile_fullname);

if fid ==-1
    error(['File' infile_fullname 'not found or permission denied.']);
end

data_filenames = struct('mesh',[],'image_list',[],'image_path',[],'cameras',[],'faceVis',[],'annotation_list',[],'test_path',[], 'test_file',[]);

while ~feof(fid)
    raw = fgetl(fid);
    cooked = sscanf(raw,'%s[\t]%*s');
    
    switch cooked
        
        case 'mesh_file'
            data_filenames.mesh = sscanf(raw,'%*s\t%s');
        case 'image_list'
            data_filenames.image_list = sscanf(raw,'%*s\t%s');
        case 'image_path'
            data_filenames.image_path = sscanf(raw,'%*s\t%s');
        case 'camera_file'
            data_filenames.cameras = sscanf(raw,'%*s\t%s');
        case 'faceVis_file'
            data_filenames.faceVis = sscanf(raw,'%*s\t%s'); 
        case 'annotation_list'
            data_filenames.annotation_list = sscanf(raw,'%*s\t%s'); 
        case 'test_path'
            data_filenames.test_path = sscanf(raw,'%*s\t%s'); 
        case 'test_file'
            data_filenames.test_file = sscanf(raw,'%*s\t%s'); 
    end
end

fclose(fid);

%load mesh
[V, F] = readMesh_off(data_filenames.mesh);
handles.V = V;
handles.F = F;

%load image list 
fim = fopen(data_filenames.image_list);
C = textscan(fim,'%s\n');
handles.imgFiles = C{1};
handles.imgFilePath = data_filenames.image_path;

%load camera data

[~,~,ext] = fileparts(data_filenames.cameras);
if(strcmp(ext,'.xml'))
  [Cam, pCamCalib ] = loadCameraData( data_filenames.cameras);
elseif(strcmp(ext,'.mat'))
   myVars = {'Cam','pCamCalib'};
   load(data_filenames.cameras, myVars{:});  %loads  'Cam','pCamCalib
else
    error('file type of camera matrix data not recognized\n');
end

handles.Cam = Cam;      %cell array of camera matrices
handles.pCamCalib = pCamCalib;  %camera calibration structure


%load (and process) faceVis data
load(data_filenames.faceVis);  %loads Fcenters (face centers of mesh), visibleFC (Faces x Cameras matrix indicating which mesh faces are visible in which cameras
                % and imCoord_x, imCoord_y (Faces x Cameras cell array that contains image positions corresponding to a given face center);

seenIdx = find(sum(visibleFC,2) ~= 0); %  faces that were not seen should be excluded from further analysis 
nSeen = length(seenIdx);

handles.seenIdx  = seenIdx;
a =  linspace(1, size(seenIdx,1), size(seenIdx,1));
meshIDMap = containers.Map(seenIdx,a); %map to translate from standard mesh face id to "seen" mesh face id;
handles.meshIDMap = meshIDMap;
handles.visFCseen = visibleFC(seenIdx, :);
handles.imgCoordseen_x = imCoord_x(seenIdx,:);
handles.imgCoordseen_y = imCoord_y(seenIdx,:);
handles.Fcentseen = Fcenters(seenIdx,:);
handles.nVisFaces = nSeen;

%load annotation data
fan = fopen(data_filenames.annotation_list,'r');
D = textscan(fan,'%s\n');
handles.ann_strings = D{1}; 

%load test data if being used
handles.test_frac = -1;
if(~isempty(data_filenames.test_file))
   handles.test_path = data_filenames.test_path;
   load(data_filenames.test_file); %loads test_data
   handles.test_data = test_data;
   handles.test_frac = 0.25;
end


end