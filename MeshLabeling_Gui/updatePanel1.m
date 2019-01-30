function [ output_args ] = updatePanel1( faceIdx, handles )
%update panel1 with up to 6 images showing center point of selected mesh face in
%original images
visFCseen = handles.visFCseen(faceIdx,:);
nImgs = sum(visFCseen,2);

nPlot = min([6, nImgs]);
imgIdx = find(visFCseen);

if nImgs > 6
   frac = 6/nImgs;
   randVec = rand(nImgs,1);
   select = zeros(nImgs,1);
   select(randVec < frac) = 1;
   imgIdx = imgIdx(select == 1);
   if (length(imgIdx) < 6)
       nPlot = length(imgIdx); %this will happen sometimes
   end
end



figure(handles.figure1);

%update panel 1: close up fragments 
delete(findobj(handles.uipanel1,'type', 'axes'));  %erases all axes in panel1 - this was tricky 
hsp = 1/3; %horizontal spacing
vsp = 1/2; %vertical spacing
for j = 1:nPlot
    I = imread(strcat(handles.imgFilePath, handles.imgFiles{imgIdx(j)}));
    fprintf(1,'%s\n',handles.imgFiles{imgIdx(j)});
  %  thisPoint = squeeze(handles.imgCoord(faceIdx, imgIdx(j),:));
    %thisPoint = handles.imgCoordseen(faceIdx, (2*imgIdx(j)-1):2*imgIdx(j));
    thisPoint =[handles.imgCoordseen_x(faceIdx, imgIdx(j)), handles.imgCoordseen_y(faceIdx, imgIdx(j))];
    %trim image around point
    imRange = 150;
    [I, thisPointTrim] = trimImage(I, thisPoint, imRange);
    I = insertShape(I, 'Circle', [thisPointTrim 5],'LineWidth',3);  %format for location (3rd argument) is [x, y, radius]
    %subplot(2, 3, j, 'Parent', handles.uipanel1)
    if j <= 3
        lpos = hsp .* (j-1);
        vpos = vsp;
    else
        lpos = hsp .* (j-4);
        vpos = 0;
    end
   
    subplot('Position',[lpos, vpos, hsp, vsp ], 'Parent', handles.uipanel1);
   %subplot('Position',[0, 0, 0.5, 0.5 ], 'Parent', handles.uipanel1);
  
    imshow(I);
end


end

