library(raster)
setwd("M:/Rio_Grande/Data/Imagery/Landsat/GEE_data/Fall")

rast1 = "RG_l8_Oct2013_TCT_bgwa.img"

rast1 = stack(rast1)

disaggregate(rast1, fact = 3, filename = "M:/Rio_Grande/Mapping/CC_modeling/datalayers/RG_l8_Oct2013_TCT_bgwa_R_5m.img")