#Random Point Generator
#Because arcmap's version is terrible

import arcpy
import random

##############################################################################
#parameters
##############################################################################
#work = r'M:\Sawtooth\Mapping\CanopyCover\Reference_data\Create_random_pts.gdb'
#boundshp = r"M:\Sawtooth\Mapping\CanopyCover\Reference_data\Create_random_pts.gdb\ST_Draftmap_2014_1_17_dissolve_singlepart_dissolve_south"
#numpoints = 1000
#outpoints = "outpoints.shp"

work = arcpy.GetParameterAsText(0)
boundshp = arcpy.GetParameterAsText(1)
numpoints = arcpy.GetParameterAsText(2)
outpoints = arcpy.GetParameterAsText(3)

##############################################################################
arcpy.env.workspace = work
arcpy.env.overwriteOutput = True
##############################################################################
#determine whether workspace is a geodatabase or a folder
end = work[-4:]
if end == ".gdb":

	#get rid of the ".shp" if it exists
	if outpoints[-4:] == ".shp":
		outpoints = outpoints[:-4]
	#create temporary bounding shapefile
	extentpoly = "tempextent12341"


	extent = arcpy.Describe(boundshp).extent
	spatialref = arcpy.Describe(boundshp).SpatialReference
	#array to hold points
	array = arcpy.Array()
	#Create the bouding box
	lowerleft = extent.lowerLeft
	array.add(lowerleft)
	lowerright = extent.lowerRight
	array.add(lowerright)
	upperright = extent.upperRight
	array.add(upperright)
	upperleft = extent.upperLeft
	array.add(upperleft)
	# ensure the polygon is closed
	array.add(extent.lowerLeft)
	# Create the polygon object
	polygon = arcpy.Polygon(array)
	array.removeAll()
	arcpy.CopyFeatures_management(polygon, extentpoly)
	del polygon
	arcpy.DefineProjection_management(extentpoly, spatialref)

	#add acres field, then calculate acres
	try:
		arcpy.AddField_management(extentpoly, "acres", "FLOAT")
	except:
		print "field already present"
	#calculate acres
	arcpy.CalculateField_management(extentpoly, "acres", "float('!shape.area@acres!')","PYTHON")

	rows = arcpy.SearchCursor(extentpoly)
	extentacres = 0
	for row in rows:
		extentacres = row.getValue("acres")

	del rows
	
	##############################################################################
	#get acres from bounding shapefile
	##############################################################################
	#add acres field, then calculate acres
	try:
		arcpy.AddField_management(boundshp, "acres", "FLOAT")
	except:
		print "field already present"
	#calculate acres
	
	arcpy.CalculateField_management(boundshp, "acres", "float('!shape.area@acres!')","PYTHON")
	
	rows = arcpy.SearchCursor(boundshp)
	boundacres = 0
	for row in rows:
		boundacres = row.getValue("acres")

	del rows

	#get the proportion of bound acres to extent acres
	proportion = boundacres/extentacres
	newproportion = proportion/3.0
	#calculate how many points you will need
	realnumpoints = float(numpoints)/newproportion
	realnumpoints = int(realnumpoints)
	##############################################################################
	#generate random points
	##############################################################################
	minx = extent.XMin
	maxx = extent.XMax
	miny = extent.YMin
	maxy = extent.YMax
	
	temppoints = "temporarypoints12343"
	arcpy.CreateFeatureclass_management(work,temppoints,"POINT",'','','',spatialref)
	#create insert cursor
	inserter = arcpy.InsertCursor(temppoints)

	#pick random x,y and add that point to the point file
	for i in range(1,realnumpoints):
		x = random.uniform(minx, maxx)
		y = random.uniform(miny,maxy)
		point = arcpy.Point(x,y)
		newrow = inserter.newRow()
		newrow.shape = arcpy.PointGeometry(point)
		inserter.insertRow(newrow)

	##############################################################################
	#intersect points with boundshp and limit to the specified number
	##############################################################################

	#create feature layer
	temppoints_fl = "temp_fl"
	arcpy.MakeFeatureLayer_management(temppoints,temppoints_fl)

	#select all the points that intersect the bounding shape
	arcpy.SelectLayerByLocation_management(temppoints_fl,"INTERSECT",boundshp,'','NEW_SELECTION')
	temppoints2 = "temporarypoints123435"
	#copy the intersected features
	arcpy.CopyFeatures_management(temppoints_fl,temppoints2)

	#add a field for numbers
	arcpy.AddField_management(temppoints2,"numbers","SHORT")

	#create an update cursor
	updater = arcpy.UpdateCursor(temppoints2)

	#calculate consecutive numbers
	i = 1
	for row in updater:
		row.numbers = i
		updater.updateRow(row)
		i = i + 1

	#create feature layer that only has the user specified number of points
	temppoints_fl2 = "temp_fl_2"
	arcpy.MakeFeatureLayer_management(temppoints2,temppoints_fl2, '"numbers"<=' +str(numpoints))

	#copy to final point file
	arcpy.CopyFeatures_management(temppoints_fl2,outpoints)
