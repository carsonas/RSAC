import arcpy

#workspace = r"M:\Sawtooth\Mapping\ST_north\modelling\alpine_v_forb\scripted"

#####################################################
#Inputs
workspace = arcpy.GetParameterAsText(0)
elevation = arcpy.GetParameterAsText(1)
polys = arcpy.GetParameterAsText(2)
watershed_out_save = arcpy.GetParameterAsText(3)

arcpy.env.workspace = workspace
arcpy.env.overwriteOutput = True
arcpy.CheckOutExtension("Spatial")
#####################################################
# create inverse flow direction raster
#elevation = "st_north_elevation_m.img"
fillelevation = arcpy.sa.Fill(elevation)
fillelevation.save("fillelev")

rasElevation = arcpy.sa.Raster("fillelev")

rasflipped = rasElevation * -1
rasflipped.save("elev_flipped.img")

outFlow = arcpy.sa.FlowDirection(rasflipped,"FORCE")
outFlow.save("outFlowdir")
#####################################################
#####################################################
# Take forested polys and convert to raster
#polys = "ST_forested_polys.shp"

poly_temp = "poly_fl"
arcpy.MakeFeatureLayer_management(polys,poly_temp)

arcpy.AddField_management(poly_temp,"One_Value","SHORT")
arcpy.CalculateField_management(poly_temp,"One_Value",1)
forest_rast = "forest_temp.img"
arcpy.PolygonToRaster_conversion(poly_temp,"One_Value",forest_rast,'','',10)
#watershed_out_save = "Not_Tree_line.img"
watershed_out = arcpy.sa.Watershed("outFlowdir",forest_rast)
watershed_out.save(watershed_out_save)
arcpy.Delete_management(poly_temp)
arcpy.Delete_management(forest_rast)
arcpy.Delete_management("outFlowdir")
arcpy.Delete_management("elev_flipped.img")
arcpy.Delete_management("fillelev")





