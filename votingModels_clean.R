#Code Written By Carson Stam
#castam@fs.fed.us
#801-975-3466
#Code to make any classifier into a "voting" classifer.  Similar to how random forests makes CART a voting classifer
install.packages("caret")
install.packages("e1017")
library(caret)

#Function to train model
modelDemocracy = function(dataframe, dependentVariable, modelType, NumIter,bootStrapPercent)
	{
	
	#Eventually this could be set up to use many other models
	if(modelType == "svm")
		{
		#install.packages("kernlab")
		library(kernlab)
		
		#what column is the dependant variable?
		dependIndex = which(colnames(dataframe)== dependentVariable)
		###########################################################################
		#Get model and apply dataset using 2/3 of data each time
		numrows = dim(dataframe)[1]
		numSelect = round(numrows * bootStrapPercent)
		rowSeq = seq(1,numrows,1)
		confMatrix = NULL
		overall = 0
		modelVector = c()
		###########################################################################
		#Loop through and create multiple models and apply them to the 33% withheld
		for(i in 1:NumIter)
			{
			useRows = sample(rowSeq,numSelect)
			accRows = rowSeq[-useRows]
			
			ModelDataset = dataframe[useRows,]
			ApplyDataset = dataframe[accRows,]
			
			Answers = ApplyDataset[,dependIndex]
			ApplyDataset = ApplyDataset[,-dependIndex]
			
			###########################################################################
			#Create Model and add it to a list
			
			model = ksvm(x=as.matrix(ModelDataset[,-dependIndex]), y=as.factor(ModelDataset[,dependIndex]),type="C-svc")#,kernel="laplacedot")
			modelVector = c(modelVector,model)
			
			
			###########################################################################
			#Apply Model			
			Preds = predict(model,ApplyDataset)
			
			#Calculate overall accuracy and get confusion matrix
			calcConfusion = confusionMatrix(data = Preds, reference = Answers)
			tempMatrix = as.table(calcConfusion)
			overall = overall + calcConfusion$overall[1]
			
			if(is.null(confMatrix)){
				confMatrix = tempMatrix
			}else{
				confMatrix = confMatrix + tempMatrix
			}
			}
			
		#Print Model Properties
		confMatrix = round(confMatrix/NumIter)
		print("This is the overall Accuracy")
		overall = overall/NumIter
		print(overall)
		print("This is the OOB error Matrix for the Voting Model")
		print(confMatrix)
		outobject = list(overall,confMatrix)
		return(append(outobject,modelVector))
		}
	}

getMode = function(inVec)
	{
	temp = table(as.vector(inVec))
	classOut = names(temp)[temp == max(temp)][1]
	voteOut = max(temp)/(sum(temp)-1)
	return(c(classOut,voteOut))
	}

DemocracyInAction = function(VotingModel, Apply_Data)
	{
	rowSeq = seq(1,dim(Apply_Data)[1],1)
	Predictions = as.data.frame(rowSeq)
	for(i in 3:length(VotingModel))
		{
		Preds = predict(VotingModel[i],Apply_Data)
		Predictions = cbind(Predictions,Preds)
		}
	outPredictions = apply(Predictions,1, getMode)
	outPredictions = as.data.frame(t(outPredictions))
	colnames(outPredictions) = c("Prediction","Vote")
	outPredictions$Vote = as.numeric(as.character(outPredictions$Vote))
	return(outPredictions)	
	}
	
###########################################################################
#Code to test a dataset	
df = iris
ClassCol = 5
colnames(df)[ClassCol] = "Class"

initial = sample(seq(1,dim(df)[1],1),120)
ModelDataset1 = df[initial,]
ApplyDataset1 = df[-initial,]

ClassCol = which(colnames(df)== "Class")
Answers1 = ApplyDataset1[,ClassCol]
ApplyDataset1 = ApplyDataset1[,-ClassCol]


#Call the functions for creating votingSVM model and applying it	
votingSVM = modelDemocracy(ModelDataset, "Class", "svm", 500, 0.66)
results = DemocracyInAction(votingSVM,ApplyDataset1)

#Confusion matrix on test dataset
confusionMatrix(Answers1,results[,1])
