####################################################################################################
#Inputs This is how they should Look
####################################################################################################
#workspace = "W:/streamorder"
#inFile = "NHDFlowline_Albers_natural_connections.dbf"
#outFile = "NHDFlowline_Albers_natural_connections_strahler.csv"

library(foreign)
setwd(workspace)
time1 = Sys.time()
####################################################################################################
#Custom Functions
####################################################################################################
#Function for getting all first order streams
firstOrder = function(inVector)
	{
	testVector = inVector[2:maxSourceCol]
	nonNA = length(which(!is.na(testVector)))
	if(nonNA == 0)
		{
		return(c(1,inVector[1]))
	}else{
		return(c(NA,NA))
	}
	
	}

#Function for getting all the rest of the streams
getOrders = function(inVector)
	{
	
	removeNAs = inVector[!is.na(inVector)]
	removeNAs = unlist(removeNAs[-1])
	sourcesDF = DF[removeNAs,orderCol:sourceCol]
	if(any(is.na(sourcesDF$Order)))
		{
		return(c(NA,NA))
		}
	#Get dataframe with no duplicate sources
	noDupes = sourcesDF[!duplicated(sourcesDF[,2]),]
	
	#Get number of sources, if the number of sources is 1, simply assign it's attributes
	numSources = dim(noDupes)[1]
	if(numSources == 1)
		{
		return(c(noDupes[1,1],noDupes[1,2]))
		}
	
	#If there is more than one source, identify the maximum stream order
	maxOrder = max(noDupes[,1])
	maxWhich = which.max(noDupes[,1])
	maxOccurences = sum(maxOrder == noDupes[,1])
	
	if(maxOccurences==1)
		{
		return(c(noDupes[maxWhich,1],noDupes[maxWhich,2]))
	}else if(maxOccurences>1){
		return(c(maxOrder + 1,noDupes[maxWhich,2]))
	}
	
	}

####################################################################################################
#Prep Data structures
####################################################################################################
#Read in data
DF = read.dbf(inFile)

#Delete unnecessary columns
first = which("ORIG_FID"==colnames(DF))
last = dim(DF)[2] - 1
DF = DF[,first:last]

#Make sure that each column starts with "O", if it doesn't, delete it
delVec = c()

for(i in 1:length(colnames(DF)))
	{
	if(substring(colnames(DF)[i],1,1) != "O")
		{
		delVec = append(delVec,i)
		}
	}
if(length(delVec)>0)
	{
	DF = DF[,-delVec]
	}
	
#Get max number of stream sources columns
maxSourceCol = dim(DF)[2]
orderCol = maxSourceCol + 1
sourceCol = maxSourceCol + 2
#Convert all zeros to NA
DF[DF==0] = NA

#Set up Column names
colnames(DF)[1] = "StreamID"
colnameVec = c()
for(i in 2:dim(DF)[2])
	{
	StreamSourceName = paste("StreamSource_",i,sep="")
	colnameVec = c(colnameVec,StreamSourceName)
	}
colnames(DF)[2:dim(DF)[2]] = colnameVec

#Add empty vectors for source and stream order
emptyVec = rep(NA,dim(DF)[1])
DF = cbind(DF,emptyVec)
DF = cbind(DF,emptyVec)
colnames(DF)[dim(DF)[2] - 1] = "Order"
colnames(DF)[dim(DF)[2]] = "Source"


#call the first order stream function
firstOrderVec = t(apply(DF,1,firstOrder))

#assign order and source for all first order streams
DF[1:dim(DF)[1],orderCol:sourceCol] = firstOrderVec

####################################################################################################
#Get rest of the stream orders
####################################################################################################
test = 0
lastLeft = -99
while(test==0)
	{
	notAssignedDF = subset(DF, is.na(DF[,orderCol]))
	curLeft = dim(notAssignedDF)[1]
	print("This many lines left to Attribute")
	print(curLeft)
	if(lastLeft == curLeft)
		{
		break
		}
	lastLeft = curLeft
	
	if(dim(notAssignedDF)[1]==0)
		{
		break
		}
	nextOrderVec = t(apply(notAssignedDF,1,getOrders))
	replaceRows = as.vector(as.integer(rownames(nextOrderVec)))
	DF[replaceRows,orderCol] = as.integer(nextOrderVec[,1])
	DF[replaceRows,sourceCol] = as.integer(nextOrderVec[,2])
	rm(notAssignedDF)
	rm(nextOrderVec)
	rm(replaceRows)
	}

write.csv(DF,outFile,row.names= FALSE)

time2 = Sys.time()
totaltime = time2 - time1
print(totaltime)
q()



