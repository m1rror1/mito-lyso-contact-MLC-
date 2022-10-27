function RAW = read_tiff(Tiffdata,it)
fname = Tiffdata;
info = imfinfo(fname);
RAW = imread(fname, it, 'Info', info);
end