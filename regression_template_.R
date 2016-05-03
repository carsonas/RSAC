###############################################################################################################################################################
#
#  Input parameters (This is how they should look)
#
###############################################################################################################################################################
#
#workspace = "I:/Ethiopia/Change_Detection"
#pointsshp = "I:/Ethiopia/Change_Detection/test_points"
#classfield = "change"
#predicttype = "Thematic"
#imageList = c("I:/Ethiopia/Change_Detection/Guji/l8_20130127_guji_stack_7band.img","I:/Ethiopia/Change_Detection/Guji/guji_l5tm_feb_1987_mosaic_clipped.img","I:/Ethiopia/Change_Detection/Guji/guji_1987_2014_difference.img")
#thematicimagelist = c("I:/Ethiopia/Change_Detection/Guji/l8_20130127_guji_stack_7band.img")
#outfile = "I:/Ethiopia/Change_Detection/change_test.img"
#
###############################################################################################################################################################

#install and get required packages
install.packages("raster", repos='http://cran.us.r-project.org')
install.packages("rgdal", repos='http://cran.us.r-project.org')
install.packages("tools", repos='http://cran.us.r-project.org')

library(raster)

library(tools)
library(rgdal)

#set working directory
setwd(workspace)

#read in points
points = shapefile(pointsshp)

rm(pointsshp)
gc()
rasterOptions(chunksize = 2e+06)
######################################################################################
#
#  create stacklist
#
######################################################################################

stacklist = c()

#read each raster from imageList as stack
print("Stacking Rasters")
if (length(imageList) > 0)
{
	for(i in 1:length(imageList))
	{
		rast = stack(imageList[i])
		stacklist = append(stacklist,rast)
		rm(rast)
	}
}

if (length(thematicimagelist) > 0 & thematicimagelist[1] != "")
{
	for(i in 1:length(thematicimagelist))
	{
		rast = stack(thematicimagelist[i])
		stacklist = append(stacklist,rast)
		rm(rast)
	}
}

print(stacklist)

#stack all the rasters
ourStack = stack(stacklist)

rm(stacklist)
gc()

######################################################################################
#
# extract points
#
######################################################################################

print("Extracting Point Values")
pointvalues = extract(ourStack, points)
pointsDF = as.data.frame(points)

rm(points)
gc()

######################################################################################
#
# get class field
#
######################################################################################

classindex = which(colnames(pointsDF)==classfield)

rm(classfield)
gc()

######################################################################################
#
#  Recode the thematic values
#
######################################################################################

legend = ""
emptyvec = c()

if(predicttype=="Thematic")
{
	classnames = as.factor(pointsDF[,classindex])
	numvec = seq(1,length(levels(classnames)),1)
	legend = as.data.frame(cbind(numvec,levels(classnames)))
	
	#loop through and change values in pointsDF
	for(i in 1:dim(pointsDF)[1])
	{
		newvalue = as.numeric(as.character(legend[which(legend[,2]==pointsDF[i,classindex]),][1]))
		emptyvec = append(emptyvec,newvalue)
	}
	
	colnames(legend) = c("NumValue","TextValue")
	
	rm(newvalue)
	rm(numvec)
	rm(classnames)
	gc()

}
	
######################################################################################
#
# create modeldataset
#
######################################################################################

print("Creating Model Dataset")

if(predicttype=="Thematic"){
	ModelDataset = as.data.frame(cbind(emptyvec, pointvalues))
}else{
	ModelDataset = as.data.frame(cbind(pointsDF[,classindex], pointvalues))
}

#if it should be a thematic output, then force "class" field to a factor
if(predicttype=="Thematic")
{
	ModelDataset[,1] = as.factor(ModelDataset[,1])
}

rm(emptyvec)	
rm(classindex)
rm(pointvalues)
rm(pointsDF)
gc()

######################################################################################
#  
#  set data type for the rasters
#
######################################################################################

#set continuous rasters to numeric
if (length(imageList)>0)
{
	print("Setting Rasters to continuous")
	for( i in 1:length(imageList))
	{
		ImageName = basename(file_path_sans_ext(imageList[i]))
		for(j in 1:dim(ModelDataset)[2])
		{
			columnname = unlist(strsplit(basename(colnames(ModelDataset)[j]),split = "\\."))[1] 
			
			if(ImageName == columnname)
			{
				ModelDataset[,j] = as.numeric(ModelDataset[,j])	
				print("Changed following column to numeric:")
				print(colnames(ModelDataset)[j])
				print(is.numeric(ModelDataset[,j]))
			}
		}
		rm(columnname)
		rm(ImageName)
		gc()
	}
}

#set thematic rasters to factor	
if(length(thematicimagelist)>0)
{
	print("Setting Rasters to factor")
	for( i in 1:length(thematicimagelist))
	{
		ImageName = basename(file_path_sans_ext(thematicimagelist[i]))
		for(j in 1:dim(ModelDataset)[2])
		{	
			columnname = basename(colnames(ModelDataset)[j])
			if(ImageName == columnname)
			{
				ModelDataset[,j] = as.factor(ModelDataset[,j])	
				print("Changed following column to factor:")
				print(colnames(ModelDataset)[j])
				print(is.factor(ModelDataset[,j]))
			}
		}
		rm(columnname)
		rm(ImageName)
		gc()
	}
}

rm(imageList)
rm(thematicimagelist)
gc()

######################################################################################

colnames(ModelDataset)[1] = "Class"

######################################################################################
#
# create random forest model
#
######################################################################################

print("Creating Random Forest Model")

LM_Model = lm(Class~.,data = ModelDataset)


rm(ModelDataset)
gc()

######################################################################################
#
# output to file varimpplot and confusion matrix
#
######################################################################################

base = basename(file_path_sans_ext(OutputModel))


######################################################################################
#
# create predict raster
#
######################################################################################

time1 = Sys.time()

print("Predicting Raster")
if(predicttype=="Thematic"){
	outputrast = predict(ourStack, RF_Model, filename = OutputModel, type='response',progress = "text", datatype = 'INT1U', inf.rm = TRUE)
}else{
	outputrast = predict(ourStack, LM_Model, filename = OutputModel, type='response',progress = "text", datatype = 'INT2U', inf.rm = TRUE)
}

time2 = Sys.time()
totaltime = time2 - time1
print(totaltime)

rm(outputrast)
rm(RF_Model)
rm(predicttype)
rm(ourStack)
rm(OutputModel)
rm(time1)
rm(time2)
rm(totaltime)
gc()
