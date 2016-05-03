######################################################################################
#
#  Set up R
#
######################################################################################
install.packages("randomForest", repos='http://cran.us.r-project.org')
library(randomForest)

# Turns off scientific notation
options(scipen=999)

#set workspace
setwd(workspace)
rm(workspace)

######################################################################################
#
# Read in the reference data
#
######################################################################################

ReferencePoints = read.csv(points,header=T)
rm(points)

######################################################################################
#
# Read in the zonal stats
#
######################################################################################

# Read the first 5 rows of the zonal stats.
ZonalStats_5Rows = read.table(zonalstats,header=T,nrows=26100)

# Use the first 5 rows of the zonal stats to determine the column type ("integer", "character", "numeric", etc.)
ColumnTypes = sapply(ZonalStats_5Rows,class)
rm(ZonalStats_5Rows)

# Reading in the zonal stats file with the column types pre-defined speeds the process up by 50%
AllZonalStats = read.table(zonalstats,header=T,colClasses=ColumnTypes)
rm(zonalstats)
rm(ColumnTypes)

# Get the zonal stats headers
ZonalStatsHeaders = colnames(AllZonalStats)
NumberOfVariables = length(ZonalStatsHeaders)

######################################################################################
#
# Remove variables in the "exclude" list
#
######################################################################################

if (exclude != '')
{
	omit = c()
	for (i in 1:NumberOfVariables)
	{
		if(ZonalStatsHeaders[i] %in% exclude)
		{
			omit = append(omit,i)
		}	
	}
	ZonalStatsExcludedRemoved = AllZonalStats[,-omit]
	rm(omit)
} else
{
	ZonalStatsExcludedRemoved  = AllZonalStats
}

rm(exclude)
rm(ZonalStatsHeaders)
rm(NumberOfVariables)

######################################################################################
#
# Get the Zonal Statistics for the "Model" Data Set
#
######################################################################################

nrows = dim(AllZonalStats)[1]
modelFIDs = ReferencePoints[,1]

Model_ZonalStats = ZonalStatsExcludedRemoved[0,]
erase = c()
for (i in 1:nrows)
{
	if(AllZonalStats[i,1] %in% modelFIDs)
	{
		Model_ZonalStats = rbind(Model_ZonalStats,ZonalStatsExcludedRemoved[i,])	
		erase = append(erase,i)
	}
}
rm(AllZonalStats)
rm(nrows)
rm(modelFIDs)

######################################################################################
#
# Get the Zonal Statistics for the "Apply" Data Set
#
######################################################################################

Apply_ZonalStats = ZonalStatsExcludedRemoved[-erase,]
rm(ZonalStatsExcludedRemoved)
rm(erase)

######################################################################################
#
#  Create the "Model" Data Set
#
######################################################################################

ModelDataset = Model_ZonalStats[,2:dim(Model_ZonalStats)[2]]
ModelDataset = cbind(ModelDataset,ReferencePoints[,2])
names(ModelDataset)[dim(ModelDataset)[2]] = "Class"
rm(Model_ZonalStats)

######################################################################################
#
#  Assign Factors to the "Model" Dataset
#
######################################################################################

if (facts != '')
{
	for(i in 1:length(facts))
	{
		for(j in 1:dim(ModelDataset)[2])
		{
			if(colnames(ModelDataset)[j]==facts[i])
			{
				x1 = ModelDataset[,j]
				x2 = as.factor(x1)
				ModelDataset[,j] = x2		
				rm(x1)
				rm(x2)
				gc()
			}
		}
	}
}

######################################################################################
#
#  Assign Factors to the "Apply" Dataset
#
######################################################################################

if (facts != '')
{
	for(i in 1:length(facts))
	{
		for(j in 1:dim(Apply_ZonalStats)[2])
		{
			if(colnames(Apply_ZonalStats)[j]==facts[i])
			{
				x1 = Apply_ZonalStats[,j]
				x2 = as.factor(x1)
				Apply_ZonalStats[,j] = x2		
				rm(x1)
				rm(x2)
				gc()
			}
		}
	}
}

