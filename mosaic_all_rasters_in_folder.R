library(raster)

#folder that contains all of your images to mosaic, make sure there are no other images in there though.
workspace = "M:/Dixie/Data/Imagery/NAIP_2014/quarterquads"

#output image
outname = "DX_NAIP2014_z12.img"


setwd(workspace)

imageList = list.files(path = ".", pattern = "\\.img$")
mosaicList = c()


for(i in 1:length(imageList))
	{
	rast = stack(imageList[i])
	mosaicList = append(mosaicList,rast)
	}

#Use either mosaic or merge below, probably use merge though (the uncommented one).

#use this for most imagery.  It is slower, but takes care of NA values.
#you may want to change the function type to mean
#do.call(mosaic, c(mosaicList, fun = max, filename = outname))


#this is faster, but only do it if your images have no overlapping NAs.
do.call(merge, c(mosaicList, overlap = TRUE, filename = outname))