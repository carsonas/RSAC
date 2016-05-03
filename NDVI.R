setwd("M:/Manti_La_Sal/Data/Imagery/NAIP/For_Segmentation/Stam_R_Mosaic_Test/test")
library(raster)
outname = "ndvi_image.img"
inname = "tempcomposite_115.img"


b3<-raster(inname,3) #band 3 of first input image
b4<-raster(inname,4) #band 4 of first input image
ndvi1<-(b4-b3)/(b4+b3) #calculating NDVI for first image

writeRaster(ndvi1, outname, datatype = 'FLT4S')