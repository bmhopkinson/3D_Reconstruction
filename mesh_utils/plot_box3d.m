function [outputArg1] = plot_box3d(lb,ub,color)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

%face 1 - at z_min
plot3([lb(1) ub(1) ub(1) lb(1) lb(1) ], [lb(2) lb(2) ub(2)  ub(2) lb(2)], [lb(3) lb(3) lb(3) lb(3) lb(3)],color)
hold on;
%face 2 - at z_max
plot3([lb(1) ub(1) ub(1) lb(1) lb(1) ], [lb(2) lb(2) ub(2)  ub(2) lb(2)], [ub(3) ub(3) ub(3) ub(3) ub(3)],color)

%connect faces
plot3([lb(1), lb(1)],[lb(2), lb(2)],[lb(3) ub(3)],color);
plot3([ub(1), ub(1)],[lb(2), lb(2)],[lb(3) ub(3)],color);
plot3([ub(1), ub(1)],[ub(2) ub(2)],[lb(3) ub(3)],color);
plot3([lb(1), lb(1)],[ub(2) ub(2)],[lb(3) ub(3)],color);

end

