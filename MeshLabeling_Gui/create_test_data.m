%create a test annotation dataset to assess accuarcy of annotators
addpath(genpath('/home/cv-bhlab/Documents/MATLAB/3D_Reconstruction/'));

ann_file = './0443/0443_02122016_annotations_all.txt';
gui_infile = '0443_all_infile.txt';
mesh_id = '0443';
patch_dir = strcat('./',mesh_id,'/data/patches/');

data = [];
data = load_mesh_data(data, gui_infile);

org_to_seen_map = zeros(size(data.F,1),1);
for i = 1:size(data.seenIdx,1)
    org_to_seen_map(data.seenIdx(i)) = i;
end


fid = fopen(ann_file,'r');
C = textscan(fid,'%d\t%d\t%f\t%f\t%d\n');
anns.face_id = C{1,1};
anns.label   = C{1,2};
anns.x       = C{1,3};
anns.y       = C{1,4};
anns.img     = C{1,5};

n_anns = size(anns.face_id,1);

test_data = {};

for i = 1:n_anns
    idx_seen = org_to_seen_map(anns.face_id(i));
    img_nums = find(data.imgCoordseen_x(idx_seen,:));
    x = full(data.imgCoordseen_x(idx_seen,:));
    x = x(x~=0);
    y = full(data.imgCoordseen_y(idx_seen,:));
    y = y(y~=0);
    
    n_views = size(img_nums,2);
    MAX_VIEWS = 6;
    if n_views > MAX_VIEWS
        draw = rand(1,n_views);
        [ranked, idx_rank] = sort(draw);
        img_nums = img_nums(idx_rank(1:MAX_VIEWS));
        x = x(idx_rank(1:MAX_VIEWS));
        y = y(idx_rank(1:MAX_VIEWS));
    end
    
    
    [patches, pts] = extract_patches(img_nums,data.imgFilePath, data.imgFiles,x,y);
    
    patch_files = {};
    n_patches = size(patches,2);
    for j = 1:n_patches
        this_pfile = strcat(patch_dir,mesh_id,'_',num2str(anns.face_id(i)),'_',num2str(j),'.jpg');  %patch file name
        this_patch = patches{j};
        this_patch= insertShape(this_patch, 'Circle', [pts(j,:) 5],'LineWidth',3);  %format for location (3rd argument) is [x, y, radius]
        imwrite(this_patch,this_pfile);
        patch_files{j} = this_pfile;
    end
    
    
    test_data{i} = { anns.face_id(i), anns.label(i), strcat('./',mesh_id,'/',data.imgFiles{anns.img(i)}), [anns.x(i) anns.y(i)], patch_files };
    
    
end
outfile = strcat(mesh_id,'_test_data.mat');
save(outfile,'test_data');

