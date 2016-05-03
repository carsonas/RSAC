import subprocess, os, arcpy, tkMessageBox

arcpy.env.overwriteOutput = True

######################################################################################################
#
#  Set up variables
#
######################################################################################################

# Workspace
work = arcpy.GetParameterAsText(0).replace('\\','/')
arcpy.env.workspace = work

# Set temporary output CSV files
outputtext = work + "/temptext.csv"
arcpy.AddMessage(outputtext)

# Template R Script
TemplateScript = arcpy.GetParameterAsText(9).replace('\\','/')

# Output Image
outputimg = arcpy.GetParameterAsText(6).replace('\\','/')

# Geodatabase
geodatabase = arcpy.GetParameterAsText(1)

# Segments
shapefile = arcpy.GetParameterAsText(2)

# Segments ID
FIDfield = arcpy.GetParameterAsText(3)

# Cell Size
CellSize = arcpy.GetParameterAsText(10)

######################################################################################################
#
#  Find R executable
#
######################################################################################################
#
####################
#Find Rscript.exe
######################################################################################################
RnameArray = []
path = r"C:\Program Files\R"
for files in os.walk(path):
	for name in files:
		for n in name:
			if n == "Rscript.exe":
				scriptPath = files[0] + "\Rscript.exe"
				RnameArray.append(scriptPath)

if len(RnameArray)<1:
	path = r"C:\Program Files (x86)\R"
	for files in os.walk(path):
		for name in files:
			for n in name:
				if n == "Rscript.exe":
					scriptPath = files[0] + "\Rscript.exe"
					RnameArray.append(scriptPath)
				

Rexe = " "
for i in RnameArray:
	if i.split("\\")[5]=="x64":
		Rexe = i
		break

if Rexe == " ":
	Rexe = RnameArray[0]

arcpy.AddMessage(Rexe)

######################################################################################################
#
#  Create new script
#
######################################################################################################

ScriptLines = []
ScriptLines.append('workspace = "' + work + '"\n')
ScriptLines.append('points = "' + arcpy.GetParameterAsText(4).replace('\\','/') + '"\n')
ScriptLines.append('zonalstats = "' + arcpy.GetParameterAsText(5).replace('\\','/') + '"\n')
ScriptLines.append('outputtxt = "' + outputtext + '"\n')
ScriptLines.append('exclude = c("' + arcpy.GetParameterAsText(8).replace(';','","') + '")\n')
ScriptLines.append('facts = c("' + arcpy.GetParameterAsText(7).replace(';','","') + '")\n')
ScriptLines.append('OutputModel = "' + os.path.splitext(outputimg)[0] + '.Rdata"\n')

newRscript = os.path.splitext(outputimg)[0] + '.R'
Lines = open(TemplateScript,'r').readlines()
OutputScript = open(newRscript,'w')
OutputScript.writelines(ScriptLines)
OutputScript.writelines(Lines)
OutputScript.close()

######################################################################################################
#
#  Run the R script
#
######################################################################################################

if (Rexe != ''):

        call = subprocess.Popen(Rexe + ' --save "' + newRscript + '"')
        call.wait()

        ######################################################################################################
        #
        #  Convert the randomForest predictions to an image
        #
        ######################################################################################################

        # Load CSV file into the Geodatabase
        # The CSV file contains the randomForest predictions
        arcpy.AddMessage('Importing CSV to Geodatabase')
        arcpy.TableToTable_conversion(outputtext,geodatabase,'join_table')
        arcpy.AddMessage('Done Importing')
        arcpy.AddMessage('Running AddIndex')
        arcpy.AddIndex_management(geodatabase+'/join_table','FID;responses','ind')
        arcpy.AddMessage('Done AddIndex')

        # Joining the CSV file to the segments

        arcpy.AddMessage('Joining the CSV and the shapefile')
        segment_fl = "seg_temp"
        arcpy.MakeFeatureLayer_management(shapefile,segment_fl)
        arcpy.AddJoin_management(segment_fl,FIDfield,geodatabase+'/join_table','FID')
        arcpy.AddMessage('Done Joining')
        arcpy.AddMessage('Exporting to temporary Feature Class')
        temp_poly = geodatabase +'/temp_polygon_10_1'
        arcpy.CopyFeatures_management(segment_fl,temp_poly)
        
        #Add a field to rescale the continuous field - floats are slow and huge!
        #arcpy.AddField_management(temp_poly, "cc_Int", "SHORT")
        #arcpy.CalculateField_management(temp_poly, "cc_Int", '!join_table_responses!', "PYTHON_9.3")
        
        # Creating the Raster

        arcpy.AddMessage('Creating Raster')
        arcpy.PolygonToRaster_conversion(temp_poly,'join_table_responses',outputimg,'','',CellSize)
        arcpy.AddMessage('Done Creating Raster')
        arcpy.AddMessage('Cleaning Up')
        arcpy.RemoveIndex_management(geodatabase + '/join_table',['ind'])
        arcpy.AddMessage('Building Pyramids')
        arcpy.BuildPyramids_management(outputimg)
        arcpy.AddMessage('Deleting Temporary Feature Class')
        arcpy.Delete_management(temp_poly)
        os.remove(outputtext)
        arcpy.AddMessage('Done')

else:
        arcpy.AddMessage('Cannot run R')
