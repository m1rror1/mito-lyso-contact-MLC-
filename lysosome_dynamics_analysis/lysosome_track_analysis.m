clc; clear; close all;

% um
micronPerPixel = 0.0542;

cell_boder = imread('cell_borders.png');
cell_boder = logical(cell_boder);

%% get lyso track edge info
% csv file obtain from trackmate
track_table = xlsread('tracks.csv');
% if track length > 50
confident_track = find(track_table(:, 3) > 50)-1;

spot_table = xlsread('spots.csv');
% 2id 4x 5y 6z 7t 8frame 
spot_filter_table = zeros(size(spot_table, 1), 4);
spot_filter_table(:, 1) = spot_table(:, 2);
spot_filter_table(:, 2) = round(spot_table(:, 4)/micronPerPixel)+1;
spot_filter_table(:, 3) = round(spot_table(:, 5)/micronPerPixel)+1;
spot_filter_table(:, 4) = spot_table(:, 8)+1;

track_num = length(unique(spot_filter_table(:, 1)));
track_length = zeros(1, track_num);

track_list = cell(1, size(confident_track, 1));
tracklist = cell(size(confident_track, 1), 1);

for i = 1:length(confident_track)
    track_list{i} = spot_filter_table(spot_filter_table(:, 1) == confident_track(i), :);    
    track_list{i} = sortrows(track_list{i}, 4);
    
    tracklist{i} = [spot_table(spot_table(:, 2) == confident_track(i), 7), spot_table(spot_table(:, 2) == confident_track(i), 4), spot_table(spot_table(:, 2) == confident_track(i), 5)];
    tracklist{i} = sortrows(tracklist{i}, 1);
    
    x = tracklist{i}(:,2);
    y = tracklist{i}(:,3);
    if cell_boder(round(y(1)/0.0542)+1, round(x(1)/0.0542)+1)~=1
        tracklist{i} = [];
    end
end
tracklist(cellfun(@isempty,tracklist))=[];

% tracklist_tmp = cell(10, 1);
% for iit = 1:10
%     idx = randi(length(tracklist));
%     tracklist_tmp{iit} = tracklist{idx};
% end

%% MSD
dimension=2;
spaceUnits='um';
timeUnits='s';
timeinterval=0.1;
ma = msdanalyzer(dimension, spaceUnits, timeUnits);
ma = ma.addAll(tracklist);

figure
ma.plotTracks;
ma.labelPlotTracks;
axis tight
axis ij

% compute and plot MSDs
ma = ma.computeMSD;
figure
ma.plotMSD;
axis tight
