##################################################################################################
#Libraries
##################################################################################################
library(raster)
library(rgdal)
library(SDMTools)

##################################################################################################
#Input Variables
##################################################################################################
workspace = "M:/Medicine_Bow/Stage2/Mapping/Heterogenous"
forestSHPname = "MBR_fragstats_poly.shp"
forestRastname = "mbr_change_detection.img"
outName = "MBR_fragstats.csv"

changeRastMin = 1
changeRastMax = 2

##################################################################################################
#Read in spatial data
##################################################################################################
setwd(workspace)
#read in shapefile
forestSHP = shapefile(forestSHPname)

#read in Raster
forestRast = raster(forestRastname)

##################################################################################################
#Iterate through each polygon
##################################################################################################
FIDlist = as.vector(forestSHP$SPATIAL_ID)

#set up empty object for dataframe
outData = 0

time1 = proc.time()
for(i in FIDlist)
	{
	print(i)
	tempPoly = forestSHP[forestSHP$SPATIAL_ID == i,]
	tempCrop = crop(forestRast,tempPoly)
	tempRaster = mask(tempCrop,tempPoly)
	# Make sure there change patches
	if(!is.na(minValue(tempRaster)))
	{
		if(minValue(tempRaster) == changeRastMin & maxValue(tempRaster) == changeRastMax)
		{
			#print(tempRaster)
			#image(tempRaster, col=c('blue','red'))
			## Run fragstats and extract stats of interest
			#calculate the class statistics
			cl.data = ClassStat(tempRaster)
			#print(cl.data)
			stats = as.data.frame(append(cl.data[1,], cl.data[2,]))
			stats =as.data.frame(append(i, stats))
			names(stats)[1] = 'SpatialID'
			#print(stats)
			#Create output file
			if(outData ==0)
				{
				outData = stats
			}else{
				outData = rbind(outData,stats)
			}
		}
	}
	}
proc.time() - time1
write.csv(outData,outName)
