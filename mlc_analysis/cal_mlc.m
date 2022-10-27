clc; clear all; close all;

addpath('./code');
%% get cell borders
cell = imread('cell_borders.png');
se = strel('disk', 2);
celldilate = imdilate(cell, se);
cellerode = imerode(cell, se);
cell_borders = cell - cellerode;
cell = logical(cell);
% figure;
% imagesc(cell); title('cell label');

%% get lyso position
csv_table = xlsread('spots.csv');
micronPerPixel = 0.0542;
csv_filter_table = zeros(size(csv_table, 1), 3);
csv_filter_table(:, 1) = csv_table(:, 8)+1;
csv_filter_table(:, 2) = round(csv_table(:, 4)/micronPerPixel)+1;
csv_filter_table(:, 3) = round(csv_table(:, 5)/micronPerPixel)+1;
FRAME = length(unique(csv_filter_table(:, 1)));
clear csv_table

%% initialization
lyso_num = zeros(FRAME, 1);
mlc_count = zeros(FRAME, 1);
mlc_rate = zeros(FRAME, 1);
minArea = 0.3;
maxArea = 200;
lyso_wid = round(0.6/micronPerPixel);
for N = 1:1:FRAME
    rank = get_file_name_rank(N-1);
    lyso_img = read_tiff('lyso_prediction.tif', 1);
    mito_img = read_tiff('mito_prediction.tif', 1);
    
    [lyso, lyso_cell_num] = get_lyso_num_pos(csv_filter_table, cell, N);
    lyso_num(N) = lyso_cell_num;
    lyso_cell = lyso & cell;
    % lysosome position in cell
    [cenx, ceny] = find(lyso_cell==1);
    
    % lysosome binary mask
    lyso_bw = uint8(zeros(size(cell)));
    for ii = 1:length(ceny)
        x1 = cenx(ii) + lyso_wid * cos(0:2*pi/360:2*pi);
        y1 = ceny(ii) + lyso_wid * sin(0:2*pi/360:2*pi);
        for j = 1:length(x1)
            if x1(j)<1
                x1(j) = 1;
            end
            if y1(j)<1
                y1(j) = 1;
            end
            if x1(j)>size(cell, 1)
                x1(j) = size(cell, 1);
            end
            if y1(j)>size(cell, 2)
                y1(j) = size(cell, 2);
            end
            lyso_bw(round(x1(j)), round(y1(j))) = 1;
        end
    end
    lyso_bw = imfill(lyso_bw, 'holes');
    
    % mitochondria binary mask
    ImMask = threshold_image(mito_img, max(max(mito_img))*0.4);
    ImMaskThresholded = area_threshold(ImMask,minArea/(micronPerPixel^2),maxArea/(micronPerPixel^2));
    mito_bw = uint8(ImMaskThresholded);
    
    % binary mask * image -> true mask
    lyso_merge = lyso_img.*lyso_bw;
    lyso_matrix = threshold_image(lyso_merge, max(max(lyso_merge))*0.05);
    lyso_matrix = area_threshold(lyso_matrix,10,10000);
    lyso_matrix = lyso_matrix & cell;
    
    mito_merge = mito_img.*mito_bw;
    mito_matrix = threshold_image(mito_merge, max(max(mito_merge))*0.1);
    mito_matrix = mito_matrix & cell;
    
    merge_matrix = zeros(size(cell, 1), size(cell, 2), 3);
    merge_matrix(:, :, 1) = lyso_matrix * 255;
    merge_matrix(:, :, 2) = mito_matrix * 255;
    merge_matrix(:, :, 3) = cell_borders * 255;
    figure;
    imshow(merge_matrix);

    overlap_matrix = mito_matrix .* lyso_matrix;
    CC = bwconncomp(overlap_matrix);
    mlc_count(N) = CC.NumObjects;
    mlc_rate(N) = mlc_count(N)/lyso_cell_num;
    disp('===================================================================')
    disp('===================================================================')
    disp(['Frame ', num2str(N), '...'])
    disp(['Found ', num2str(lyso_cell_num), ' lysosomes...'])
    disp('Found mitochondria...')
    disp(['Found ', num2str(mlc_count(N)), ' mito_lyso_contacts...'])
    disp(['Mito_lyso_contacts rate: ', num2str(mlc_rate(N))])
end

save('mlc.mat', 'lyso_num', 'mlc_count', 'mlc_rate', '-v7.3')