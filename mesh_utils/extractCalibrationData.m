function [ pCamCalib, sensorID_map] = extractCalibrationData( camXML, version )
%gets sensor calibration data from agisoft xml camera file
%addpath('/home/brian/Documents/MATLAB/Library/xml'); %needed for xml2struct function
allSensors = camXML.getElementsByTagName('sensor'); 
nSensors = allSensors.getLength;

sensorID_map = containers.Map;

%loop through sensors - data available is highly variable so every element access is
%in a try catch block
for i = 1:nSensors
    thisSensor = allSensors.item(i-1); %xml interface uses zero based indexing
    sensor_id_raw = char(thisSensor.getAttribute('id'));
    sensorID_map(sensor_id_raw) = i;
    
    % camera resolution
    try
      thisResolution = thisSensor.getElementsByTagName('resolution'); %resolution is listed twice for each sensor so this will return two nodes, just pick one - they're identical in all instances i've seen
      width = char(thisResolution.item(0).getAttribute('width'));
      height = char(thisResolution.item(0).getAttribute('height'));
      pCamCalib(i).width = sscanf(width,'%i');
      pCamCalib(i).height = sscanf(height,'%i');
    catch
      pCamCalib(i).width = 0;
      pCamCalib(i).height = 0;
    end
    

    %camera focal length (pixels)
    if version == 'v1.2'
      try
        fxelms = thisSensor.getElementsByTagName('fx');
        fyelms = thisSensor.getElementsByTagName('fy');
        pCamCalib(i).fx = sscanf(char(fxelms.item(0).getFirstChild.getData), '%f');
        pCamCalib(i).fy = sscanf(char(fyelms.item(0).getFirstChild.getData), '%f');
      catch
        pCamCalib(i).fx = 0;
        pCamCalib(i).fy = 0;
      end
    end

    if version == 'v1.4'
      try
        felms = thisSensor.getElementsByTagName('f');
        f = sscanf(char(felms.item(0).getFirstChild.getData), '%f');
        pCamCalib(i).fx = f;
        pCamCalib(i).fy = f;
      catch
        pCamCalib(i).fx = 0;
        pCamCalib(i).fy = 0;
      end
    end

    %camera center parameters
    try 
      cxelms = thisSensor.getElementsByTagName('cx');
      cyelms = thisSensor.getElementsByTagName('cy');
      cx_val = sscanf(char(cxelms.item(0).getFirstChild.getData), '%f');
      cy_val = sscanf(char(cyelms.item(0).getFirstChild.getData), '%f');
      %parse strings 
      if version == 'v1.2'
        pCamCalib(i).cx = cx_val;
        pCamCalib(i).cy = cy_val;
      elseif version == 'v1.4'
        pCamCalib(i).cx = 0.5*pCamCalib(i).width  + cx_val;
        pCamCalib(i).cy = 0.5*pCamCalib(i).height + cy_val;
      end
    catch
        pCamCalib(i).cx = 0;
        pCamCalib(i).cy = 0;
    end
    
    %tangential distortion parameters  
    try  
      p1elms = thisSensor.getElementsByTagName('p1');
      p2elms = thisSensor.getElementsByTagName('p2');
      pCamCalib(i).p1 = sscanf(char(p1elms.item(0).getFirstChild.getData), '%f');
      pCamCalib(i).p2 = sscanf(char(p2elms.item(0).getFirstChild.getData), '%f');
    catch
      pCamCalib(i).p1 = 0;
      pCamCalib(i).p2 = 0;
    end

    %radial distortion parameters are not always there (?)
    try
        k1elms = thisSensor.getElementsByTagName('k1');
        pCamCalib(i).k1 = sscanf(char(k1elms.item(0).getFirstChild.getData), '%f');
    catch
        pCamCalib(i).k1 = 0;
    end
    try
        k2elms = thisSensor.getElementsByTagName('k2');
        pCamCalib(i).k2 = sscanf(char(k2elms.item(0).getFirstChild.getData), '%f');
    catch
        pCamCalib(i).k2 = 0;
    end
    try
        k3elms = thisSensor.getElementsByTagName('k3');
        pCamCalib(i).k3 = sscanf(char(k3elms.item(0).getFirstChild.getData), '%f');
    catch 
        pCamCalib(i).k3 = 0;
    end

end

end

