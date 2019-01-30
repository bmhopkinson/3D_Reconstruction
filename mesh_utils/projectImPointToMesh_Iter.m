function [ faceIdx ] = projectImPointToMesh_Iter( ximg, yimg, V, F, T, camPos, pCamCalib)
%projects image point (ximg, yimg) to mesh (V, F) returning index of
%interescted face
%compenstates for radial and tangential distortion using iterative approach (using func from JY Bouguet camera calibration toolbox).
T
camPos

% %unpack calibration data for clarity
fx = pCamCalib.fx;
fy = pCamCalib.fy;
cx = pCamCalib.cx;
cy = pCamCalib.cy;
k1 = pCamCalib.k1;
k2 = pCamCalib.k2;
k3 = pCamCalib.k3;
p1 = pCamCalib.p1;
p2 = pCamCalib.p2;

xp = (ximg - cx)./fx;  
yp = (yimg - cy)./fy;

%iteratively correct for radial distortion and tangential distortion
pinh = comp_distortion_oulu([xp; yp], [k1 k2 k3], [p1 p2]); 
fprintf('distortion compensated pinh(1): %f  pinh(1): %f\n',pinh(1), pinh(2));
fprintf('neglecting distorion xp: %f yp: %f\n', xp, yp);

%p1 is a point along the line connecting the camera center to the original world point, but in the camera refernce frame
p1 = [pinh(1); pinh(2); 1; 1];  %in focal length normalized coordinates (i.e z = 1) but that's fine b/c i just need a point along the line connecting camera center to world point
p1world = T*p1;
line = createLine3d(camPos',p1world(1:3)');
[points, pos, faceInds] = intersectLineMesh3d(line, V, F);

if length(pos) > 1  %if the line interescts multiple point on the mesh, the first interscetion should be the one that's visible
    [m, i] = min(abs(pos));
    pCor = points(i,:);
    faceIdx = faceInds(i);
else
    pCor = points;
    faceIdx = faceInds;
    
end



end

