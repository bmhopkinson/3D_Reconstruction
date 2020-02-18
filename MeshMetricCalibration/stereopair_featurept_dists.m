function [outDists, outPoints] = stereopair_featurept_dists(I1, I2, stereoParams)

%stereorectification and disparity map generation based on Matlab toolbox functions. 
%use stereocamera calibrations obtained from 'stereoCameraCalibrator' application in matlab (gives very similar calibrations to Caltech matlab camera calibration toolb
addpath(genpath('/home/brian/Documents/MATLAB/Computer_Vision/toolboxes/vlfeat-0.9.20/'));
addpath(genpath('/home/brian/Documents/MATLAB/Library/geom2d'));

%% Tunable Parameters
minDisp = 0;  %minimum pixel difference in stereo matching procedure
maxDisp = 96; %minimum pixel difference in stereo matching procedure (note difference between min and max must be divisible by 16
minDepth = 0;  %depths shallower than this are flagged as invalid, meters
maxDepth = 5;  %depths deeper than this are flagged as invalid, meters
MaxPoints = 20; %max number of points between which distances are computed in each stereopair

%% Stereo reconstruction
[R1_valid, R2_valid] = rectifyStereoImages(I1,I2, stereoParams,'OutputView','valid');

disparityRange = [minDisp maxDisp];  %difference must be divisible by 16
disparityMap = disparity(rgb2gray(R1_valid),rgb2gray(R2_valid),'BlockSize',15, 'DisparityRange',disparityRange);
% 
errIdx = (disparityMap == -realmax('single'));

%create metric steroreconstruction using pinhole camera model - does not account for radial distortion (which is quite small with GoPros underwater)
Baseline = norm(stereoParams.TranslationOfCamera2)./1000; %stereobasline in meters
favg = mean(stereoParams.CameraParameters1.FocalLength);  %focal length in pixels
depth = favg.*Baseline./(double(disparityMap));  %first determine depth (i.e. z dimension - distance of point from principal plane)

%get an index of all invalid depths and for viewing purposes replace problematic depths with mean
OutIdx = (depth < minDepth) | (depth > maxDepth);
depthInvalidIdx = errIdx | OutIdx;
depthView = depth;
meanDepth = mean(mean(depth(~depthInvalidIdx)));
depthView(depthInvalidIdx) = meanDepth;

figure(1)
imagesc(depthView);
xc_center = stereoParams.CameraParameters1.PrincipalPoint(1);      %camera center location from calibration
yc_center = stereoParams.CameraParameters1.PrincipalPoint(2); 
xc = repmat(linspace(1, size(depth,2),size(depth,2)), size(depth,1),1) - xc_center;
yc = repmat(linspace(1, size(depth,1),size(depth,1))', 1,size(depth,2)) - yc_center;
xw = xc.*depth./favg;
yw = yc.*depth./favg;
xyzWorld = cat(3, xw, yw, depth); %final array providing metric xyz coordinates for each point in the image; need to generate an accomanying logical matrix indicating which points are valid
figure(2);
pcshow([xw(:),yw(:),depthView(:)]);  %at a global scale this reconstruction looks very bad, but i compared it to the matlab reconstruction below and actually they're pretty similar
                                       % a zoom in though on both my and the matlab reconstructScene output shows that actually the bulk of hte data looks good -but the outliers stand out in global view
                                     

%% detect SIFT feature points; work with figure 1 because disparities are referenced to this image
I1gray = single(rgb2gray(I1));
R1gray = single(rgb2gray(R1_valid));
[fI,dI] = vl_sift(I1gray,'PeakThresh',5);
[fR,dR] = vl_sift(R1gray,'PeakThresh',5);
[matches, scores] = vl_ubcmatch(dI, dR); %feature matching 
xImatch = fI(1:2,matches(1,:))';
xRmatch = fR(1:2,matches(2,:))';

try
    [F, inlierIdx] = estimateFundamentalMatrix(xImatch, xRmatch); %double check feature matching by RANSAC estimation of fundamental matrix - surprisingly there are many errors
catch
    outDists = [];
    outPoints = [];
    fprintf(1,'could not estimate fundamental matrix for this image\n');
    return
end
    
xImatch_in = round(xImatch(inlierIdx,:)); %pull out inliers and convert x,y positions to integers
xRmatch_in = round(xRmatch(inlierIdx,:));

%% Eliminate matches without valid xyzWorld data 
nMatches = size(xRmatch_in, 1);
invalidMatches = zeros(nMatches,1);
for i = 1:nMatches
    thisInvalid = depthInvalidIdx(xRmatch_in(i,2), xRmatch_in(i,1));
    if thisInvalid == 1
        invalidMatches(i) = 1;
    end
end
xImatch_in = xImatch_in(~invalidMatches,:);
xRmatch_in = xRmatch_in(~invalidMatches,:);

%% take first ten randomly selected points and calculate distances between
%them; disparities are referenced to image 1 

nMatchesValid = size(xImatch_in,1);
if nMatchesValid >= MaxPoints
    nSel = MaxPoints;  %select the maximum number of points to compute distances between
else
    nSel = nMatchesValid; %if there aren't enought points for max, take all
end
    
perm = randperm(nMatchesValid);   %randomize inlying matches prior to selection of a subset, they are ordered by location in figure otherwise
xImatch_in = xImatch_in(perm,:);  %keep xI and xJ matches in the same order 
xRmatch_in = xRmatch_in(perm,:);

xImatch_sel = xImatch_in(1:nSel, :);
xJmatch_sel = xRmatch_in(1:nSel, :);

figure(4)
showMatchedFeatures(I1, R1_valid, xImatch_sel, xJmatch_sel,'montage');


xyzMatches = zeros(nSel,3);
for i = 1:nSel
    xyzMatches(i,:) = reshape(xyzWorld(xJmatch_sel(i,2), xJmatch_sel(i,1),:),1,[]);
end

D = distancePoints(xyzMatches, xyzMatches);  %from geom2D package

%create matrices with relavent data for output
outDists=[];
for i = 1:nSel
    for j = i+1:nSel
        outDists = [outDists; i,j, D(i,j)];
    end
end

outPoints = [xImatch_sel, xyzMatches];



return







