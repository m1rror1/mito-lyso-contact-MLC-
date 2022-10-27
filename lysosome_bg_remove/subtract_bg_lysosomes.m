% file name or path
fluorPath = 'tif_name.tif';

% kernel size = CircleFiltSize * 2 + 1
minCircleFiltSize = 2;
maxCircleFiltSize = 20;

info = imfinfo(fluorPath);
[m, n] = size(info);
fluorImg = zeros(info(1).Height,info(1).Width, m);
[nx,ny,nz] = size(fluorImg);
for i = 1:nz
    fluorImg(:, :, i) = read_tiff(fluorPath,i);
end

% diffuse background remove
[ImBgRemoved,ImMinMed,ImMedFiltered] = diffuseBgRemove(fluorImg,minCircleFiltSize,maxCircleFiltSize);

% save images
for i = 1:nz
    imwrite(uint16(ImBgRemoved(:, :, i)), 'save_tif_path.tif','tif','Compression','none', 'WriteMode', 'append');
end

for i = 1:nz
img = ImBgRemoved(:, :, i);

[y_out, x] = imhist(img, 65536);
y_out_sum = sum(y_out);
y_out_remove = y_out_sum*0.98;
id = find_idx(y_out, y_out_remove);
if id > 1200
    id = 1200;
end

img_remove = img;
img_remove(img_remove<id) = 0;

se=strel('disk',2);
img_close = imclose(img_remove, se);
mask = img_close;
mask(mask>0) = 255;
mask = logical(mask);
% remove small area--noise or error signal
mask1 = bwareaopen(mask, 20);
img_close(mask1==0) = 0;
img_close = double(img_close);
adj_img = uint8(img_close/max(max(img_close))*255);
% enhance contrast
adj_img = imadjust(adj_img, [], [], 0.35);
% save final label
imwrite(uint8(adj_img), 'save_final_bg_remove_path.tif','tif','Compression','none');
end

function g = find_idx(y, n)
    i = 1;
    while n > 0
        n = n - y(i, 1);
        i = i + 1;
    end
    g = i;
end
