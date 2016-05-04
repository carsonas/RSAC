##Code for testing every possible combination (4 or less variables at a time).
##Gets model R2 and max VIF.

#######################################################################
#install.packages('zoo')
library(zoo)
#install.packages('car')
library(car)
#install.packages('utils')
library(utils)


# Turns off scientific notation
options(scipen=999)
#######################################################################
#User Parameters
#######################################################################
workspace = "C:/Users/castam/Desktop/temp/Tanu"
setwd(workspace)

#Input CSV
df = read.csv("Model_BSLRPData_Jan28.csv",header=T)
colnames(df)

#Response Variable name and number
responVarNum = 3
responVarName = "BA_WTD_DBH"

#Predictor variables numbers
predVarNums = seq(13,65,1)

#Initial correlation threshold
predVrespCor = 0.01

#VIF threshold
VIFthresh = 5

#######################################################################
#/User Parameters
#######################################################################

#######################################################################
#Check for transformation
#######################################################################

df = cbind(df[,responVarNum],df[,predVarNums])
colnames(df)[1] = responVarName

hist(df[,1])
#hist(sqrt(df[,1]))
#hist(log(df[,1]))
#apply transformation
df[,1] = log(df[,1])
#df[,1] = sqrt(df[,1])
#df[,1] = (df[,1]*df[,1])
df[,1] = (df[,1])

#######################################################################
#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
#SHOULD NOT NEED TO EDIT BEYOND THIS POINT
#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
#######################################################################


###########################################################################
#Remove variables that are not correlated to response based on predVrespCor
###########################################################################
#get correlations
cors = cor(df)
cors = abs(cors)

#limit to one row
cors = cors[1,]
#limit dataframe to those variables with "high" correlation
relevant = cors>predVrespCor
df = df[,relevant]


###########################################################################
#Get all possible combinations
###########################################################################
#Get all possible combinations
allVarNums = seq(2,dim(df)[2],1)
at1 = allVarNums
at2 = t(combn(allVarNums,2))
at3 = t(combn(allVarNums,3))
at4 = t(combn(allVarNums,4))

colnames(at4) = c("var1","var2","var3","var4")

#create parts
na1 = rep(NA,length(at1))
at1variables = cbind(at1,na1,na1,na1)
colnames(at1variables) = c("var1","var2","var3","var4")

na2 = rep(NA,dim(at2)[1])
at2variables = cbind(at2,na2,na2)
colnames(at2variables) = c("var1","var2","var3","var4")

na3 = rep(NA,dim(at3)[1])
at3variables = cbind(at3,na3)
colnames(at3variables) = c("var1","var2","var3","var4")

#put together
varOptions = rbind(at1variables,at2variables,at3variables,at4)



###########################################################################
#/Get all possible combinations
###########################################################################

######################################################################################
#Functions for getting R2 and max VIF of every single combination
######################################################################################

#Function for returning max VIF
vifGetter = function(inModel){
	vif2 = tryCatch({
			allVifs = vif(inModel)
			vif2 = max(allVifs)
			
		},error = function(cond){
			vif2 = 1000
		})
	return(vif2)
}


#Function for calculating R2 and this calls the vifGetter function
R2vif = function(inVec)
	{
	preds = inVec
	preds = na.trim(preds)
	preds = unique(as.vector(preds))
	tempDF = as.data.frame(cbind(df[,1],df[,preds]))
	#print(tempDF)
	colnames(tempDF)[1] = "V1"
	lm1 = lm(V1~.,data=tempDF)
	#get VIF
	vif1 = 0
	if(dim(tempDF)[2]>2)
		{
		vif1 = vifGetter(lm1)
		}
	outAnswer = c(summary(lm1)$adj.r.squared,vif1)
	return(outAnswer)
	}

	
######################################################################################
#Create empty dataframe to hold answers
#Loop through every possible combination of variables and calculate R2 and max VIF
#Return answer to previously empty dataframe
#Write out table
######################################################################################
R2vifs = c(NA,NA)
for(i in 1:dim(varOptions)[1])
	{
	print(i)
	R2vifsingle = R2vif(varOptions[i,])
	R2vifs = rbind(R2vifs,R2vifsingle)
	}

#Remove first row because it is NA/NA
R2vifs = R2vifs[-1,]

#Write out
outTable = cbind(varOptions,R2vifs)
colnames(outTable) = c("var1","var2","var3","var4","AdjR2","VIF")
outTable = as.data.frame(outTable)
outTable = outTable[outTable$VIF<5,]
write.csv(outTable,paste0(responVarName,"_bestmodel_4Var.csv"),row.names=F)

######################################################################################
#Function for printing information about model
######################################################################################

printModel = function(inTable)
	{
	whichModelInd = which.max(inTable$R2)
	whichModel = inTable[whichModelInd,]
	varNums = suppressWarnings(na.trim(as.vector(as.numeric(as.character(whichModel[1:4])))))
	print("Best Model R2")
	print(whichModel[5])
	print("Best Model VIF")
	print(whichModel[6])
	print("Best Model Predictor Names")
	print(colnames(df)[varNums])
	print("Best Model Predictor Numbers")
	print(varNums)
	}

######################################################################################
#Print information about each model (1, 2, 3, and 4 variable models)
######################################################################################
oneVar =outTable[is.na(outTable$var2),] 
twoVar = outTable[is.na(outTable$var3) & is.na(outTable$var2)==FALSE,]
threeVar = outTable[is.na(outTable$var4) & is.na(outTable$var3)==FALSE,]
fourVar = outTable[is.na(outTable$var4)==FALSE,]

printModel(oneVar)
printModel(twoVar)
printModel(threeVar)
printModel(fourVar)
######################################################################################
#Create model so that test can be done
######################################################################################
#testDF = as.data.frame(cbind(df[,1],df[,varNums]))
testDF = as.data.frame(cbind(df[,1],df[,c(19,31,45,51)]))
colnames(testDF)[1] = "V1"
linearModel = lm(V1~.,data=testDF)
summary(linearModel)
vif(linearModel)

