function thresh_img = area_threshold(img,minArea,maxArea)
    %Get areas of each component for thresholding
    thresh_img = zeros(size(img),class(img));

    for frameNum = 1:size(img,3)
        CCPreThresh = bwconncomp(img(:,:,frameNum));
        statsPreThresh = regionprops(CCPreThresh,'Area');

        %Get components above the area threshold
        keptComponents = find([statsPreThresh.Area]>minArea & [statsPreThresh.Area]<maxArea);

        %Make a new image with only components above threshold
        thresh_img(:,:,frameNum) = ismember(labelmatrix(CCPreThresh),keptComponents);
    end
end