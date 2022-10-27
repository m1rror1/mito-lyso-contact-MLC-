function [sigmaOptimal,threshOptimal,costs] = optimizeSigmaThresh(ImBgRemoved,minArea,maxArea)
%

numFrames = min(size(ImBgRemoved,3),5);

%We use Otsu’s thresholding and verify its effectiveness metric to
%determine whether it is satisfactory (>80% effective) to use rather than
%iterating through intensity values. If it is not satisfactory (<80%
%effective) we calculate the entire stack’s 80th quantile of intensity and
%use that as the upper limit for thresholding.
%我们使用Otsu的阈值，并验证其有效性度量，以确定它是否令人满意(>80%的有效性)
%来使用，而不是通过强度值迭代。如果它不令人满意(<80%有效)，
%我们计算整个堆栈的强度的第80个分位数，并将其作为阈值的上限。
[t,em] = graythresh(uint8(ImBgRemoved));
if em > 0.8 && round(t*max(ImBgRemoved(:))) ~= 0
    intensityQuantile = round(t*max(ImBgRemoved(:)));
    threshMatrix = intensityQuantile;
else
    intensityQuantile = quantile(ImBgRemoved(ImBgRemoved~=0),0.8);
    threshMatrix = (2:1:intensityQuantile);
end

%We also limit the gaussian filter’s standard deviation between 0.33 and
%0.5. We choose these values as we want to keep the gaussian filter’s size
%to a 3x3 kernel. We choose a minimum standard deviation of greater than
%0.32 as it has a center value of 0.97 and edge values of 0.0074,
%essentially making it and anything below it useless as a filter. We choose
%a maximum standard deviation of 0.5 as, in general, the rule of thumb is
%to limit the filter size to 3 times the standard deviation on either side
%of the center (making it 6*0.5 for a size of 3). This is because the tails
%of the Gaussian have values that are effectively 0 after three standard
%deviations, and anything greater than 0.5 with a filter size of 3 produces
%a non-Gaussian filter.
%我们也限制了高斯滤波器的标准偏差在0.33和0.5之间。我们选择这些值是因为我们希望
%高斯滤波器的大小保持在3x3核。我们选择的最小标准差大于0.32，因为它的中心值
%为0.97，边缘值为0.0074，本质上使得它和任何低于它的东西都不能作为过滤器。我们
%选择最大标准差为0.5,总体而言,经验法则是过滤器的大小限制为3倍标准差中心的两侧
%(使其6 * 0.5的尺寸3)。这是因为反面的高斯值有效0三个标准差后,任何大于0.5且滤波器
%大小为3的东西都会产生非高斯滤波器。
sigmaMatrix = (0.33:0.01:0.5);


numComponents = zeros([length(threshMatrix),length(sigmaMatrix),numFrames]);
medianArea = zeros([length(threshMatrix),length(sigmaMatrix),numFrames]);

loading = waitbar(0,'Please wait...','CreateCancelBtn','setappdata(gcbf,''canceling'',1)');
setappdata(loading,'canceling',0);
pause(.0002)


for sigma = 1:length(sigmaMatrix)
    ImGaussFiltered = gaussFilter(ImBgRemoved,sigmaMatrix(sigma));
    for thresh = 1:length(threshMatrix)
        
        %
        if getappdata(loading,'canceling')
            delete(loading)
            break
        end
        waitbar((thresh+length(threshMatrix)*(sigma-1))/(length(sigmaMatrix)*length(threshMatrix)),loading,sprintf('Testing parameter %d of %d.',(thresh+length(threshMatrix)*(sigma-1)),(length(sigmaMatrix)*length(threshMatrix))));
        pause(.0002)
        %
        
        %         [~,ImMask] =
        %         segmentObjects(Im,ImBgRemoved,ImGaussFiltered,threshMatrix(thresh));
        ImMask = thresholdImage(ImGaussFiltered,threshMatrix(thresh));
        
        %We then iterate through the first 10 timeframes (or all frames if
        %the total number of timeframes is less than 10) for each standard
        %deviation and intensity value.
        for frameNum = 1:numFrames
            %返回连通分量
            CCPreThresh = bwconncomp(ImMask(:,:,frameNum));
            %返回每个连通的面积
            statsPreThresh = regionprops(CCPreThresh,'Area');
            %We calculate the number of mitochondria and the median area of
            %all mitochondria that are within the area threshold in each
            %temporal frame.
            if nargin > 1
                keptComponents = find([statsPreThresh.Area]>minArea & [statsPreThresh.Area]<maxArea);
                numComponents(thresh,sigma,frameNum) = length(keptComponents);
                medianArea(thresh,sigma,frameNum) = nanmedian([statsPreThresh(keptComponents).Area]);
            else
                keptComponents = find([statsPreThresh.Area]>1);
                numComponents(thresh,sigma,frameNum) = length(keptComponents);
                medianArea(thresh,sigma,frameNum) = nanmedian([statsPreThresh(keptComponents).Area]);
            end
        end
    end
end
%We calculate the standard deviation of the median area of the mitochondria
%and the mean and standard deviation of the number of mitochondria across
%all temporal stacks for each Gaussian sigma and absolute threshold value.
%我们计算线粒体中值面积的标准差和每个高斯标准差和绝对阈值在所有时间堆栈中线粒体
%数量的平均值和标准差。
meanArea = nanmean(medianArea,3);
stdNum = nanstd(numComponents,[],3);
stdArea = nanstd(medianArea,[],3);
stdArea(isnan(stdArea)) = nanmean(stdArea(:));
meanNum = nanmean(numComponents,3);

%We take the z-score of each of these mitochondrial parameters to build up
%our cost matrix.
%我们取每一个线粒体参数的z分数来建立我们的成本矩阵。
normStdArea = zscore(stdArea,0,'all');
normStdNum = zscore(stdNum,0,'all');
normMeanNum = zscore(meanNum,0,'all');

% normStdArea(meanArea<minArea) = 1e4; normStdArea(meanArea>maxArea) = 1e4;

%To ensure choosing a stable value, we run the cost matrix through a
%symmetric 3x3 median filter, which acts to remove any outlying regions.
costMatrix = medfilt2(normStdArea + normStdNum - 0.5*normMeanNum,'symmetric');
costMatrix(costMatrix==0) = 1e4;

%We then select the minimum value of this cost matrix to set our sigma and
%threshold values.
minVal = min(costMatrix,[],'all');

[rowMin,colMin] = find(costMatrix == minVal);

threshOptimal = threshMatrix(floor(median(rowMin)));
sigmaOptimal = sigmaMatrix(floor(median(colMin)));

costs.stdArea = stdArea;
costs.stdNum = stdNum;
costs.meanNum = meanNum;
costs.normStdArea = normStdArea;
costs.normStdNum = normStdNum;
costs.normMeanNum = normMeanNum;
costs.costMatrix = costMatrix;
costs.numComponents = numComponents;
costs.medianArea = medianArea;
costs.rowMin = rowMin;
costs.colMin = colMin;


% figure imagesc(costMatrix) axis image colormap hot hold on
% scatter(colMin,rowMin,'r') figure imagesc(normStdArea) axis image
% colormap hot hold on scatter(colMin,rowMin,'r') figure
% imagesc(normStdNum) axis image colormap hot hold on
% scatter(colMin,rowMin,'r') figure imagesc(-normMeanNum) axis image
% colormap hot hold on scatter(colMin,rowMin,'r')

delete(loading)

end
