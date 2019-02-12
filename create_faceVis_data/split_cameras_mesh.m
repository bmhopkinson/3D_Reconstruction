function [Vsets_out, Fsets_out] = split_cameras_mesh(Cam, pCamCalib, V,F,depth)


%group cameras spatially (e.g. aabb tree) then split mesh into exclusive
%groups of faces associated with camera groups
% 
% overall approach is:
% 1. group cameras spatially using aabb tree - at two levels: major groups,
% minor groups
% 2. idenfity faces viewed by each group (minor)
% 3. determine overlap of faces between minor groups
% 4. exclusively allocate faces to minor groups using greedy algorithm-
% when faces are acquired from a group, add that group's cameras to
% acquiring group
% 5. Aggregate minor groups to major
%% 1. split cameras spatially used aabb tree into major and minor groups

n_groups = 2^depth;
nCams = size(Cam, 2);

%extract camera positions
camPos = zeros(nCams,3);

for i=1:nCams
    camPos(i,:) = Cam(i).camPos;
end


node_min = max(10, round(nCams/(n_groups*10)));
op.nobj = node_min;
tr = maketree([camPos, camPos],op);  % from D. Engwirda's aabb tree matlab library

%descend tree to split depth and then collect all leaf nodes contained by
%nodes at 'level'

parents = [1]; %start with root node

for i=1:depth
    children = [];
    for j = 1:size(parents,2)
        c1 = tr.ii(parents(j),2);  %first child
        c2 = c1 + 1;  %second child 
        children = [children, c1, c2];
    end
    parents = children;
    
end

major_groups = parents;

%define minor groups by descending say 2 or 3 levels further (need to
%consider encountering leaf nodes)
%collect all cameras of these minor groups
%retain minor-> major map

minor_depth = 4;
minor_groups = cell(n_groups,1);
minor_to_major.major = [];
minor_to_major.minor = [];
for i = 1:n_groups
  parents = major_groups(i);  %starting node - major_group id
  
  for j=1:minor_depth
    children = [];
    for k = 1:size(parents,2)
        c1 = tr.ii(parents(k),2);  %first child
        if c1 == 0  %leaf node
           children =[children, parents(k)]; %don't descend, reappend leaf node 
           continue;
        else
           c2 = c1 + 1;  %second child 
           children = [children, c1, c2]; %append new nodes
        end
    end
    parents = children;
    
  end
  minor_groups{i} = parents;
  minor_to_major.major = [minor_to_major.major i*ones(1,size(parents,2))];
  minor_to_major.minor = [minor_to_major.minor linspace(1,size(parents,2),size(parents,2))];
end

camGroups = {};      % major x minor cell array in which each cell holds array of camera indices corresponding to minor group
tic;
for i=1:n_groups
   parents = minor_groups{i};
   n_minor = size(parents,2);
   camGrp_minor = {};
   
   for j = 1:n_minor
    this_parent = parents(j);
    queue.data = this_parent;
    queue.head = 1;
    queue.tail = 2;
    
    camIDs = [];
    
    while(queue.head < queue.tail)
      nc = queue.data(queue.head); %current node
      queue.head =queue.head+1;
      
      if(tr.ii(nc,2) == 0)   %leaf node (no children); append cameras
        camIDs = [camIDs ; tr.ll{nc}];
      else %not a leaf node - append to queue for descent
        c1 = tr.ii(nc,2);  %first child node of binary tree;
        c2 = c1 + 1;      %second child node is always 1 below 
        cnodes = [c1 c2];
        queue.data = [queue.data, cnodes];
        queue.tail = queue.tail + 2;
      end
      
    end  %end while for queue processing
    camGroups{i,j} = camIDs;
   end %end loop on minor groups
   
end %end for on major groups
toc
fprintf(1,'done defining camera groups\n');

%% 2. determine vertices and faces relevant to each camera group
tic;
%create aabb tree on faces 
bl = V(F(:,1),:); %lower bound of aabb box - initialize to values of 1st vertex
bu = V(F(:,1),:); %upper bound of aabb box - initialize to values of 1st vertex

for i = 2:size(F,2)
    bl = min(bl, V(F(:,i),:));
    bu = max(bu, V(F(:,i),:));
end

tr_faces = maketree([bl, bu]);  % from D. Engwirda's aabb tree matlab library

Fsets = {}; 
visByCam_group = {};

%do this on minor groups
n_minor = size(camGroups,2);
for i=1:n_groups

    for j = 1:n_minor
      if(isempty(camGroups{i,j})) 
          continue; 
      end
      %determine which faces are potentially visible in the camera group
      this_Cam = Cam(camGroups{i,j});    
      [visByCam, ~, ~] = projectFacesToCams(this_Cam,pCamCalib, V,F, tr_faces,'Dist_Threshold',2.0);
      visByCam_group{i,j} = visByCam;
    
      Frel =[];
      for k = 1:size(visByCam,2)
         Frel = union(Frel,visByCam{k});
      end
      Fsets{i,j}= Frel;
    end  %end loop on n_minor
    
end  %end loop on n_groups
toc
fprintf(1,'done projecting faces into camera\n');
%% 3. determine face overlap between each camera group- DO ON MINOR GROUPS AND
% only consider edges between minor groups in other major groupsO

tot_minor = 0;
for i = 1:n_groups
    n_cur = size(minor_groups{i},2);
    tot_minor = tot_minor + n_cur;
end


edgeStrength = zeros(tot_minor,tot_minor);
sharedEdges = cell(tot_minor,tot_minor);
all_shared = [];



