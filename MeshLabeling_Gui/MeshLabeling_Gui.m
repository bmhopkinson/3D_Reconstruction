function varargout = MeshLabeling_Gui_small(varargin)
% MESHLABELING_GUI_SMALL MATLAB code for MeshLabeling_Gui_small.fig
%      MESHLABELING_GUI_SMALL, by itself, creates a new MESHLABELING_GUI_SMALL or raises the existing
%      singleton*.
%
%      H = MESHLABELING_GUI_SMALL returns the handle to a new MESHLABELING_GUI_SMALL or the handle to
%      the existing singleton*.
%
%      MESHLABELING_GUI_SMALL('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MESHLABELING_GUI_SMALL.M with the given input arguments.
%
%      MESHLABELING_GUI_SMALL('Property','Value',...) creates a new MESHLABELING_GUI_SMALL or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before MeshLabeling_Gui_small_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to MeshLabeling_Gui_small_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help MeshLabeling_Gui_small

% Last Modified by GUIDE v2.5 08-Aug-2017 15:45:50

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @MeshLabeling_Gui_small_OpeningFcn, ...
                   'gui_OutputFcn',  @MeshLabeling_Gui_small_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before MeshLabeling_Gui_small is made visible.
function MeshLabeling_Gui_small_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to MeshLabeling_Gui_small (see VARARGIN)
addpath(genpath('/home/cv-bhlab/Documents/MATLAB/Library/geom3d')); %reading and displaying meshes
addpath(genpath('/home/cv-bhlab/Documents/MATLAB/Library/mesh_utils'));  %reading agisoft camera files, project points, etc
% Choose default command line output for MeshLabeling_Gui_small
handles.output = hObject;
classData = struct('val',1);
set(handles.popupmenu1,'UserData',classData);
xypos = struct('x',0,'y',0);
set(handles.axes1,'UserData',xypos);
handles.classLabels =[];
handles.facesLabeled = [];
handles.counter = 0;
handles.curFace = [];  %active face; index of seen Faces, need to convert back to all faces for output
handles.curImg = []; %active image, loaded into axes 1
handles.xpos = []; %track x, y positions in image locations corresponding to mesh faces
handles.ypos = [];
handles.correspondingImg = [];  %image coresponding to x, y positions 
handles.curX = [];  %current x position in current image
handles.curY = [];  %current y position in current image
handles.ActiveFaceDepth = -5;       % plotted depth of active face - may need to very to make the active face clear in a plot and yet retain some indication of depth for remaining faces; a value of 0 to -5 has been worked so far
handles.ActiveFaceScale = 5;   %factor by which to expand size of active face to make it more visible


%load mesh
fprintf(1,'Select mesh file in off format\n');
[filenameMesh, pathname] = uigetfile({'*.off'}, 'Select mesh file in off format');
fullnameMesh = fullfile(pathname, filenameMesh);
[V, F] = readMesh_off(fullnameMesh);
%axes(handles.axes3)
handles.figure2 = figure;
handles.F = F;
handles.V = V;
plotMesh(F, V, handles.curFace, handles);


%load image file namesloadCam
fprintf(1,'Select image list file\n');
[filenameImg, pathname] = uigetfile({'*.txt'}, 'Select image list file');
fullnameImg = fullfile(pathname, filenameImg);
fid = fopen(fullnameImg);
C = textscan(fid,'%s\n');
handles.imgFiles = C{1}; % don't ask me why
handles.imgFilePath = pathname;
set(handles.listbox3,'String',cellstr(handles.imgFiles));

%load test image to get image dimensions; assumes loadCamall images in data set
%are the same size
I = imread(strcat(handles.imgFilePath, handles.imgFiles{1}));
handles.xLim = size(I, 2);
handles.yLim = size(I, 1);

%load camera matrices file
camVersion = 'v1.4';
fprintf(1,'Select camera matrix file -.xml or processed .mat\n');
[filenameCamMats, pathname] = uigetfile({'*.xml';'*.mat'}, 'Select camera matrix file');  %camera file in agisoft format
fullnameCamMats = fullfile(pathname, filenameCamMats);
[~,~,ext] = fileparts(filenameCamMats);
if(strcmp(ext,'.xml'))
  [Cam, pCamCalib ] = loadCameraData( fullnameCamMats, camVersion );
elseif(strcmp(ext,'.mat'))
   myVars = {'Cam','pCamCalib'};
   load(fullnameCamMats, myVars{:});  %loads  'Cam','pCamCalib
else
    error('file type of camera matrix data not recognized\n');
end

handles.Cam = Cam;      %cell array of camera matrices
handles.pCamCalib = pCamCalib;  %camera calibration structure

%load mesh to image(camera) correspondenses
fprintf(1,'Select FacesVisibleToCamerasData file\n');
[filenameVis, pathname] = uigetfile({'*.mat'}, 'Select FacesVisibleToCamerasData file');
fullnameVis = fullfile(pathname, filenameVis);
load(fullnameVis);  %loads Fcenters (face centers of mesh), visibleFC (Faces x Cameras matrix indicating which mesh faces are visible in which cameras
                % and imCoord_x, imCoord_y (Faces x Cameras cell array that contains image positions corresponding to a given face center);

seenIdx = find(sum(visibleFC,2) ~= 0); %  faces that were not seen should be excluded from further analysis 
nSeen = length(seenIdx);
fprintf(1,'number seen %i\n', nSeen);
handles.seenIdx  = seenIdx;
a =  linspace(1, size(seenIdx,1), size(seenIdx,1));
meshIDMap = containers.Map(seenIdx,a); %map to translate from standard mesh face id to "seen" mesh face id;
handles.meshIDMap = meshIDMap;
handles.visFCseen = visibleFC(seenIdx, :);
handles.imgCoordseen_x = imCoord_x(seenIdx,:);
handles.imgCoordseen_y = imCoord_y(seenIdx,:);
handles.Fcentseen = Fcenters(seenIdx,:);
handles.nVisFaces = nSeen;

set(handles.figure1, 'WindowButtonDownFcn', {@getMousePositionOnImage, hObject});
set(handles.figure1, 'Pointer', 'crosshair'); % Optional

save('handles.mat','handles');
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes MeshLabeling_Gui_small wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = MeshLabeling_Gui_small_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


function getMousePositionOnImage(obj, eventdata, hObject)
% 
 handles = guidata(hObject);
 
 cursorPoint = get(handles.axes1, 'CurrentPoint');
 curX = cursorPoint(1,1);
 curY = cursorPoint(1,2);
 
 xLimits = get(handles.axes1, 'xlim');
 yLimits = get(handles.axes1, 'ylim');
 
 if (curX > min(xLimits) && curX < max(xLimits) && curY > min(yLimits) && curY < max(yLimits))
 %disp(['Cursor coordinates are (' num2str(curX) ', ' num2str(curY) ').']);
 currpos = strcat('x: ',num2str(curX,'%5.1f'),' y:',num2str(curY,'%5.1f'));
 set(handles.text2,'String',currpos)
 data = get(handles.axes1,'UserData');
 data.x = curX;
 data.y = curY;
 set(handles.axes1,'UserData',data);
% display(data);
 axes(handles.axes1);
 plot(curX, curY,'ro','MarkerSize',7)
 %fprintf(1, 'current image %i, x: %f y: %f\n',handles.curImg, curX, curY);
 
 %select face on mesh close to point picked on image
 newFace = projectImPointToMesh_Iter(curX, curY, handles.V, handles.F, handles.Cam(handles.curImg).T, handles.Cam(handles.curImg).camPos, handles.pCamCalib(handles.Cam(handles.curImg).sensor_id));
 if isempty(newFace)
     fprintf(1,'point lies outside bounds of mesh\n');
 else
%     newFaceSeenIdx = find((handles.seenIdx - newFace) == 0);
     newFaceSeenIdx = handles.meshIDMap(newFace);
     if isempty(newFaceSeenIdx)
         fprintf(1, 'image point selected does not match a visible face, please retry\n');
     else
         handles.curFace = newFaceSeenIdx;  %set identified face to current face - indexed to seen faces only
         handles.curX = curX;
         handles.curY = curY;

         %update mesh plot
        V = handles.V;
        F = handles.F;
 
        plotMesh(F, V, handles.curFace, handles);

        %update panel 1
        updatePanel1(handles.curFace, handles);
     end
 end

 else
 disp('Cursor is outside bounds of image.');
 end
 guidata(hObject, handles);  %save handles data
 
 
 
 
% --- Executes on selection change in popupmenu1.
function popupmenu1_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
classes = get(hObject, 'String');
val = get(hObject, 'Value');
str = classes{val};
%fprintf(1, 'string: %s , value: %d\n', str, val);
data = get(hObject,'UserData');
data.val = val;
set(hObject,'UserData',data);   %% stores data in 'UserData' field of 

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu1


% --- Executes during object creation, after setting all properties.
function popupmenu1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton1: ENTER DATA
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
classData = get(handles.popupmenu1,'UserData');
posData = get(handles.axes1,'UserData');
handles.classLabels  = [handles.classLabels classData.val];

outFace = handles.seenIdx(handles.curFace); % map seen faces idx back to all faces index
handles.facesLabeled = [handles.facesLabeled outFace];
handles.xpos = [handles.xpos handles.curX];
handles.ypos = [handles.ypos handles.curY];
handles.correspondingImg = [handles.correspondingImg handles.curImg];

%fprintf(1,'adding face %i with classLabel %i to data set\n', outFace, classData.val);

handles.counter = handles.counter +1;
counterString = strcat('Points Annotated:  ', num2str(handles.counter));
set(handles.text3, 'String',counterString);
lastString = strcat(num2str(handles.counter),' face: ', num2str(outFace,'%i'),...
                   ' Class: ',num2str(classData.val));
set(handles.text4,'String',lastString);
guidata(hObject, handles);  %save handles data


% --- Executes on button press in pushbutton: SAVE DATA
function pushbutton2_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[filename, pathname] = uiputfile('*.txt','Save Annotation Data');
fullname = fullfile(pathname,filename);
fid = fopen(fullname, 'w');
classData = handles.classLabels;
faces = handles.facesLabeled;
xpos = handles.xpos;
ypos = handles.ypos;
corImg = handles.correspondingImg;
for i = 1:length(classData)
    fprintf(fid, '%i\t%i\t%5.1f\t%5.1f\t%i\n',faces(i), classData(i), xpos(i), ypos(i), corImg(i));
end
fclose(fid);


% --- Executes on button press in pushbutton4: CLEAR MARKERS
function pushbutton4_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
axes(handles.axes1);
hold off;
imshow(handles.image);
hold on;

% --- Executes on button press in pushbutton: NEW IMAGE
function pushbutton5_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[filename, pathname] = uigetfile({'*.jpg';'*.tif';'*.tiff'},'Select image file');
fullname = fullfile(pathname, filename); 
I = imread(fullname);
display(filename);
set(handles.text5,'String',filename);
axes(handles.axes1);
hold off;
imshow(I);
hold on;
handles.image = I;
guidata(hObject, handles);

% --- Executes on button press in pushbutton6: CLEAR DATA
function pushbutton6_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.counter = 0;
counterString = strcat('Points Annotated:  ', num2str(handles.counter));
set(handles.text3, 'String',counterString);
handles.classLabels = [];
handles.facesLabeled = [];
handles.xpos = [];
handles.ypos = [];
handles.correspondingImg = [];
set(handles.text4,'String','no data');
axes(handles.axes1);
hold off;
imshow(handles.image);
hold on;
guidata(hObject, handles);


% --- Executes on button press in pushbutton7: RANDOM MESH FACE
function pushbutton7_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
rng('shuffle');
z = rand();
idx = ceil(handles.nVisFaces *z);
handles.curFace = idx;
updatePanel1(handles.curFace, handles); %update panel1
[curImg, faceCoord] = selectCentralImg(handles.curFace, handles);
handles.curImg = curImg;
handles.curX = faceCoord(1);
handles.curY = faceCoord(2);
%update axes1
imgFileToOpen = strcat(handles.imgFilePath, handles.imgFiles{handles.curImg});
I = imread(imgFileToOpen);
set(handles.text5,'String',imgFileToOpen);
axes(handles.axes1);
hold off;
imshow(I);
hold on;
plot(faceCoord(1), faceCoord(2),'ro','MarkerSize',7)
handles.image = I;

%update current position in Text box 2
currpos = strcat('x: ',num2str(handles.curX,'%5.1f'),' y:',num2str(handles.curY,'%5.1f'));
set(handles.text2,'String',currpos)


%update mesh plot
% figure(handles.figure2);
V = handles.V;
F = handles.F;
%C = V(F(:,1),3);  %generally color faces by height, use first vertex in each face (each vertex in a face will be at more or less the same height) 
%C(handles.seenIdx(idx)) = handles.ActiveFaceDepth;  %idx is only from visible faces - map back into all faces
plotMesh(F, V, handles.curFace, handles);

guidata(hObject, handles);


% --- Executes on selection change in listbox3. LOAD IMAGES 
function listbox3_Callback(hObject, eventdata, handles)
% hObject    handle to listbox3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox3 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox3

get(handles.figure1, 'SelectionType');
if (strcmp(get(handles.figure1,'SelectionType'), 'open'))
    handles.curImg = get(handles.listbox3,'Value');
    imgFileToOpen = strcat(handles.imgFilePath,  handles.imgFiles{handles.curImg});
    I = imread(imgFileToOpen);
    set(handles.text5,'String',imgFileToOpen);
    axes(handles.axes1);
    hold off;
    imshow(I);
    hold on;
    handles.image = I;
    guidata(hObject, handles);
end


% --- Executes during object creation, after setting all properties.
function listbox3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over popupmenu1.
function popupmenu1_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
