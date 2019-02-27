function [ Cam, pCamCalib ] = loadCameraData( cameraFile )
%load camera positions, calibrations, etc corresponding to current mesh
%from camera file in agisoft format

%% Load Cameras %%

camXML = xmlread(cameraFile);

%calibration data
[pCamCalib, sensorID_map] = extractCalibrationData(camXML);

%check for reconstruction transform (e.g. metric scaling) 
chunks = camXML.getElementsByTagName('chunk'); 
this_chunk = chunks.item(0).getChildNodes; %assuming only one chunk right now
node = this_chunk.getFirstChild;
found_transform = 0;
while ~isempty(node)
    if strcmpi(node.getNodeName,'transform')
        found_transform = 1;
        break;
    else 
        node = node.getNextSibling;
    end
end

scale = 1.0000; %default no scaling 

if found_transform == 1
    try 
        scale_node = node.getElementsByTagName('scale');
        scale = sscanf(char(scale_node.item(0).getFirstChild.getData), '%f');
        fprintf(1,'scale %f \n', scale);
    catch  %if failure means no scale
    end
end

%camera tranform matrices
allCameras = camXML.getElementsByTagName('camera');
nCams = allCameras.getLength;
nCamAln = 0; %number of aligned cameras

for k = 0:nCams-1
    thisCamera = allCameras.item(k);
 
    sensor_id_raw = char(thisCamera.getAttribute('sensor_id'));
    sensor_id = sensorID_map(sensor_id_raw); %values are not entirely predictable - use a map to organize; sometime start with 0, sometime 1, so map to predictable ones based integers 
    label = char(thisCamera.getAttribute('label'));
    
    
    if(strcmp(char(thisCamera.getAttribute('enabled')),'0'))  %disabled camera - ignore
       % fprintf(1,'disabled camera %s\n',label);
        continue;
    end
    
    
    
    %fprintf(1,'%i\n',sensor_id);
    try
        thisTransform = thisCamera.getElementsByTagName('transform');
        dataString = thisTransform.item(0).getFirstChild.getData;   %should be 1 transform if cam is aligned, none otherwise
        Ttemp = textscan(char(dataString),'%f');
        Ttemp = reshape(Ttemp{1}, 4, 4);
        
        %having successfully extracted transform, compute some values
        nCamAln = nCamAln + 1;
        Ttemp = Ttemp';
        Ttemp(1:3,4) = scale .* Ttemp(1:3,4);
        T = Ttemp;
        camPos = T(1:3,4);
        Tinv = inv(T); %inverse transform is needed for mapping world points to camera points
        R = Tinv(1:3,1:3); %rotation matrix
        t = Tinv(1:3,4);  %translation vector
        
        %store transforms, etc for future use
        Cam(nCamAln).T = T;
        Cam(nCamAln).Tinv = Tinv;
        Cam(nCamAln).R = R;
        Cam(nCamAln).t = t;
        Cam(nCamAln).camPos = camPos;
        Cam(nCamAln).sensor_id = sensor_id;
        Cam(nCamAln).label = label;
    catch  %if failure means camera was not aligned so ignore
    end
end

fprintf(1,'extracted camera data for %d cameras\n', nCamAln);
end