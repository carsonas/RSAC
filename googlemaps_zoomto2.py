#This script was produced by Carson Stam, a contract employee working at the Remote Sensing Applications Center in Salt Lake City.


import webbrowser
import os

#Get desktop location for saving temporary .mxd
user_profile = os.environ['USERPROFILE']
userdesktop = user_profile + "/Desktop"
new_shp = userdesktop + "/temporaryshape12321.shp"
new_shp2 = userdesktop + "/temporaryshape123212.shp"


#get current map extent and scale
mxd = arcpy.mapping.MapDocument("CURRENT")
olddf = arcpy.mapping.ListDataFrames(mxd)[0]
scale = olddf.scale

############################################################################################################
#Try new way
############################################################################################################

dfAsFeature = arcpy.Polygon(arcpy.Array([olddf.extent.lowerLeft,olddf.extent.lowerRight,olddf.extent.upperRight,olddf.extent.upperLeft]),olddf.spatialReference)
arcpy.CopyFeatures_management(dfAsFeature,new_shp)

##get WGS 84 projection.  These 5 lines of code below take care of differences in getting projection between 10.0 and 10.1
prjfile = os.path.join(arcpy.GetInstallInfo()["InstallDir"], "Coordinate Systems/Geographic Coordinate Systems/World/WGS 1984.prj")
if os.path.exists(prjfile):
	geographicSF = prjfile
else:
	geographicSF = arcpy.SpatialReference(4326)

arcpy.Project_management(new_shp,new_shp2,geographicSF)
desc = arcpy.Describe(new_shp2)

#get four corners of arcmap extent
xmin = desc.extent.XMin
xmax = desc.extent.XMax
ymin = desc.extent.YMin
ymax = desc.extent.YMax

#get center point
longitude = (xmin + xmax)/2.0
latitude = (ymin + ymax)/2.0


#Create URL
#http://maps.google.com/?q=<lat>,<lng>
stringbeg = "http://maps.google.com/?q="
midstring = str(latitude) + "," + str(longitude)

wholestring = stringbeg + midstring
arcpy.AddMessage(wholestring)

#open up bingmaps
webbrowser.open(wholestring)

#tidy up
del mxd
del scale
del olddf
arcpy.Delete_management(new_shp)
arcpy.Delete_management(new_shp2)