import arcpy, os

#Parameters
baseDir = "W:/Processing_Test4/HUC8_10m"
resolution = 10
wholeDEM = "W:/10_dem_albers.img"
NHDshp = "W:/streamorder/NHD_UTAH.gdb/NHD_Flowline_Albers_natural_strahler"
slopeRes = 9
slopeThresh = 7
snapdistance = 30
HACheights = [0.2,0.3,0.3,0.3,0.5,1,2,3.6,5.9]

FID_list = range(0,106)
print FID_list

for FID in FID_list:
	
	folder = "FID_" + str(FID)
	print(folder)
	
	#test to see if this directory has been worked through
	testText = baseDir + "/" + folder + "/" + "startFile.txt"
	if not os.path.isfile(testText):
	
		#Create testText file
		OutputScript = open(testText,'w')
		OutputScript.writelines(os.environ['COMPUTERNAME'])
		OutputScript.close()
	
		NHDsnappedStream = "WBDHU8_" + str(FID) + "_" + str(resolution) + "m_Drainage_Network_NHD_snapped_natural.img"
		print(NHDsnappedStream)
		
		#create working directory
		workingDir = baseDir + "/" + folder + "/VB_Processing/snap_natural"
		print workingDir
		if not os.path.exists(workingDir):
			os.makedirs(workingDir)
		
		#get boundary
		boundary = baseDir + "/" + folder + "/WBDHU8_Albers_" + str(FID) + ".shp"
		
		###########################################################################################
		#Workspace and Environments
		###########################################################################################
		arcpy.env.workspace = workingDir
		arcpy.env.snapRaster = wholeDEM
		arcpy.env.cellSize = wholeDEM
		arcpy.env.overwriteOutput = True
		arcpy.env.pyramid = "NONE"
		arcpy.CheckOutExtension("Spatial")
		
		###########################################################################################
		#Clip DEM
		###########################################################################################
		DEM = "WBDHU8_Albers_" + str(FID) + "_"+ str(resolution) + "m_dem_natural.img"
		arcpy.Clip_management(wholeDEM,"#",DEM,boundary,"#","ClippingGeometry")
		arcpy.env.extent = boundary
		print "finished DEM"
		###########################################################################################
		#Clip NHD
		###########################################################################################
		filegdb = workingDir + "/NHD_natural_" + str(FID) + ".gdb"
		if not os.path.exists(filegdb):
			arcpy.CreateFileGDB_management(workingDir,"NHD_natural_" + str(FID) + ".gdb")
		
		NHD = filegdb + "/" + "NHD_" + str(FID)
		arcpy.Clip_analysis(NHDshp,boundary,NHD)	
		
		#Test to see if any features are present
		featureCount = int(arcpy.GetCount_management(NHD).getOutput(0))
		if featureCount > 0:
			###########################################################################################
			#Convert NHD to raster
			###########################################################################################
			NHDRast = "WBDHU8_" + str(FID) + "_" + str(resolution) + "m_Drainage_Network_NHD_notsnapped_natural.img"
			arcpy.PolylineToRaster_conversion(NHD,"Order_",NHDRast)

			###########################################################################################
			#Get accumulation raster
			###########################################################################################
			#Fill DEM
			DEMfill = arcpy.sa.Fill(DEM)

			#Get flow direction raster
			flowdr = arcpy.sa.FlowDirection(DEMfill)

			#Get flow accumulation raster
			flowaccum = arcpy.sa.FlowAccumulation(flowdr)
			flowaccum.save("WBDHU8_Albers_" + str(FID) + "_" + str(resolution) + "m_dem_Flow_Accumulation_natural.img")
			del flowdr
			###########################################################################################
			#Snap pour point
			###########################################################################################
			#Snap pour point to highest accumulation pixel within snapdistance distance
			snappedPour = arcpy.sa.SnapPourPoint(NHDRast,flowaccum,snapdistance,"VALUE")
			#snappedPour.save("tempsnappedpour.img")
			del flowaccum
			###########################################################################################
			#Get Slope and Smooth slope	 
			###########################################################################################
			#Generate slope
			slope = arcpy.sa.Slope(DEMfill,"DEGREE")

			#Get focal window slope
			slopeFocal = arcpy.sa.FocalStatistics(slope,arcpy.sa.NbrCircle(slopeRes,"CELL"),"MEAN")
			#slopeFocal.save("tempslope.img")
			del slope
			###########################################################################################
			#Combine snapped and slopebinary
			###########################################################################################
			snappedFixed = arcpy.sa.Con(slopeFocal<slopeThresh,NHDRast,snappedPour)
			snappedFixed.save(NHDsnappedStream)
			del snappedPour
			del slopeFocal
			del snappedFixed
			###########################################################################################
			#Generate HAC
			###########################################################################################
			slope_radians = baseDir + "/" + folder + "/VB_Processing/WBDHU8_Albers_" + str(FID) + "_" + str(resolution) + "m_dem_Slope_Radians_notshifted.img"
			if not os.path.exists(slope_radians):
				slpRad = arcpy.sa.Slope(DEMfill,"PERCENT_RISE")/100.0
				slpRadSmth = arcpy.sa.FocalStatistics(slpRad,arcpy.sa.NbrCircle(3,"CELL"),"MEAN")
				slpRadSmth.save(slope_radians)
				del slpRad
			
			del DEMfill 
			
			#Get max order for the current HUC8
			maxOrder = int(arcpy.GetRasterProperties_management(NHDsnappedStream,"MAXIMUM").getOutput(0))
			
			for i in range(1,maxOrder + 1):
				print i
				limitOrder = arcpy.sa.SetNull(NHDsnappedStream,NHDsnappedStream,'NOT VALUE =' + str(i))
				OrderHACname = "HAC_order_" + str(i) + ".img"
				OrderHAC = arcpy.sa.CostDistance(limitOrder,slope_radians,HACheights[i-1])
				OrderHAC.save(OrderHACname)
			
			#Mosaic based on minimum height above channel
			HACs = arcpy.ListRasters("HAC_order_*.img")
			Cellmin = arcpy.sa.CellStatistics(HACs,"MINIMUM","DATA")
			binaryHAC = arcpy.sa.Reclassify(Cellmin, "Value",arcpy.sa.RemapRange([[0,max(HACheights),1]]))
			binaryHACname = baseDir + "/" + folder + "/VB_Processing/" + NHDsnappedStream.split(".")[0] + "_Binary_Height_Above_Channel_natural.img"
			binaryHAC.save(binaryHACname)
			del Cellmin
			del binaryHAC
			
			for HAC in HACs:
				arcpy.Delete_management(HAC)
	
			#Write finished text file
			#Final Text file
			finalText = baseDir + "/" + folder + "/" + "endFile.txt"
			#Create testText file
			OutputScript2 = open(finalText,'w')
			OutputScript2.writelines(os.environ['COMPUTERNAME'])
			OutputScript2.close()
	
	








