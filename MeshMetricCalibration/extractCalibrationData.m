function [ pCamCalib, res ] = extractCalibrationData( camXML)
%gets sensor calibration data from agisoft xml camera file
%addpath('/home/brian/Documents/MATLAB/Library/xml'); %needed for xml2struct function

docInfo = camXML.getElementsByTagName('document');
version_full = docInfo.item(0).getAttribute('version');
version = 0;
if (strcmp(version_full, '1.2.0') || strcmp(version_full, '1.3.0'))
    version = 1;
elseif strcmp(version_full,'1.4.0')
    version = 2;
end

allSensors = camXML.getElementsByTagName('sensor'); 

%currently only one sensor so just analyze it
thisSensor = allSensors.item(0);

thisResolution = thisSensor.getElementsByTagName('resolution'); %resolution is listed twice for each sensor so this will return two nodes, just pick one - they're identical in all instances i've seen
width = char(thisResolution.item(0).getAttribute('width'));
height = char(thisResolution.item(0).getAttribute('height'));
res.width = sscanf(width,'%i');
res.height = sscanf(height,'%i');

%extract xml elements
if version == 1
  fxelms = thisSensor.getElementsByTagName('fx');
  fyelms = thisSensor.getElementsByTagName('fy');
end

if version == 2
  felms = thisSensor.getElementsByTagName('f');
end

cxelms = thisSensor.getElementsByTagName('cx');
cyelms = thisSensor.getElementsByTagName('cy');
p1elms = thisSensor.getElementsByTagName('p1');
p2elms = thisSensor.getElementsByTagName('p2');

%parse strings 
if version == 1
  pCamCalib(1).fx = sscanf(char(fxelms.item(0).getFirstChild.getData), '%f');
  pCamCalib(1).fy = sscanf(char(fyelms.item(0).getFirstChild.getData), '%f');
  pCamCalib(1).cx = sscanf(char(cxelms.item(0).getFirstChild.getData), '%f');
  pCamCalib(1).cy = sscanf(char(cyelms.item(0).getFirstChild.getData), '%f');
end
if version == 2
  f = sscanf(char(felms.item(0).getFirstChild.getData), '%f');
  pCamCalib(1).fx = f;
  pCamCalib(1).fy = f;
  cx_off = sscanf(char(cxelms.item(0).getFirstChild.getData), '%f');
  cy_off = sscanf(char(cyelms.item(0).getFirstChild.getData), '%f');
  pCamCalib(1).cx = 0.5*res.width + cx_off;
  pCamCalib(1).cy = 0.5*res.height + cy_off;
end


pCamCalib(1).p1 = sscanf(char(p1elms.item(0).getFirstChild.getData), '%f');
pCamCalib(1).p2 = sscanf(char(p2elms.item(0).getFirstChild.getData), '%f');

%radial distortion parameters are not always there (?)
try
    k1elms = thisSensor.getElementsByTagName('k1');
    pCamCalib(1).k1 = sscanf(char(k1elms.item(0).getFirstChild.getData), '%f');
catch
    pCamCalib(1).k1 = 0;
end
try
    k2elms = thisSensor.getElementsByTagName('k2');
    pCamCalib(1).k2 = sscanf(char(k2elms.item(0).getFirstChild.getData), '%f');
catch
    pCamCalib(1).k2 = 0;
end
try
    k3elms = thisSensor.getElementsByTagName('k3');
    pCamCalib(1).k3 = sscanf(char(k3elms.item(0).getFirstChild.getData), '%f');
catch 
    pCamCalib(1).k3 = 0;
end



end

