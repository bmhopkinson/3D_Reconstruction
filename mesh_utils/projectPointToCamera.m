function [ x,y, x_pinhole, y_pinhole ] = projectPointToCamera(pWorld, Tinv, pCamCalib )
%reproject into cameras based on what i found on the photoscan forum and
% Appendix C. Camera Models of the Photoscan manual
%tested and found that it works perfectly for unscaled models, but wasn't
%able to get it quite correct for scaled models - will need to work on it.

pWorld = [pWorld 1.0e+00]; %convert to homogeneous coordinates

%unpack calibration data for clarity
fx = pCamCalib.fx;
fy = pCamCalib.fy;
cx = pCamCalib.cx;
cy = pCamCalib.cy;
k1 = pCamCalib.k1;
k2 = pCamCalib.k2;
k3 = pCamCalib.k3;
p1 = pCamCalib.p1;
p2 = pCamCalib.p2;


pCam = Tinv*pWorld';  %convert world points to local camera coordinates
pinh = pCam(1:2)./pCam(3);  %scale by z-distance from camera 
r = norm(pinh);

% use pinhole projections for basic sanity check (can get some points way outside the camera view
% projecting into camera with nonlinear corrections (radial distortion etc)
x_pinhole = cx + pinh(1)*fx;
y_pinhole = cy + pinh(2)*fy;

xp = pinh(1).*(1+k1*r^2 + k2*r^4 + k3*r^6) + (p1*(r^2+2*pinh(1)^2) + 2*p2*pinh(1)*pinh(2));
yp = pinh(2).*(1+k1*r^2 + k2*r^4 + k3*r^6) + (p2*(r^2+2*pinh(2)^2) + 2*p1*pinh(1)*pinh(2));
x = cx + xp*fx;
y = cy + yp*fy;

end

