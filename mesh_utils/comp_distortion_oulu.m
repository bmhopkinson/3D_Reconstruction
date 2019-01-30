function [x] = comp_distortion_oulu(xd, k, p)
%modified from J-Y Bouguet Camera Calibration Toolbox for Matlab
%comp_distortion_oulu.m
%
%[x] = comp_distortion_oulu(xd,k)
%
%Compensates for radial and tangential distortion. Model From Oulu university.
%For more informatino about the distortion model, check the forward projection mapping function:
%project_points.m
%
%INPUT: xd: distorted (normalized) point coordinates in the image plane (2xN matrix)
%       k: Distortion coefficients (radial and tangential) (4x1 vector)
%
%OUTPUT: x: undistorted (normalized) point coordinates in the image plane (2xN matrix)
%
%Method: Iterative method for compensation.
%
%NOTE: This compensation has to be done after the subtraction
%      of the principal point, and division by the focal length.




k1 = k(1);
k2 = k(2);
k3 = k(3);
p1 = p(1);
p2 = p(2);

x = xd; 				% initial guess

for kk=1:20

    r_2 = sum(x.^2);
    k_radial =  1 + k1 * r_2 + k2 * r_2.^2 + k3 * r_2.^3;
    delta_x = [2*p1*x(1,:).*x(2,:) + p2*(r_2 + 2*x(1,:).^2);
    p1 * (r_2 + 2*x(2,:).^2)+2*p2*x(1,:).*x(2,:)];
    x = (xd - delta_x)./(ones(2,1)*k_radial);

end;


    