for i = 1:tot_minor
    i_mj = minor_to_major.major(i);  %outer loop indices
    i_mi = minor_to_major.minor(i);
    
    for j = i:tot_minor  %inner loop
        
        j_mj = minor_to_major.major(j);  %inner loop indices
        j_mi = minor_to_major.minor(j);
        
        if i_mj == j_mj
            continue;
        end
        shared = intersect(Fsets{i_mj,i_mi}, Fsets{j_mj, j_mi});
        n_shared = size(shared,1);
        edgeStrength(i,j) = n_shared;
        edgeStrength(j,i) = n_shared;
        sharedEdges{i,j}  = shared; %only store in one entry to conserve memory
        all_shared = union(all_shared,shared);
        
    end %end inner loop
    
end  %end outer loop



tic;
edge_rank = 1;
%% 4. exclusively allocate shared faces to minor camera groups using greedy approach
% loop on minor groups, when a minor group takes over faces from another group add that group's camera to the minor group
camGroups_aug = camGroups; %augmented camera groups resulting from face partitioning - start with original groups and then augment
while(~isempty(all_shared))
    for i = 1:tot_minor
       [~,ranked_idx] = sort(edgeStrength(i,:),'descend');  %find camGroup that this group shared 'edge_rank'th overlap with 
       merge_idx = ranked_idx(edge_rank);
       if(i<merge_idx)   %get those shared faces
           shared = sharedEdges{i,merge_idx};  
       else
           shared = sharedEdges{merge_idx,i};
       end
       
       %pull out major, minor indices of n_minor and merge_idx group
       o_mj = minor_to_major.major(i);  %new owner indices
       o_mi = minor_to_major.minor(i);
       s_mj = minor_to_major.major(merge_idx); %loser indices
       s_mi = minor_to_major.minor(merge_idx);
       
       [available,~,idx_as]  = intersect(shared,all_shared);  %determine which faces have not been allocated - i.e. still available for assignment
       
       if(~isempty(available))  %add cameras of camGroup to be merged to new owner's camGroup
           temp_s = camGroups_aug{s_mj, s_mi};  %extract cameras of loser
           temp_o = camGroups_aug{o_mj, o_mi};
           
           new_cams = unique([temp_o; temp_s]);
           
           camGroups_aug{o_mj, o_mi} = new_cams;  
       end
       
       for j = 1:n_groups   %remove faces from all other sets (effectively merging them into camGroup{i})
           if o_mj == j % if in the same major group do nothing
             continue; 
             
           else  % if in a different major group, remove 'available' faces 

             n_j = size(Fsets,2);
             for k = 1:n_j
                Fsets{j,k}  = setdiff(Fsets{j,k}, available);
             end
             
           end
       end  %and loop on major groups
 
       all_shared(idx_as) = [];
       
    end %end for loop on groups
    edge_rank = edge_rank + 1;
end  %end while loop on all_shared
toc
fprintf(1,'done withe exclusive allocation of faces\n');

%test exclusive allocation of faces
n_faces_alloc = 0;
n_cameras_aug = 0;
n_faces_by_group = 0;
for i = 1:n_groups
    F_grp_uni = [];
    for j = 1:n_minor
        n_faces_alloc = n_faces_alloc + size(Fsets{i,j},1);
        n_cameras_aug = n_cameras_aug + size(camGroups_aug{i,j},1);
        F_grp_uni = unique([F_grp_uni; Fsets{i,j}]);
    end
    n_faces_by_group = n_faces_by_group + size(F_grp_uni,1);
end
n_faces_alloc;
n_cameras_aug;
n_faces_by_group;



%% 5. Aggregate minor groups to major
Fsets_mj = [];
camGroups_mj = [];


for i=1:n_groups
    F_major = [];
    cam_major = [];
    for j=1:n_minor
        F_major = unique([F_major; Fsets{i,j}]);
        cam_major = unique([cam_major; camGroups_aug{i,j}]);
        
    end
    Fsets_mj{i} = F_major;
    camGroups_mj{i} = cam_major;

end
% 
% remap faces and vertices for split mesh sections

for i = 1:n_groups
    Fsub = F(Fsets_mj{i},:); 
    %remap vertex indices in faces
    Vidx = unique(Fsub(:));
    Vsub = V(Vidx,:);
    
    refInds = zeros(size(Vidx));
    for k = 1:length(Vidx)
        refInds(Vidx(k))= k;
    end
    
    Fsub = refInds(Fsub);
    CamSub = Cam(camGroups_mj{i}); 
    outfile = strcat('CameraGroup_',num2str(i),'.mat');
    save(outfile, 'CamSub','pCamCalib','Vsub','Fsub','-v7.3');
    
    Fsets_out{i} = Fsub;
    Vsets_out{i} = Vsub;
    
end


% 
%% plot results 
%  multiple plots
colors = {'r','g','b','c','m','y'};
for i = 1:n_groups
   figure(i);
   this_group = camGroups_mj{i};
   for j = 1:size(this_group,1)
       plotCircle3D(camPos(this_group(j),:),[0, 0, 1],0.1, colors{mod(i,size(colors,2))+1});
       hold on;
   end
   pcshow(Vsets_out{i},colors{mod(i,size(colors,2))+1});
   plot_box3d(tr.xx(major_groups(i),1:3), tr.xx(major_groups(i),4:6),colors{mod(i,size(colors,2))+1});
   trisurf(F, V(:,1), V(:,2), V(:,3));
   hold off;
end

% single plot - faces only

figure;

trisurf(F, V(:,1), V(:,2), V(:,3),'FaceColor',[0,0,0]);
hold on;
for i = 1:n_groups
    pcshow(Vsets_out{i},colors{mod(i,size(colors,2))+1});
end



end

