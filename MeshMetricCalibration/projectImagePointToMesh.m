function [ pCor, faceIdx ] = projectImagePointToMesh( ximg, yimg, V, F, T, camPos, pCamCalib)
%projects image point (ximg, yimg) to mesh (V, F) returning index of
%interescted face
%neglect radial distortion b/c inverting is complex and i just need crude reprojection right now

% %unpack calibration data for clarity
fx = pCamCalib.fx;
fy = pCamCalib.fy;
cx = pCamCalib.cx;
cy = pCamCalib.cy;

xp = (ximg - cx)./fx;  %this is a point along the line connecting the camera center to the original world point, but in the camera refernce frame
yp = (yimg - cy)./fy;

p1 = [xp; yp; 1; 1];  %in focal length normalized coordinates (i.e z = 1) but that's fine b/c i just need a point along the line connecting camera center to world point
p1world = T*p1;
line = createLine3d(camPos',p1world(1:3)');
[points, pos, faceInds] = intersectLineMesh3d(line, V, F);

if length(pos) > 1  %if the line interescts multiple point on the mesh, the first interscetion should be the one that's visible
    [m, i] = min(abs(pos));
    pCor = points(i,:);
    faceIdx = faceInds(i);
elseif length(pos) == 1
    pCor = points;
    faceIdx = faceInds;
else 
    pCor = [NaN, NaN, NaN]; %point does not exist in Mesh
    faceIdx = NaN;
    
end



end

