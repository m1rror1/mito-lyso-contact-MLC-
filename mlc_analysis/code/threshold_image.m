function im_mask = threshold_image(img,thr)
    im_mask = zeros(size(img),class(img));
    im_mask(img>thr) = 1;
    im_mask(img<=thr) = 0;
end