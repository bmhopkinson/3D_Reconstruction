function [ output_args ] = updatePanel1( patches, handles )
%update panel1 with up to 6 images showing center point of selected mesh face in
%original images


figure(handles.figure1);

%update panel 1: close up fragments 
delete(findobj(handles.uipanel1,'type', 'axes'));  %erases all axes in panel1 - this was tricky 
hsp = 1/3; %horizontal spacing
vsp = 1/2; %vertical spacing

nPlot = size(patches,2);
for j = 1:nPlot

    %subplot(2, 3, j, 'Parent', handles.uipanel1)
    if j <= 3
        lpos = hsp .* (j-1);
        vpos = vsp;
    else
        lpos = hsp .* (j-4);
        vpos = 0;
    end
   
    subplot('Position',[lpos, vpos, hsp, vsp ], 'Parent', handles.uipanel1);
  
    imshow(patches{j});
end


end

