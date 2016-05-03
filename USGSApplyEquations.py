import arcpy


####################################################################################################################
#Input paramaters
#Only edit this section
####################################################################################################################
#workspace - folder where temporary files and the output image will be written to
workspace = "M:/TRB/Modeling/ValleyTyping/NE"

#Streams layer representing height above channels.  This is the "source raster".
NHDsnappedStream = "M:/TRB/Modeling/ValleyTyping/NE/NE_q50_HAC_meters_roundup_times2_int_fixnull.img"

#Cost distance raster based on slope
slope_radians = "M:/TRB/Modeling/ValleyTyping/NE/NE_cost_raster.img"

#PrecisionFactor. If you multiplied your streams layer by a factor to increase precision, use the value you used for precFactor.
#If you did not multiply by anything, set precFactor to 1.0.
precFactor = 2.0

#The output image name. Do not include the full path.
outImageName = "NE_USGS_equation_q50_height.img"
####################################################################################################################


arcpy.env.workspace = workspace
arcpy.env.snapRaster = slope_radians
arcpy.env.cellSize = slope_radians
arcpy.env.overwriteOutput = True
arcpy.env.pyramid = "NONE"
arcpy.CheckOutExtension("Spatial")


#Get max order for the current HUC8
print arcpy.GetRasterProperties_management(NHDsnappedStream,"MAXIMUM").getOutput(0)
maxOrder = int(arcpy.GetRasterProperties_management(NHDsnappedStream,"MAXIMUM").getOutput(0))

for i in range(1,maxOrder + 1):
	print i
	limitOrder = arcpy.sa.SetNull(NHDsnappedStream,NHDsnappedStream,'NOT VALUE =' + str(i))
	OrderHACname = "HAC_order_" + str(i) + ".img"
	floodTo = i/precFactor
	OrderHAC = arcpy.sa.CostDistance(limitOrder,slope_radians,floodTo)
	OrderHAC.save(OrderHACname)

#Mosaic based on minimum height above channel
HACs = arcpy.ListRasters("HAC_order_*.img")
Cellmin = arcpy.sa.CellStatistics(HACs,"MINIMUM","DATA")
binaryHAC = arcpy.sa.Reclassify(Cellmin, "Value",arcpy.sa.RemapRange([[0,maxOrder,1]]))
binaryHACname = workspace  +  "/" + outImageName
binaryHAC.save(binaryHACname)
del Cellmin
del binaryHAC

for HAC in HACs:
	arcpy.Delete_management(HAC)