######################################################################################
#
#  Assign all the "Apply" data sets levels to the factors in the "Model" data set
#
######################################################################################

if (facts != '')
{
	for(i in 1:length(facts))
	{
		for(j in 1:dim(Apply_ZonalStats)[2])
		{
			if(colnames(Apply_ZonalStats)[j]==facts[i])
			{
				factlevels = levels(Apply_ZonalStats[,j])
				levels(ModelDataset[,j-1])=factlevels
				rm(factlevels)
				gc()
			}	
		}
	}
}

rm(facts)

######################################################################################
#
# Run randomForest
#
######################################################################################

library(randomForest)

RF_Model = randomForest(Class~., data=ModelDataset,importance=TRUE,ntree=1000)
#save(ReferencePoints,ModelDataset,Apply_ZonalStats,RF_Model,file=OutputModel)

print(RF_Model)
rm(ModelDataset)
######################################################################################
#output to file varimpplot and confusion matrix
base = unlist(strsplit(basename(OutputModel),split = "\\."))[1]
output_confusion = paste(base,"_confusion_matrix.txt",sep="",collapse = "")
confusion_matrix = as.data.frame(RF_Model[5])
write.table(confusion_matrix, output_confusion)

varimp = paste(base,"_VarImpPlot.png",sep="",collapse = "")
png(filename=varimp, width = 10, height= 6, units = "in", res = 300)
varImpPlot(RF_Model, type = 1)
dev.off()
######################################################################################
#
#  Create Predictions in bunches of 50,000 records
#
######################################################################################

#If there are more than 50,000 records, get how many times it must loop through 50,000

fifties = floor(dim(Apply_ZonalStats)[1]/50000)
fiftyplusone = (fifties*50000)+1
AllPredictions = c()
if (dim(Apply_ZonalStats)[1] > 50000)
{
	print("Number of Segments Classified:")
	

	#loop through groups of 50,000 up to fifties * 50,000
	
	for(i in 1:fifties)
	{
		j = i*50000
		k = j-50000+1
		Apply_Subset = Apply_ZonalStats[k:j,]
		Predictions = predict(RF_Model,Apply_Subset,type="response")
		Predictions_Vector = as.vector(Predictions)
		AllPredictions=c(AllPredictions,Predictions_Vector)
		rm(Predictions_Vector)
		rm(Predictions)
		rm(Apply_Subset)
		gc()
		print(j)
	}
}

#  Create predictions for the remaining rows

Apply_NumberOfRows = dim(Apply_ZonalStats)[1]

Apply_Subset = Apply_ZonalStats[fiftyplusone:Apply_NumberOfRows,]
Predictions = predict(RF_Model,Apply_Subset,type="response")
Predictions_Vector = as.vector(Predictions)
AllPredictions=c(AllPredictions,Predictions_Vector)
rm(Predictions_Vector)
rm(Predictions)
rm(Apply_Subset)
rm(Apply_NumberOfRows)
rm(RF_Model)
gc()

######################################################################################
#
#  output text file
#
######################################################################################

#combine into 1 table with FID and prediction

ApplyFID = as.numeric(Apply_ZonalStats[,1])
ApplyPredictions = as.factor(AllPredictions)
output = as.data.frame(ApplyFID)
output = cbind(output,ApplyPredictions)

rm(Apply_ZonalStats)
rm(ApplyPredictions)
rm(AllPredictions)
rm(ApplyFID)
gc()

colnames(output)[2] = "responses"
colnames(output)[1] = "FID"

TrainingData = ReferencePoints[,1]
TrainingData = as.data.frame(TrainingData)
TrainingData = cbind(TrainingData,as.factor(ReferencePoints[,2]))
colnames(TrainingData)[2] = "responses"
colnames(TrainingData)[1] = "FID"
rm(ReferencePoints)

output = rbind(output,TrainingData)
rm(TrainingData)

#change responses to numeric
output[,2] = as.numeric(as.character(output[,2]))


write.csv(output, outputtxt,row.names=FALSE)
rm(output)
rm(outputtxt)
gc()
q("no")