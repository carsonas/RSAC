import arcpy, os, subprocess, datetime

##################################################################################
#Input parameters
#Only edit this section
##################################################################################
#The vector stream network to be ordered.  Use geodatabase feature class
inLine = "C:/Users/castam/Desktop/runNHDorder/NHDH_NE_order2.gdb/NHDFlowline_albers_repbasin_v2"

#The workspace (geodatabase) where the inLine exists
workspace = "C:/Users/castam/Desktop/runNHDorder/NHDH_NE_order2.gdb"

#The output location (folder) where things will be written to
outputFolder = "C:/Users/castam/Desktop/runNHDorder/"

#The name of the output file.  Needs to be a .csv.  Do not include a full path.
outputTable = "NHD_Flowline_Albers_connections.csv"

#The template R script full path to "OrderStreamTemplate.R"
TemplateScript = "M:/TRB/Deliverables/Scripts/OrderStreamTemplate.R"

##################################################################################
#Custom Functions
##################################################################################
time1 = datetime.datetime.now()
def deleteFields(inFC, inList):
	fields = arcpy.ListFields(inFC)
	keepFields = inList #["OBJECTID","Shape","FTYPE","FCODE","Shape_Length","Sorder","lineName"]
	dropFields = [x.name for x in fields if x.name not in keepFields]
	if len(dropFields)>0:
		arcpy.DeleteField_management(inFC,dropFields)

#Function for adding addition intersections to the table
def additionalIntersections(inJoined, outJoined, inEnd, previousJoinName):
	#delete end vertices that have already been joined
	existingValues = []

	with arcpy.da.SearchCursor(inJoined,[previousJoinName]) as cursor:
		for row in cursor:
			if row[0] is not None:
				existingValues.append(row[0])
	del cursor
	
	if len(existingValues) == 0:
		return 1
	with arcpy.da.UpdateCursor(inEnd,["ORIG_FID"]) as cursor2:
		for row in cursor2:
			if row[0] in existingValues:
				cursor2.deleteRow()
	del cursor2
	
	#Spatial Join the next set
	arcpy.SpatialJoin_analysis(inJoined,inEnd,outJoined,"JOIN_ONE_TO_ONE", "KEEP_ALL")
	return 0

##################################################################################
#Set stuff up
##################################################################################
arcpy.env.workspace = workspace
arcpy.env.overwriteOutput = True
##################################################################################
#Start intersecting
##################################################################################
#Make copy of table with Ftype
jt2 = "jt2"
arcpy.TableToTable_conversion(inLine,workspace,jt2,'',)
##################################################################################
#Start intersecting
##################################################################################
#Delete fields first to simplify
deleteFields(inLine,["OBJECTID","FType","Shape","Shape_Length"])
#Make copy of table with Ftype
jt2 = "jt2"
arcpy.TableToTable_conversion(inLine,workspace,jt2)

#Delete the rest of the fields
deleteFields(inLine,["OBJECTID","Shape","Shape_Length"])

#Get start vertex
startV = inLine + "_startVertex"
arcpy.FeatureVerticesToPoints_management(inLine,startV,"Start")

#Get end vertex
endV = inLine + "_endVertex"
arcpy.FeatureVerticesToPoints_management(inLine,endV,"END")

#Spatial Join initial
firstJoin = inLine + "_1"
arcpy.SpatialJoin_analysis(startV,endV,firstJoin,"JOIN_ONE_TO_ONE", "KEEP_ALL")

##################################################################################
#Do the rest of the features
##################################################################################
#Set up interators
count = 99
i = 2
nextJoin = "blah"

#Set up while loop to go through until there are no more joins possible
while count != 0:
	nextJoin = inLine + "_" + str(i)
	print nextJoin
	#Get the current last field
	allFields = arcpy.ListFields(firstJoin)
	
	#Call function to start adding additional joins
	test = additionalIntersections(firstJoin, nextJoin, endV, allFields[-1].name)
	
	#if the additionalIntersections function returns a 1, break out of the script because there are no more joins to make
	if test == 1:
		nextJoin = inLine + "_" + str(i - 1)
		break
	
	#A backup for checking to make sure there are endpoints to intersect
	count = int(arcpy.GetCount_management(endV).getOutput(0))
	
	#reset the current table
	firstJoin = nextJoin
	i += 1

#Export the final table
arcpy.TableToTable_conversion(nextJoin,outputFolder,outputTable)

######################################################################################################
#
#  This part transitions to running R to calculate Strahler order
#
######################################################################################################
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
	
print "R Executable"
print Rexe

######################################################################################################
#
#  Create new script
#
######################################################################################################
#First prep lines to be written
inFile = outputTable.split(".")[0] + ".dbf"
outFile = inLine.split("/")[-1] + "_strahler.csv"
RfileToRun = outputFolder + inLine.split("/")[-1] + "_strahler.R"

ScriptLines = []
ScriptLines.append('workspace = "' + outputFolder + '"\n')
ScriptLines.append('inFile = "' + inFile + '"\n')
ScriptLines.append('outFile = "' + outFile + '"\n')


newRscript = RfileToRun
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
		
	#########################################################################
	#Add the new table to the gdb and export as new geodatabase feature class
	#########################################################################
		
        #import csv
        print "importing table"
        arcpy.TableToTable_conversion(outFile,workspace,'join_table')
        print "adding index"
        arcpy.AddIndex_management(workspace+'/join_table','StreamID;Order_','ind')
        arcpy.AddIndex_management(workspace+'/jt2','OBJECTID;FType','ind2')
        	
        #Join table to lines
        print "Joining"
        segment_fl = "seg_temp"
        arcpy.MakeFeatureLayer_management(inLine,segment_fl)
        arcpy.AddJoin_management(segment_fl,"OBJECTID",workspace+'/join_table','StreamID')
        arcpy.AddJoin_management(segment_fl,"OBJECTID",workspace+'/jt2','OBJECTID')	
        #Export the finished product
        print "Exporting ordered network"
        arcpy.CopyFeatures_management(segment_fl,inLine + "_strahler")

print datetime.datetime.now() - time1