###################################################################################################
#else, if the workspace is a folder
###################################################################################################
else:
	
	#add '.shp' if the outpoints doesn't have it
	if outpoints[-4:] != ".shp":
		outpoints = outpoints + ".shp"
		
	#create temporary bounding shapefile
	extentpoly = "tempextent12341.shp"


	extent = arcpy.Describe(boundshp).extent
	spatialref = arcpy.Describe(boundshp).SpatialReference
	#array to hold points
	array = arcpy.Array()
	#Create the bouding box
	lowerleft = extent.lowerLeft
	array.add(lowerleft)
	lowerright = extent.lowerRight
	array.add(lowerright)
	upperright = extent.upperRight
	array.add(upperright)
	upperleft = extent.upperLeft
	array.add(upperleft)
	# ensure the polygon is closed
	array.add(extent.lowerLeft)
	# Create the polygon object
	polygon = arcpy.Polygon(array)
	array.removeAll()
	arcpy.CopyFeatures_management(polygon, extentpoly)
	del polygon
	arcpy.DefineProjection_management(extentpoly, spatialref)

	#add acres field, then calculate acres
	try:
		arcpy.AddField_management(extentpoly, "acres", "FLOAT")
	except:
		print "field already present"
	#calculate acres
	arcpy.CalculateField_management(extentpoly, "acres", "float('!shape.area@acres!')","PYTHON")

	rows = arcpy.SearchCursor(extentpoly)
	extentacres = 0
	for row in rows:
		extentacres = row.getValue("acres")

	del rows

	##############################################################################
	#get acres from bounding shapefile
	##############################################################################
	#add acres field, then calculate acres
	try:
		arcpy.AddField_management(boundshp, "acres", "FLOAT")
	except:
		print "field already present"
	#calculate acres
	arcpy.CalculateField_management(boundshp, "acres", "float('!shape.area@acres!')","PYTHON")

	rows = arcpy.SearchCursor(boundshp)
	boundacres = 0
	for row in rows:
		boundacres = row.getValue("acres")

	del rows


	#get the proportion of bound acres to extent acres
	proportion = boundacres/extentacres
	newproportion = proportion/3.0

	#calculate how many points you will need
	realnumpoints = float(numpoints)/newproportion
	realnumpoints = int(realnumpoints)
	print realnumpoints

	##############################################################################
	#generate random points
	##############################################################################
	minx = extent.XMin
	maxx = extent.XMax
	miny = extent.YMin
	maxy = extent.YMax

	temppoints = "temporarypoints12343.shp"
	arcpy.CreateFeatureclass_management(work,temppoints,"POINT",'','','',spatialref)
	#create insert cursor
	inserter = arcpy.InsertCursor(temppoints)

	#pick random x,y and add that point to the point file
	for i in range(1,realnumpoints):
		x = random.uniform(minx, maxx)
		y = random.uniform(miny,maxy)
		point = arcpy.Point(x,y)
		newrow = inserter.newRow()
		newrow.shape = arcpy.PointGeometry(point)
		inserter.insertRow(newrow)

	##############################################################################
	#intersect points with boundshp and limit to the specified number
	##############################################################################

	#create feature layer
	temppoints_fl = "temp_fl"
	arcpy.MakeFeatureLayer_management(temppoints,temppoints_fl)

	#select all the points that intersect the bounding shape
	arcpy.SelectLayerByLocation_management(temppoints_fl,"INTERSECT",boundshp,'','NEW_SELECTION')
	temppoints2 = "temporarypoints123435.shp"

	#copy the intersected features
	arcpy.CopyFeatures_management(temppoints_fl,temppoints2)

	#add a field for numbers
	arcpy.AddField_management(temppoints2,"numbers","SHORT")

	#create an update cursor
	updater = arcpy.UpdateCursor(temppoints2)

	#calculate consecutive numbers
	i = 1
	for row in updater:
		row.numbers = i
		updater.updateRow(row)
		i = i + 1

	#create feature layer that only has the user specified number of points
	temppoints_fl2 = "temp_fl_2"
	arcpy.MakeFeatureLayer_management(temppoints2,temppoints_fl2, '"numbers"<=' +str(numpoints))

	#copy to final point file
	arcpy.CopyFeatures_management(temppoints_fl2,outpoints)



#delete temporary point files
arcpy.Delete_management(temppoints)
arcpy.Delete_management(temppoints2)
arcpy.Delete_management(extentpoly)









