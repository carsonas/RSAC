########################################################################
#user input
########################################################################

#output image
OutputModel = "landsat_scene_for_rf_unsup_test_10classes_CART_20000.img"

#number of desired clusters
clustnum = 10

#number of samples
num_samples = 10000

#workspace
workspace = "M:/Manti_La_Sal/Reference_Data/Field_Sites/01_Site_Placement/00_RF_Unsup_Test_20140328"

#input image
image = "landsat_scene_for_rf_unsup_test.img"
########################################################################


library(raster)
library(randomForest)
setwd(workspace)

l8stack = stack(image)
l8DF = as.data.frame(l8stack)

l8DFsample = l8DF[sample(nrow(l8DF),num_samples),]
rm(l8DF)

l8stack.unsup = randomForest(l8DFsample, proximity = TRUE)

l8stack.proximity = l8stack.unsup$proximity
rm(l8stack.unsup)
gc()
l8stack.proximity = 1 - l8stack.proximity
l8stack.proximity = as.dist(l8stack.proximity)

########################################################################
#Cluster Analysis using euclidean distance
########################################################################

fit = hclust(l8stack.proximity, method = "ward")

plot(fit)
#cut the tree to create clustnum clusters
groups = cutree(fit,k=clustnum)
rect.hclust(fit,k=clustnum, border = "red")

#combine Spatial_IDs with cluster groups
df_with_groups = cbind(l8DFsample, groups)
rm(groups)
rm(fit)
gc()
########################################################################
#CART from cluster
########################################################################
library(rpart)
df_with_groups$groups = as.factor(df_with_groups$group)
#df.RF = randomForest(groups~., data = df_with_groups,importance=TRUE,ntree=1000, na.action=na.omit)
df.Cart = rpart(groups~., data = df_with_groups, control = rpart.control(cp=0.0, minsplit = 2))
rm(df_with_groups)
########################################################################
#Apply CART model to whole landsat scene
########################################################################
outputrast = predict(l8stack, df.Cart, filename = OutputModel, type='class',progress = "text", datatype = 'INT1U', inf.rm = TRUE)

