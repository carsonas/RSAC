###############################################################################################################################################################
#
#  Input parameters
#
###############################################################################################################################################################
#
workspace = "M:/Ethiopia_Mapping/Boise_Training/Data/CARSON/new_correct/167"

#random points in overlap areas (areas of intersection between images and not clouds in either image).
pointsshp = "M:/Ethiopia_Mapping/Boise_Training/Data/CARSON/new_correct/167/p167_randompoints.shp"

#Master
masterImage = "M:/Ethiopia_Mapping/Boise_Training/Data/CARSON/new_correct/p168_mosaic.img"

#Slave
slaveImage = "M:/Ethiopia_Mapping/Boise_Training/Data/CARSON/new_correct/167/p167_mosaic.img"

#Output Image
OutputModel = "M:/Ethiopia_Mapping/Boise_Training/Data/CARSON/new_correct/167/test_R_script4.img"

#Output Data type for Unsigned 16 bit: 'INT2U', for Unsigned 8 bit: 'INT1U', for Float: 'FLT4S', for more info on page 62: http://cran.r-project.org/web/packages/raster/raster.pdf
dataType = 'INT2U'

#ChunkSize - The chunksize of 2e+06 should work for most things, but if the script bombs on you, lower the value to something like 2e+05
ChunkSize = 3e+06

###############################################################################################################################################################

#install and get required packages
#install.packages("raster", repos='http://cran.us.r-project.org')
#install.packages("rgdal", repos='http://cran.us.r-project.org')
#install.packages("tools", repos='http://cran.us.r-project.org')

library(raster)
rasterOptions(chunksize = ChunkSize)
library(tools)
library(rgdal)

#set working directory
setwd(workspace)


######################################################################################
#
#  read in rasters and shapefile
#
######################################################################################
master = stack(masterImage)
slave = stack(slaveImage)

#read in points
points = shapefile(pointsshp)
rm(pointsshp)
######################################################################################
#
# extract points for response variable
#
######################################################################################

print("Extracting Point Values")
pointvalues = extract(master, points)
pointvalues2 = extract(slave, points)

modelDF = as.data.frame(cbind(pointvalues,pointvalues2))
colN = colnames(modelDF)
######################################################################################
#
# Loop through each band and predict
#
######################################################################################
numBands = dim(modelDF)[2]/2
rasterOuts = c()
for(i in 1:numBands)
	{
	
	######################################################################################
	#
	# create linear model model
	#
	######################################################################################
	
	print("Creating Linear Model")
	#Create formula String
	dependent = i + numBands
	formulaString = paste(colN[i],"~",colN[dependent],sep="")
	print(formulaString)
	LM_Model = lm(formulaString,data = modelDF)

	######################################################################################
	#
	# create predict raster
	#
	######################################################################################

	print(paste("Predicting Band: ",as.character(i),sep=""))
	outBandName = paste(substr(OutputModel,0,nchar(OutputModel)-4),"_band",as.character(i),".img",sep="")
	rasterOuts = c(rasterOuts,outBandName)
	outputrast = predict(slave, LM_Model, filename = outBandName, type='response',progress = "text", datatype = dataType, inf.rm = TRUE)
	}

#Write final stacked raster
writeRaster(stack(rasterOuts),OutputModel)



