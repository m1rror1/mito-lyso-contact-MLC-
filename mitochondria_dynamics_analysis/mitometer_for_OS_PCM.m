clc; clear all; close all;

addpath(strcat(pwd,'/code'));

% load prediction_1s_30min_1.mat
%% initialization
% um
micronPerPixel = 0.0542;
% time interval:s
secondsPerFrame = 1;
% mitochondrial area limits
minArea = 0.3;
maxArea = 200;
% track dist thresh: um
distThreshMicrons = 1;
fision_fusion = 0;

% read tif stack file---method1
[importedImage,numFrames,tif_name,tif_path] = openTifs();
ImAll = importedImage{1};
clear importedImage

% % read tif images---method2
% namelist = dir('.\*.tif');
% len = length(namelist);
% len = 600;
% file_name = cell(1, len);
% ImAll = uint8(zeros(2048, 2048, len));
% for i = 1:len
%     file_name{i}=[namelist(i).folder, '\', namelist(i).name];
%     ImAll(:, :, i) = read_tiff(file_name{i}, 1);
% end

%% segmentation
[ImBgRemoved,ImMinMed,ImMedFiltered] = diffuseBgRemove(ImAll,(minArea)/micronPerPixel,(1)/micronPerPixel);
clear ImMinMed ImMedFiltered
[sig, thr, costs] = optimizeSigmaThresh(ImBgRemoved);
clear costs
ImGaussFiltered = gaussFilter(ImBgRemoved,sig);
ImMask = thresholdImage(ImGaussFiltered, thr);

ImMaskThresholded = areaThreshold(ImMask,minArea/(micronPerPixel^2),maxArea/(micronPerPixel^2));
Im = ImMaskThresholded.*ImAll;

clear ImMask ImMaskThresholded ImGaussFiltered ImBgRemoved

% save
for i = 1:size(ImAll, 3)
    imwrite(Im(:,:,i), [tif_path, 'segmentation.tif'], 'tif', 'WriteMode', 'append', 'Compression', 'none');
end

useframeThreshSeconds = size(ImAll,3);

%% tracking
weightsPrelim = ones(1,6)*1/6;
trackPrelim = trackMitochondria(Im,ImAll,weightsPrelim,micronPerPixel,secondsPerFrame,distThreshMicrons,useframeThreshSeconds,0,1);

[weights,~] = getTrackingWeights(trackPrelim);
if sum(isnan(weights))
    weights = weightsPrelim;
end

clear trackPrelim weightsPrelim

if ~fision_fusion
    [track,mitoCoM,extra] = trackMitochondria(Im,ImAll,weights(1:6),micronPerPixel,secondsPerFrame,distThreshMicrons,useframeThreshSeconds);
else
    [track,mitoCoM,extra] = trackMitochondria(Im,ImAll,weights(1:6),micronPerPixel,secondsPerFrame,distThreshMicrons,useframeThreshSeconds,0,1);
end
clear extra mitoCoM

% painting
[trackList,noTracksFound] = trackLengthThreshold(track,1);

figure;
h = imshow(255-ImAll(:,:,1));
hold on;

trackType = 1;
for i = 1:length(trackList)
    plotWeightedCentroidApp(trackList(i))
    if ~trackType
        plotFissionEventsApp(trackList,i);
        plotFusionEventsApp(trackList,i);
    end
end

fission_num = 0;
fusion_num = 0;
for i = 1:length(trackList)
    flag_fi = plotFissionEventsApp(trackList,i);
    flag_fu = plotFusionEventsApp(trackList,i);
    fission_num = fission_num + flag_fi;
    fusion_num = fusion_num + flag_fu;
end
fission_rate = fission_num/length(trackList);
fusion_rate = fusion_num/length(trackList);

%% analysis
oneFileDynamics = getDynamics(micronPerPixel,secondsPerFrame,trackList);

for i = 1:length(oneFileDynamics.speed)
    holdBoth(i).speed = oneFileDynamics.speed{i};
    holdBoth(i).distance = oneFileDynamics.distance{i};
    holdBoth(i).displacement = oneFileDynamics.displacement{i};
    holdBoth(i).velocity = oneFileDynamics.velocity{i};
end

for i = 1:length(trackList)
    medianVals(i).Area = nanmedian(trackList(i).Area);
    medianVals(i).Perimeter = nanmedian(trackList(i).Perimeter);
    medianVals(i).zAxisLength = 0;

    medianVals(i).MajorAxisLength = nanmedian(trackList(i).MajorAxisLength);
    medianVals(i).MinorAxisLength = nanmedian(trackList(i).MinorAxisLength);
    medianVals(i).Solidity = nanmedian(trackList(i).Solidity);
    medianVals(i).MeanIntensity = nanmedian(trackList(i).MeanIntensity);
    medianVals(i).fission = nnz([trackList.fission])/length(trackList);
    medianVals(i).fusion = nnz([trackList.fusion])/length(trackList);
    medianVals(i).speed = nanmedian(holdBoth(i).speed);
    medianVals(i).distance = nanmedian(holdBoth(i).distance);
    medianVals(i).displacement = nanmedian(holdBoth(i).displacement);
    medianVals(i).velocity = nanmedian(holdBoth(i).velocity);
end

trackList = rmfield(trackList,'Extrema');
trackList = rmfield(trackList,'PixelIdxList');
trackList = rmfield(trackList,'MaxFeretDiameter');
trackList = rmfield(trackList,'MaxFeretAngle');
trackList = rmfield(trackList,'MaxFeretCoordinates');
trackList = rmfield(trackList,'NN');
trackList = rmfield(trackList,'NNExtrema');
trackList = rmfield(trackList,'NPA');
trackList = rmfield(trackList,'label');

%% display
fig2 = uifigure;
HistFig = uiaxes(fig2);
h = histogram(HistFig,[medianVals.Perimeter],round(length(trackList)/2),'Normalization','probability');
HistFig.YLim = [0,max(h.Values)];
HistFig.XLim = [min(h.BinEdges),max(h.BinEdges)];
ylabel(HistFig, 'Frequency');
