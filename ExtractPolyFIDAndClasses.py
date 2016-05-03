import arcpy, csv

# Set the Arc Workspace
workspace = arcpy.GetParameterAsText(0)
arcpy.AddMessage('Workspace: ' + workspace)
arcpy.env.workspace = workspace

# Overwrite files
arcpy.env.overwriteOutput = True

#set points and segments
refdata = arcpy.GetParameterAsText(1)
arcpy.AddMessage('Points: ' + refdata) 
segments = arcpy.GetParameterAsText(2)
arcpy.AddMessage('Segments: ' + segments) 

#set FID field 
FIDfield = arcpy.GetParameterAsText(3)
arcpy.AddMessage('FID: ' + FIDfield) 

#set class field
ClassField = arcpy.GetParameterAsText(4)
arcpy.AddMessage('Class: ' + ClassField) 

#set which classes you want
classes = arcpy.GetParameterAsText(5)
arcpy.AddMessage('Selected Classes: ' + classes)

#set output table
outputcsv = arcpy.GetParameterAsText(6)
arcpy.AddMessage('Output CSV: ' + outputcsv)

#create points feature layer
pointsfl = 'sites_fl'
arcpy.MakeFeatureLayer_management(refdata, pointsfl)

#select points if the field is equal to the class you want
arcpy.SelectLayerByAttribute_management(pointsfl,'NEW_SELECTION', classes)

#spatial join between point and segments
temp1 = 'temp1.shp'
temp2 = 'temp2.shp'
arcpy.SpatialJoin_analysis(pointsfl,segments,temp1,'','KEEP_COMMON')
arcpy.Sort_management(temp1,temp2,[[FIDfield,"ASCENDING"]])

#create csv file
c = csv.writer(open(outputcsv,'wb'))
c.writerow(['FID','Class'])

#loop through each row and write values to csv
rows = arcpy.SearchCursor(temp2)
test = -1  # this is used to handle multiple points in segments
for row in rows:
	if row.getValue(FIDfield) != test:
		c.writerow([str(row.getValue(FIDfield)),str(row.getValue(ClassField))])
	test = row.getValue(FIDfield)

# Cleanup
arcpy.Delete_management(temp1)
arcpy.Delete_management(temp2)
