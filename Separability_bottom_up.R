#################################################################################
#Set user defined parameters
#The "workspace", "modeltxt", and "factors" are the only lines of code that need to be
#changed by the user.
#################################################################################
#set up workspace and model dataset
workspace = "C:/Users/castam/Desktop/temp/yakutat/"			#Example: "M:/Sawtooth/Mapping/ST_north/separability"
modeltxt = 	"Model_Dataset.csv"			#Example: "st_n_separability_model_allpoints.txt"

#list all column names that should be considered factors
factors = c()    			#Example: c("st_north_landtype_filled1_MAJORITY","st_north_geology_MAJORITY", "st_north_soils_MAJORITY")
#################################################################################

#set workspace
setwd(workspace)
library(randomForest)

#read in model dataset
d1= read.table(modeltxt,header=T)



######################################################################################
#read in datasets and change factor variables to factors
######################################################################################

#get dimension
d1_collen = dim(d1)[2]

#create subset of model dataset that does not include FID
d2 = d1[,2:d1_collen]

#loop through the model dataset and change all factors columns to factors
for(i in 1:length(factors)){
	for(j in 1:dim(d2)[2]){
		if(colnames(d2)[j]==factors[i]){
			x1 = d2[,j]
			x2 = as.factor(x1)
			d2[,j] = x2		
		}
	}
}

######################################################################################
#Function for identifying pair with worst separability
######################################################################################


GetMaxValueDF = function(filled_df){

maxValue = max(filled_df)
a = 0
b = 0
for(i in 1:dim(filled_df)[1]){
	for(j in 1:dim(filled_df)[2]){
		if(filled_df[i,j]-maxValue==0){
		a = i
		b = j
		}
	}
}

worstpair = c(rownames(filled_df)[a],colnames(filled_df)[b])
worstpair = append(worstpair,maxValue)
return(worstpair)
}
######################################################################################
#Function to take pair with highest OOB error and collapse those classes
######################################################################################
CollapseVegTypes = function(worstpair,veg_dataframe){
	temp_filled_df = veg_dataframe
	temp_filled_df[,1] = as.character(temp_filled_df[,1])
	collapsedname = paste(worstpair[1],worstpair[2],sep="",collapse = "")
	for(i in 1:dim(temp_filled_df)[1]){
		if(temp_filled_df[i,1] %in% worstpair){
			temp_filled_df[i,1] = collapsedname
		}
	}
	temp_filled_df[,1] = as.factor(temp_filled_df[,1])
	return(temp_filled_df)
}

######################################################################################
# Create function that gets all the factor levels and creates an empty vector to store similarity values
# Each time that RF is run, the number of samples used is determined by the class with the minimum
# number of samples
######################################################################################
GenerateConfusionMatrixRF_minSamples = function(vegdataframe){


allLevels = levels(vegdataframe[,1])
numberlevels = length(allLevels)

empty_df = data.frame(matrix(0,nrow = numberlevels, ncol = numberlevels))
colnames(empty_df) = allLevels
rownames(empty_df) = allLevels


#generate similarity values among each pair


for(i in 1:numberlevels){
	currentvegtype = rownames(empty_df)[i]
	for(j in 1:numberlevels){
		bothvegtypes = c(currentvegtype,colnames(empty_df)[j])
		if(bothvegtypes[1] != bothvegtypes[2]){
			omit = c()
			for (k in 1:dim(vegdataframe)[1])
			{
				if(vegdataframe[k,1] %in% bothvegtypes){
					}
				else{
					omit = append(omit,k)
					}
			}
			if(length(omit)>=1){
				temp_d2 = vegdataframe[-omit,]
			}
			else{temp_d2 = vegdataframe}
			temp_d2[,1] = droplevels(temp_d2[,1])
			#limit by number of samples
			Counttable = table(temp_d2[,1])
			CountDF = as.data.frame(Counttable)
			Count1 = CountDF[1,2]
			Count2 = CountDF[2,2]
			if(Count1 == Count2){
				temp_d2 = temp_d2
			}
			else{
				Countmin = min(c(Count1,Count2))
				randomvec = rnorm(dim(temp_d2)[1],mean = 200, sd = 3)
				randomvec = as.vector(randomvec)
				cbind(temp_d2,randomvec)
				temp_d2 = temp_d2[order(temp_d2[,1],temp_d2[,dim(temp_d2)[2]]),]
				factor1_df = temp_d2[1:Countmin,]
				start2 = Count1+1
				end2 = Count1+Countmin
				factor2_df = temp_d2[start2:end2,]
				temp_d2 = rbind(factor1_df,factor2_df)
				temp_d2[,dim(temp_d2)[2]] = NULL
			}
			RF_model = randomForest(Class~., data=temp_d2,importance=TRUE,ntree=1000)
			accClass1 = as.data.frame(RF_model[5])[1,3]
			accClass2 = as.data.frame(RF_model[5])[2,3]
			OOB = (accClass1 + accClass2)/2.0
			empty_df[i,j] = OOB
		}
		else{empty_df[i,j] = -1}
	}
}
return(empty_df)
}
######################################################################################
######################################################################################
#Use functions
######################################################################################


TotalLevels = length(levels(d2[,1]))

while(length(levels(d2[,1]))>1){
	confusion_df2 = GenerateConfusionMatrixRF_minSamples(d2)
	worstpair = GetMaxValueDF(confusion_df2)
	print(worstpair)
	d2 = CollapseVegTypes(worstpair,d2)
}

