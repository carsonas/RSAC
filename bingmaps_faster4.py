#this is a text
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

#get zoom scale for bing maps
zl = 0
if scale >295829355:
                zl = 1
elif scale > 147914677:
                zl = 1
elif scale > 73957338.86:
                zl = 2
elif scale > 36978669.43:
                zl = 3
elif scale > 18489334.72:
                zl = 4
elif scale > 9244667.36:
                zl = 5
elif scale > 4622333.68:
                zl = 6
elif scale > 2311166.84:
                zl = 7
elif scale > 1155583.42:
                zl = 8
elif scale > 577791.71:
                zl = 9
elif scale > 288895.85:
                zl = 10
elif scale > 144447.93:
                zl = 11
elif scale > 72223.96:
                zl = 12
elif scale > 36111.98:
                zl = 13
elif scale > 18055.99:
                zl = 14
elif scale > 9028.00:
                zl = 15
elif scale > 4514.00:
                zl = 16
elif scale > 2257.00:
                zl = 17
elif scale > 1128.50:
                zl = 18
elif scale > 564.25:
                zl = 19
elif scale > 282.12:
                zl = 20
elif scale > 141.06:
                zl = 21
elif scale > 0:
                zl = 22
                

#Create URL
stringbeg = "http://www.bing.com/maps/?v=2&cp="
midstring = str(latitude) + "~" + str(longitude)
stringmid2 = "&sty=a&lvl="
stringend = str(zl)
wholestring = stringbeg + midstring + stringmid2 +stringend
arcpy.AddMessage(wholestring)

#open up bingmaps
webbrowser.open(wholestring)

#tidy up
del mxd
del scale
del olddf
arcpy.Delete_management(new_shp)
arcpy.Delete_management(new_shp2)