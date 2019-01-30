function [selectedImg, faceCoord] = selectCentralImg(faceIdx, handles )
%find image in which selected face is closest to the center
visFCseen = handles.visFCseen(faceIdx,:);
imgIdx = find(visFCseen);
selectedImg = imgIdx(1);%initialize to first image in which face is visible
%faceCoord = handles.imgCoord{faceIdx, imgIdx(1)}; 
faceCoord = full([handles.imgCoordseen_x(faceIdx, imgIdx(1)),handles.imgCoordseen_y(faceIdx, imgIdx(1))]);
center = [handles.xLim/2 handles.yLim/2];
minDist  = norm(faceCoord - center);
for i = 2:length(imgIdx)
    thisCoord =  full([handles.imgCoordseen_x(faceIdx, imgIdx(i)),handles.imgCoordseen_y(faceIdx, imgIdx(i))]);
    thisDist = norm(thisCoord - center);
    if  thisDist < minDist
        minDist = thisDist;
        faceCoord = thisCoord;
        selectedImg = imgIdx(i);
    end
end
