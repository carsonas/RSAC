library(raster)

#set Working Directory
setwd("M:/Rio_Grande/Mapping/Change_Detection")

#Raster to rescale and then resample
rast1name = "rio_grande_2013_1999_ndvi_difference_plus255_clipped_NAD83.img"
rast1 = stack(rast1name)

#Get the number of bands in the raster
numLayers = nlayers(rast1)
#numLayers = 1

#loop through each band and perform rescale and resample
for(i in 1:numLayers)
	{
	print(i)
	tempRast = subset(rast1,subset = i)
	maxV = maxValue(tempRast)
	minV = minValue(tempRast)
	print(maxV)
	print(minV)
	
	#rescale
	if(minV<0){
		tempRast = tempRast + abs(minV)
		tempRast = abs(tempRast)
		maxV = maxValue(tempRast)
		minV = minValue(tempRast)
		print("new")
		print(maxV)
		print(minV)
	}
	tempRescaled = ((tempRast - minV)*65533)/(maxV - minV)
	rm(tempRast)
	
	#Resample and write out
	outname = paste(substr(rast1name,0,nchar(rast1name)-4),"_band_",i,".img",sep="")
	tempDisag = disaggregate(tempRescaled, fact = 3)
	rm(tempRescaled)
	writeRaster(tempDisag, outname, datatype = 'INT2U')
	rm(tempDisag)
	}













