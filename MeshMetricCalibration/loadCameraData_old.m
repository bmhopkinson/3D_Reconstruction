function [Label, T, Tinv,camPos, pCamCalib ] = loadCameraData( cameraFile )
%load camera positions, calibrations, etc corresponding to current mesh
%from camera file in agisoft format

camXML = xmlread(cameraFile);

%calibration data
[pCamCalib, res] = extractCalibrationData(camXML); %NOTE: right now this assumes only ONE CAMERA is used 

%obtain camera label and tranform matrices
allCameras = camXML.getElementsByTagName('camera');

nCams = allCameras.getLength;
for k = 0:(nCams-1)
    thisCamera = allCameras.item(k);
    Label{k+1} = char(thisCamera.getAttribute('label'));
    thisTransform = thisCamera.getElementsByTagName('transform');
     for i = 1:thisTransform.getLength  %this mess is necesary because different versions of the agisoft camera xml file seem to be structured slightly differently
         node = thisTransform.item(i-1);
         thisData  = char(node.getFirstChild.getNodeValue);
         if(all(isspace(thisData)))
             continue
         else 
         dataString = thisData; %first non whitespace node should be the data
         end
     end
   % CameraChildren = thisCamera.getChildNodes;
   % thisTransform = CameraChildren.item(1);  %item(0) is the whitespace of camera element (very strange)
    
    %node = thisTransform.item(0);
    %dataString = node.getFirstChild.getNodeValue;
 %   dataString = thisTransform.getFirstChild.getData;
    Ttemp = textscan(dataString,'%f');
    Ttemp2 = reshape(Ttemp{1}, 4, 4);
    T{k+1} = Ttemp2';
end


%now perform some calculations on the camera transforms
for i= 1:nCams
    thisTinv = inv(T{i});  %inverse transform is needed for mapping world points to camera points
    Tinv{i} = thisTinv; 
    R{i} = thisTinv(1:3, 1:3);  %rotation matrix
    t{i} = thisTinv(1:3,4); %translation vector
    camPos{i} = -inv(R{i})*t{i};
end


end

