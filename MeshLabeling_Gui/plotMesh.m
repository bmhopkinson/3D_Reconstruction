function [ output_args ] = plotMesh( F, V, activeFace, handles )
%plot mesh data in figure 2. 
if isempty(activeFace)
    C = V(:,3);
else
    C = V(F(:,1),3);  %generally color faces by height, use first vertex in each face (each vertex in a face will be at more or less the same height) 
    C(handles.seenIdx(activeFace)) = handles.ActiveFaceDepth;  %idx is only from visible faces - map back into all faces
end

figure(handles.figure2);
hold off
trisurf(F, V(:,1), V(:,2), -1.*V(:,3),-1.*C);
hold on
view([0 90]);
axis image;
shading flat;

%plot scaled version of active face to make it easier to see
if ~isempty(activeFace);
    activeFace_all = handles.seenIdx(activeFace);
    X = V(F(activeFace_all,:)',1);
    Y = V(F(activeFace_all,:)',2);
    Z = V(F(activeFace_all,:)',3);
    Fcenter = [mean(X), mean(Y), mean(Z)];
    XYZnorm = [X Y Z] - repmat(Fcenter, 3, 1); 
    XYZnorm =   handles.ActiveFaceScale .* XYZnorm;
    Xs = XYZnorm(:,1) + Fcenter(1);
    Ys = XYZnorm(:,2) + Fcenter(2);
    Zs = XYZnorm(:,3) + Fcenter(3);
    patch(Xs,Ys,-1.*Zs,'red');

end
% X = [0; 0; 1];
% Y = [0; 1; 0];
% Z = [0; 0; 0];
% patch(X, Y, Z,'red');

end

