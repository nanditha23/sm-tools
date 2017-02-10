from DBUtils.PooledDB import PooledDB               
import psycopg2
#from shapely.geometry import Point
from datetime import datetime
from pyproj import Proj

#password = 5M_S1mM0bility
#DSN = '''dbname=simmobility user=postgres password=5M_S1mM0bility host=172.25.184.48'''
DSN = '''dbname=simmobility user=postgres password=5M_S1mM0bility host=172.25.184.48'''
#DSN = '''dbname=SimMobility_DB user=postgres password=5M_S1mM0bility host=172.25.184.11'''
DSN_HPC = '''dbname=simmobility user=postgres password=d84dmiN host=172.25.184.156'''
SQL_GET_TABLE = '''SELECT table_schema,table_name 
FROM information_schema.tables
ORDER BY table_schema,table_name'''
SQL_getvehids = '''select distinct vehicle_num from %s where to_date(to_char(report_timestamp, 'YYYY/MM/DD'), 'YYYY/MM/DD') = '%s' '''
#SQL_getgpslog = '''select vehicle_num, driver_id,report_timestamp, x_lon, y_lat, speed,status from %s 
#    where vehicle_num='%s' and  to_date(to_char(report_timestamp, 'YYYY/MM/DD'), 'YYYY/MM/DD') = '%s' order by vehicle_num, report_timestamp'''
SQL_getgpslog = '''select vehicle_num, driver_id,report_timestamp, x_lon, y_lat, speed,status from %s order by vehicle_num, report_timestamp'''
SQL_taxistand = '''Select lon,lat,type_cd_de,shapeid from supply.taxistands_lat_lon where type_cd_de ='%s' or type_cd_de ='%s' ''' 

Pool = PooledDB(psycopg2, dsn=DSN)

def get_all_tables():
	## get all tables from Comfort database
	tables = []
	try:
		conn = Pool.dedicated_connection()
		curs = conn.cursor()
		curs.execute(SQL_GET_TABLE)
		for row in curs:
			if row[0] == 'gps' and len(row[1])>20 and str(row[1]).startswith("comfort"):
				tables.append(row[0]+'.'+row[1])
	finally:
		print "failed"
		#conn.close()       
	return tables

#This function gets all the taxi stands
def get_all_Taxi_Stand():
	taxiStands =[]
	taxiStops = []
	Pool1 = PooledDB(psycopg2, dsn=DSN_HPC)
	conn = Pool1.dedicated_connection()
	try:
		Pool1 = PooledDB(psycopg2, dsn=DSN_HPC)        
		conn = Pool1.dedicated_connection()
		curs = conn.cursor()
		proj = Proj(init = "epsg:3414")
		taxiStand = 'TAXI STAND'
		taxiStop = 'TAXI STOP'
		curs.execute(SQL_taxistand%(taxiStand,taxiStop))
		for row in curs:
			XY = proj(float(row[0]),float(row[1]))
			coor = [XY[0],XY[1]]
			#print "taxi stand coordinate is"
			#print coor
			#print str(row[2])
			if str(row[2]) == 'TAXI STAND':
				taxiStands.append((coor,int(row[3])))
			elif str(row[2]) == 'TAXI STOP':
				taxiStops.append((coor,int(row[3])))
	finally:
		conn.close()
	return taxiStands,taxiStops

def writeIntoFile(finalList,fp):
	#print "writing to file"
	printList = str(finalList).strip('[')
	printList = str(printList).strip(']')
	#print "before printing"
	printList = printList.replace("'","")
	#print printList
	#print "after printing"
	fp.write(printList+"\n")

#This function handles the drop off
#This function is called whenevr there is a state other than passenger on board to check its a drop off
#based on previous POB counts
def is_Drop_Off(prevPOB,POBCount,freeRows,noDriverRows,freeRowsStartIndex,freeRowsEndIndex,noDriverRowsStartIndex,noDriverRowsEndIndex,start_driver_id,driver_id,fp,rowNum,listOfPrevsPOB):
	if prevPOB == True:
		if POBCount >1:
			rowIndex = rowNum - len(listOfPrevsPOB)
			# append all break and POB row previously to no driver rows if driver id is not present or write them to file
			for i in range (0,len(listOfPrevsPOB)):
				(storedList,st_driver_id,end_driver_id) = listOfPrevsPOB[i]
				if storedList[6] == 'POB':
					print "6th element is"
					print storedList[6]
					storedList.append("DROP OFF")
				else:
					storedList.append("CRUISING")
					#if driver_id == "" or driver_id == " ":
						#listOfPrevsPOB[i].append(
				if storedList[1] =="" or storedList[1] == " ":
					if noDriverRowsStartIndex == -1:
						noDriverRowsStartIndex = rowIndex
					noDriverRowsEndIndex = rowIndex
					noDriverRows.append(storedList)
				else:
					freeRows = mergeNoDriverRowsIntoFreeRows(freeRows,noDriverRows,freeRowsStartIndex,freeRowsEndIndex,noDriverRowsStartIndex,noDriverRowsEndIndex,st_driver_id,end_driver_id,fp)
					noDriverRowsEndIndex = -1
					noDriverRowsStartIndex = -1
					noDriverRows =[]
					#start_driver_id = driver_id	
					print storedList
					writeIntoFile(storedList,fp)
				rowIndex = rowIndex +1
			#row num to be updated
			return (freeRows,noDriverRows,freeRowsStartIndex,freeRowsEndIndex,noDriverRowsStartIndex,noDriverRowsEndIndex,start_driver_id,driver_id,fp,listOfPrevsPOB,rowNum,True)
		else:
			# just ignore previous POB row ,may be error
			rowIndex = rowNum  - len(listOfPrevsPOB)			
			for i in range (0,len(listOfPrevsPOB)):
				(storedList,st_driver_id,end_driver_id) = listOfPrevsPOB[i]
				print "sixth elements"+ " "+storedList[6]			
				#print storedList[6]
				if storedList[6] == 'POB':
					print "need to discard this POB"
					rowIndex = rowIndex - 1
					continue
				else:
					storedList.append("CRUISING")
				if storedList[1] =="" or storedList[1] == " ":
					if noDriverRowsStartIndex == -1:
						noDriverRowsStartIndex = rowIndex
					noDriverRowsEndIndex = rowIndex
					noDriverRows.append(storedList)
				else:
					freeRows = mergeNoDriverRowsIntoFreeRows(freeRows,noDriverRows,freeRowsStartIndex,freeRowsEndIndex,noDriverRowsStartIndex,noDriverRowsEndIndex,st_driver_id,end_driver_id,fp)
					noDriverRowsEndIndex = -1
					noDriverRowsStartIndex = -1
					noDriverRows =[]
					#start_driver_id = driver_id	
					print storedList
					writeIntoFile(storedList,fp)
				rowIndex = rowIndex +1
			rowNum = rowNum -1
			#write all the busy states to file if driver id is present
			#rowNum to be updated
			return freeRows,noDriverRows,freeRowsStartIndex,freeRowsEndIndex,noDriverRowsStartIndex,noDriverRowsEndIndex,start_driver_id,driver_id,fp,listOfPrevsPOB,rowNum,False
	else:
		print "No POB"
		print rowNum
		return freeRows,noDriverRows,freeRowsStartIndex,freeRowsEndIndex,noDriverRowsStartIndex,noDriverRowsEndIndex,start_driver_id,driver_id,fp,listOfPrevsPOB,rowNum,False

#This function checks for pick up
#Whenever is the second POB in sequence then the first one is checked for pickup.That is if the POB count considering the previous POB is 1
#then its a pickup
def isPickUp(prevPOB,POBCount,freeRows,noDriverRows,freeRowsStartIndex,freeRowsEndIndex,noDriverRowsStartIndex,noDriverRowsEndIndex,start_driver_id,driver_id,fp,rowNum,listOfPrevsPOB):
	if  POBCount == 1 and prevPOB == True:
		#prevList.append("PICKUP")
		rowIndex = rowNum - len(listOfPrevsPOB)
		# append all break and POB row previously to no driver rows if driver id is not present or write them to file
		for i in range (0,len(listOfPrevsPOB)):
			(storedList,st_driver_id,end_driver_id) = listOfPrevsPOB[i]
			if storedList[6] == 'POB':
				storedList.append("PICKUP")
			else:
				storedList.append("OCCUPIED")
			if storedList[1] =="" or storedList[1] == " ":
				if noDriverRowsStartIndex == -1:
					noDriverRowsStartIndex = rowIndex
				noDriverRowsEndIndex = rowIndex
				noDriverRows.append(storedList)
			else:
				freeRows = mergeNoDriverRowsIntoFreeRows(freeRows,noDriverRows,freeRowsStartIndex,freeRowsEndIndex,noDriverRowsStartIndex,noDriverRowsEndIndex,st_driver_id,end_driver_id,fp)
				noDriverRowsEndIndex = -1
				noDriverRowsStartIndex = -1
				noDriverRows =[]
				#start_driver_id = driver_id	
				print storedList
				writeIntoFile(storedList,fp)
			rowIndex = rowIndex +1
		return prevPOB,POBCount,freeRows,noDriverRows,freeRowsStartIndex,freeRowsEndIndex,noDriverRowsStartIndex,noDriverRowsEndIndex,start_driver_id,driver_id,fp,rowNum,True
	else:
		return prevPOB,POBCount,freeRows,noDriverRows,freeRowsStartIndex,freeRowsEndIndex,noDriverRowsStartIndex,noDriverRowsEndIndex,start_driver_id,driver_id,fp,rowNum,False

#If there is POB in sequence 
def isOccupied(prevPOB,POBCount,freeRows,noDriverRows,freeRowsStartIndex,freeRowsEndIndex,noDriverRowsStartIndex,noDriverRowsEndIndex,start_driver_id,driver_id,fp,rowNum,listOfPrevsPOB):
	if prevPOB == True  and POBCount>1:		
		#prevList.append("OCCUPIED")
		rowIndex = rowNum - len(listOfPrevsPOB)
		for i in range (0,len(listOfPrevsPOB)):
			(storedList,st_driver_id,end_driver_id) = listOfPrevsPOB[i]
			if storedList[6] == 'POB':
				storedList.append("OCCUPIED")
			else:
				storedList.append("OCCUPIED")
			if storedList[1] =="" or storedList[1] == " ":
				if noDriverRowsStartIndex == -1:
					noDriverRowsStartIndex = rowIndex
				noDriverRowsEndIndex = rowIndex
				noDriverRows.append(storedList)
			else:
				freeRows = mergeNoDriverRowsIntoFreeRows(freeRows,noDriverRows,freeRowsStartIndex,freeRowsEndIndex,noDriverRowsStartIndex,noDriverRowsEndIndex,st_driver_id,end_driver_id,fp)
				noDriverRowsEndIndex = -1
				noDriverRowsStartIndex = -1
				noDriverRows =[]
				#start_driver_id = driver_id	
				#print storedList
				writeIntoFile(storedList,fp)
			rowIndex = rowIndex+1
		return (prevPOB,POBCount,freeRows,noDriverRows,freeRowsStartIndex,freeRowsEndIndex,noDriverRowsStartIndex,noDriverRowsEndIndex,start_driver_id,driver_id,fp,rowNum,True)
	else:
		return (prevPOB,POBCount,freeRows,noDriverRows,freeRowsStartIndex,freeRowsEndIndex,noDriverRowsStartIndex,noDriverRowsEndIndex,start_driver_id,driver_id,fp,rowNum,False)
	


       
def get_all_vehicle_id(table):
    vehicles = []
    conn =""
    try:
        conn = Pool.dedicated_connection()
        curs = conn.cursor()
        curs.execute(SQL_getvehids%(table,'2010-08-02'))
        for row in curs:
            #print row[0]
            vehicles.append(row[0])
        print len(vehicles),'vehicle_id loaded.'
    finally:
        conn.close()
    return vehicles

def is_Taxi_Stand(x,y,taxiStands):
	#print "in is Taxi Stand function"	
	if x == "" or x == " " or x == None or y == "" or y == " " or y == None: 
		#print "incorrect taxi stand coordinate"    	
		return False;
	totalStands = len(taxiStands)
	minDis = -1
	minDisStandId = -1
	for i in range(0,totalStands):
		#print "x coordinate is" +str(x)
		#print "y coordinate is" +str(y)
		#print "taxi stand coor"
		#print taxiStands[i]
		(stand,standId) = taxiStands[i]
		#print "stand coordiantes are"
		#print stand[0]
		#print stand[1]
		dis = (x-(stand[0]))*(x-(stand[0])) + (y-(stand[1]))*(y-(stand[1]))
		#print "distance from taxi Stand is"
		#print dis		
		if dis<=25:
			#print "location at taxi Stand"
			if minDis == -1 or dis<minDis:
				minDis = dis
				minDisStandId = standId
			
	return minDisStandId

def is_Taxi_Stop(x,y,taxiStops):
	#print "in is Taxi Stand function"	
	if x == "" or x == " " or x == None or y == "" or y == " " or y == None: 
		#print "incorrect taxi stand coordinate"    	
		return False;
	totalStops = len(taxiStops)
	minDis = -1
	minDisStopId = -1
	for i in range(0,totalStops):
		#print "x coordinate is" +str(x)
		#print "y coordinate is" +str(y)
		#print "taxi stand coor"
		#print taxiStands[i]
		(stop,stopId) = taxiStops[i]
		dis = (x-(stop[0]))*(x-(stop[0])) + (y-(stop[1]))*(y-(stop[1]))
		#print "distance from taxi Stand is"
		#print dis		
		if dis<=25:
			#print "location at taxi Stop"
			if minDis == -1 or dis<minDis:
				minDis = dis
				minDisStopId = stopId
			
	return minDisStopId

    

def convertFreeRowsTo(rows,isTaxiStand):
	size = len(rows)
	#print size
	for i in range (0,size):
		if len(rows[i]) == 10:
			continue
		if isTaxiStand == True:
			rows[i].append("DRIVE TO DESTINATION")
			#print rows[i]
		else:
			rows[i].append("CRUISING")
			#print rows[i]
	return rows

def mergeCruisingRowsNoDriverRows(freeRows,noDriverRows,freeRowsStartIndex,freeRowsEndIndex,noDriverRowsStartIndex,noDriverRowsEndIndex,fp):
	if 	len(freeRows) == 0 or freeRowsStartIndex == -1 or freeRowsEndIndex ==-1:
		return noDriverRows

	#print "no driver rows"
	#print noDriverRows
	#print "done printing no driver rows"
	if 	noDriverRowsStartIndex == -1 and noDriverRowsEndIndex == -1:
		missingvalue = ""
		#print "length of free rows" + str(len(freeRows))
		for i in range (0,len(freeRows)):
			#noDriverRows[i][1] = missingValue
			#print freeRows[i]
			writeIntoFile(freeRows[i],fp)
			#print "finished writing"

	elif freeRowsStartIndex < noDriverRowsStartIndex  and freeRowsEndIndex >= noDriverRowsStartIndex and freeRowsEndIndex <= noDriverRowsEndIndex:
		#merge the first section rows into free state rows
		diff =  noDriverRowsStartIndex - freeRowsStartIndex 
		#status = freeRows[0][9]		
		noDriverRowsSec1 = []
		print "the diff is "
		print diff		
		print freeRowsStartIndex
		print noDriverRowsStartIndex
		for i in range (0,diff):
			#noDriverRows.append(status)
			#print "printing first section"
			#print freeRows[i]
			writeIntoFile(freeRows[i],fp)
		totallengthofNoFreeRows = freeRowsEndIndex - freeRowsStartIndex +1
		for i in range (0,totallengthofNoFreeRows-diff):
			print "adding remaining section"
			#noDriverRows[i].append(status) 
			print noDriverRows[i]
			print "printed remaining section"
		return noDriverRows
	elif freeRowsStartIndex >= noDriverRowsStartIndex and freeRowsStartIndex <= noDriverRowsEndIndex and freeRowsEndIndex>=freeRowsStartIndex and freeRowsEndIndex <= noDriverRowsEndIndex:
		diff = freeRowsStartIndex - noDriverRowsStartIndex
		#print "complete overlap"
		for i in range (diff,diff+freeRowsEndIndex - freeRowsStartIndex +1):
			#noDriverRows[i].append(status)
			print noDriverRows[i]
	else:
		print "unfortunately in else part of merge no driver rows into free rows,something seriously wrong"
		for i in range (0,freeRowsStartIndex - freeRowsEndIndex +1):
			#noDriverRows[i][1] = missingValue
			#"other condition"
			writeIntoFile(freeRows[i],fp)
			#print freeRows[i]
	return noDriverRows

def mergeNoDriverRowsIntoFreeRows(freeRows,noDriverRows,freeRowsStartIndex,freeRowsEndIndex,noDriverRowsStartIndex,noDriverRowsEndIndex,start_driver_id,driver_id,fp):
	if noDriverRowsStartIndex == -1 or noDriverRowsEndIndex == -1 or len(noDriverRows) == -1:
		return freeRows	
	missingvalue =""
	print "printing indexs"
	print freeRowsStartIndex
	print freeRowsEndIndex
	print noDriverRowsStartIndex
	print noDriverRowsEndIndex
	if start_driver_id != driver_id:
		missingvalue = "-1"
	else:
		missingvalue = start_driver_id
					
	if 	freeRowsStartIndex == -1 and freeRowsEndIndex == -1:		
		for i in range (0,len(noDriverRows)):

			#print "start end driver ids are"
			#print start_driver_id
			#print end_driver_id
			#print missingvalue			
			if (noDriverRows[i][6] == "OUT OF SERVICE" or noDriverRows[i][6] == "OUT OF SERVICE") and start_driver_id == driver_id:
				noDriverRows[i][1] = "-1"
			else:
				noDriverRows[i][1] = missingvalue
				if missingvalue == "-1":
					noDriverRows[i][9] = "OUT OF SERVICE"
			print noDriverRows[i]	
			writeIntoFile(noDriverRows[i],fp)
	
	#overlap
	elif noDriverRowsStartIndex < freeRowsStartIndex  and noDriverRowsEndIndex >= freeRowsStartIndex and noDriverRowsEndIndex <= freeRowsEndIndex:
		print "merge the first section rows into free state rows"
		diff = freeRowsStartIndex - noDriverRowsStartIndex
		print diff
		print noDriverRowsStartIndex
		print freeRowsStartIndex
		print noDriverRowsEndIndex
		print freeRowsEndIndex		
		noDriverRowsSec1 = []		
		for i in range (0,diff):
			if (noDriverRows[i][6] == "OUT OF SERVICE" or noDriverRows[i][6] == "OUT OF SERVICE") and start_driver_id == driver_id:
				noDriverRows[i][1] = "-1"
			else:
				noDriverRows[i][1] = missingvalue
				if missingvalue == "-1":
					noDriverRows[i][9] = "OUT OF SERVICE"
			print noDriverRows[i]
			writeIntoFile(noDriverRows[i],fp)

		# the overlap inside section
		totallengthofNoDriverRows = noDriverRowsEndIndex - noDriverRowsStartIndex +1		
		for i in range (0,totallengthofNoDriverRows-diff):
			freeRows[i][1] = missingvalue
			if missingvalue == "-1":
				freeRows[i].append("OUT OF SERVICE") 
		return freeRows

	#complete overlap
	elif noDriverRowsStartIndex >= freeRowsStartIndex and noDriverRowsStartIndex <= freeRowsEndIndex and noDriverRowsEndIndex>=freeRowsStartIndex and noDriverRowsEndIndex <= freeRowsEndIndex:
		diff = noDriverRowsStartIndex - freeRowsStartIndex	
		print "complete overlap"
		print start_driver_id
		for i in range (diff,diff+noDriverRowsEndIndex - noDriverRowsStartIndex +1):
			freeRows[i][1] = missingvalue
			if missingvalue == "-1":
				freeRows[i].append("OUT OF SERVICE")
	else:	
		print "unfortunately in else part of merge no driver rows into free rows,something seriously wrong"
		for i in range (0,len(noDriverRows)):
			if (noDriverRows[i][6] == "OUT OF SERVICE" or noDriverRows[i][6] == "OUT OF SERVICE") and start_driver_id == driver_id:
				noDriverRows[i][1] = "-1"
			else:
				noDriverRows[i][1] = missingvalue
			writeIntoFile(noDriverRows[i],fp)
			print noDriverRows[i]
	return freeRows

def calCulateTimeDifference(time1,time2):
	print time1
	print time2	
	datetimefields1 = time1.split(" ")
	datetimeval1 = datetimefields1[0]
	yearmonthday1 = datetimeval1.split("-")
	day1 = int(yearmonthday1[2])
	hhmmsec1 = datetimefields1[1]
	hourminsec1 = hhmmsec1.split(":")
	hours1 = int(hourminsec1[0])
	mins1 = int(hourminsec1[1])
	secs1= int(hourminsec1[2])

	datetimefields2 = time2.split(" ")
	datetimeval2 = datetimefields2[0]
	yearmonthday2 = datetimeval2.split("-")
	day2 = int(yearmonthday2[2])
	hhmmsec2 = datetimefields2[1]
	hourminsec2 = hhmmsec2.split(":")
	hours2 = int(hourminsec2[0])
	mins2 = int(hourminsec2[1])
	secs2 = int(hourminsec2[2])
	#if time == '2010-08-27 06:36:54':
	print "time differnce  " + str((((day1-day2)*60*60*24) + ((hours1-hours2)*60*60) + ((mins1-mins2)*60) + (secs1-secs2)))
		#print (((day1-day2)*60*60*24) - ((hours1-hours2)*60*60) - ((mins1-mins2)*60) - (secs1-secs2))
	return (((day1-day2)*60*60*24) + ((hours1-hours2)*60*60) + ((mins1-mins2)*60) + (secs1-secs2))
				 
def get_trips_gps_log(i,taxiStands,taxiStops):
	trips_log = []
	proj = Proj(init = "epsg:3414")
	freeRows =[]
	noDriverRows = []
	freeRowsStartIndex = -1
	freeRowsEndIndex = -1
	noDriverRowsStartIndex = -1
	noDriverRowsEndIndex = -1
	driver_id = ""
	start_driver_id = ""
	veh_id = ""
	prevPOB = False
	listOfPrevsPOB = []
	POBCount = 0
	prevTimeOfAcceptedRow = ""
	#proj = Proj(init = "epsg:32648")
	try:
		#conn = psycopg2.connect(DSN)
		conn =""
		with open ("testwrite.csv","w") as fp:
			conn = Pool.dedicated_connection()
			curs = conn.cursor()
			#table = "externaldata.sampledata_stage0to1_final"
			#table = "externaldata.sampledata"
			table = "taxigps.comfort_gps_logs_20100803_20100804"
			#table = "externaldata.comfort_gps_logs_20100801_20100831"
			#table = "gps.comfort_gps_logs_20100803_20100804"
			curs.execute(SQL_getgpslog %(table)) #, veh_id,'2010-08-02'))            
			prevstatus = "";			
			start_driver_id = ""			
			rowNum = -1
			prev_veh_id = ""
			prevList = []
			for row in curs:
				veh_id = row[0]
				if veh_id != prev_veh_id:
					# reset the driver viables
					prevPOB,POBCount,freeRows,noDriverRows,freeRowsStartIndex,freeRowsEndIndex,noDriverRowsStartIndex,noDriverRowsEndIndex,start_driver_id,driver_id,fp,rowNum,ispickup = isPickUp(prevPOB,POBCount,freeRows,noDriverRows,freeRowsStartIndex,freeRowsEndIndex,noDriverRowsStartIndex,noDriverRowsEndIndex,start_driver_id,driver_id,fp,rowNum,listOfPrevsPOB)
					if ispickup == False:
						prevPOB,POBCount,freeRows,noDriverRows,freeRowsStartIndex,freeRowsEndIndex,noDriverRowsStartIndex,noDriverRowsEndIndex,start_driver_id,driver_id,fp,rowNum,isoccupied = isOccupied(prevPOB,POBCount,freeRows,noDriverRows,freeRowsStartIndex,freeRowsEndIndex,noDriverRowsStartIndex,noDriverRowsEndIndex,start_driver_id,driver_id,fp,rowNum,listOfPrevsPOB)				 	
						if isoccupied == False:
							# do nothing 
							listOfPrevsPOB = []
						else:
							listOfPrevsPOB = []
					else:
						listOfPrevsPOB = []
						
					for i in range (0,len(freeRows)):
						freeRows[i].append("CRUISING")
						print freeRows[i]
					noDriverRows = mergeCruisingRowsNoDriverRows(freeRows,noDriverRows,freeRowsStartIndex,freeRowsEndIndex,noDriverRowsStartIndex,noDriverRowsEndIndex,fp) 
					freeRowsStartIndex = -1
					freeRowsEndIndex = -1	
					freeRows =[]
					freeRows = mergeNoDriverRowsIntoFreeRows(freeRows,noDriverRows,freeRowsStartIndex,freeRowsEndIndex,noDriverRowsStartIndex,noDriverRowsEndIndex,start_driver_id,driver_id,fp)
					freeRows =[]
					noDriverRows = []
					freeRowsStartIndex = -1
					freeRowsEndIndex = -1
					noDriverRowsStartIndex = -1
					noDriverRowsEndIndex = -1
					start_driver_id = ""
					driver_id = ""
					lastPaymentTime = ""
					prevstatus = ""
					listOfPrevsPOB = []
					POBCount = 0
					prevPOB = False
				prev_veh_id = veh_id
				#print "rowNum is"
				#print rowNum
				
				finalList =[]
				driver_id = row[1]
				time = str(row[2])
				status = (str(row[6])).replace(" ","")
				if status == "ONCALL":
					status = "BOOKED"
				elif status == "NOSHOW":
					status = "FREE" 
				if status == "OUTOFSERVICE":
					status = "OUT OF SERVICE"					
				lon = row[3]
				lat = row[4]
				speed = row[5]
				XY = proj(lon, lat)
				rowNum = rowNum+1
				#XY = (lon,lat)	
				#print "vehicle x ,y coordinate is"
				#print XY[0]
				#print XY[1]			
				finalList.append(veh_id)
				finalList.append(driver_id)
				startTime=str(time).split(" ")[0]+" "+str(time).split(" ")[1]
				finalList.append(startTime)
				finalList.append(XY[0])
				finalList.append(XY[1])
				finalList.append(speed)
				finalList.append(status)
				taxiStandId = is_Taxi_Stand(XY[0],XY[1],taxiStands)
				taxiStopId = is_Taxi_Stop(XY[0],XY[1],taxiStops)
				finalList.append(taxiStandId)
				finalList.append(taxiStopId)
				isTaxiStand = False
				if taxiStandId != -1 or taxiStopId != -1:
					print "Got a Taxi Stand or Stop"
					isTaxiStand = True
				#print "appended data"
				if status == 'BOOKED':
					print "the current state is on call"
					freeRows,noDriverRows,freeRowsStartIndex,freeRowsEndIndex,noDriverRowsStartIndex,noDriverRowsEndIndex,start_driver_id,driver_id,fp,listOfPrevsPOB,rowNum,isDropOff = is_Drop_Off(prevPOB,POBCount,freeRows,noDriverRows,freeRowsStartIndex,freeRowsEndIndex,noDriverRowsStartIndex,noDriverRowsEndIndex,start_driver_id,driver_id,fp,rowNum,listOfPrevsPOB)
					listOfPrevsPOB = []					
					freeRows = convertFreeRowsTo(freeRows,isTaxiStand)
					noDriverRows = mergeCruisingRowsNoDriverRows(freeRows,noDriverRows,freeRowsStartIndex,freeRowsEndIndex,noDriverRowsStartIndex,noDriverRowsEndIndex,fp)
					freeRows =[]
					freeRowsStartIndex = -1
					freeRowsEndIndex = -1
					finalList.append("BOOKED")
					if driver_id =="" or driver_id == " ":
						if noDriverRowsStartIndex == -1:
							noDriverRowsStartIndex = rowNum
						noDriverRowsEndIndex = rowNum
						noDriverRows.append(finalList) 
					else:
						freeRows = mergeNoDriverRowsIntoFreeRows(freeRows,noDriverRows,freeRowsStartIndex,freeRowsEndIndex,noDriverRowsStartIndex,noDriverRowsEndIndex,start_driver_id,driver_id,fp)
						noDriverRowsEndIndex = -1
						noDriverRowsStartIndex = -1
						noDriverRows =[]
						start_driver_id = driver_id					
						print finalList
						writeIntoFile(finalList,fp)
					prevPOB = False
					POBCount = 0

				elif status == 'POB':
					print "current state is POB"
					#isPickUp(prevstatus,POBCount,freeRows,noDriverRows,freeRowsStartIndex,freeRowsEndIndex,noDriverRowsStartIndex,noDriverRowsEndIndex,start_driver_id,driver_id,fp,rowNum)
					if lastPaymentTime != "" and lastPaymentTime >= startTime:
						print "ordering of POB afetr payment"
						freeRows = convertFreeRowsTo(freeRows,isTaxiStand)
						noDriverRows = mergeCruisingRowsNoDriverRows(freeRows,noDriverRows,freeRowsStartIndex,freeRowsEndIndex,noDriverRowsStartIndex,noDriverRowsEndIndex,fp)
						freeRows =[]
						freeRowsStartIndex = -1
						freeRowsEndIndex = -1
						finalList.append("OCCUPIED")
						if driver_id =="" or driver_id == " ":
							if noDriverRowsStartIndex == -1:
								noDriverRowsStartIndex = rowNum
							noDriverRowsEndIndex = rowNum
							noDriverRows.append(finalList)
						else:
							freeRows = mergeNoDriverRowsIntoFreeRows(freeRows,noDriverRows,freeRowsStartIndex,freeRowsEndIndex,noDriverRowsStartIndex,noDriverRowsEndIndex,start_driver_id,driver_id,fp)
							noDriverRowsEndIndex = -1
							noDriverRowsStartIndex = -1
							noDriverRows =[]
							start_driver_id = driver_id					
							print finalList
							writeIntoFile(finalList,fp)
					else:
						freeRows = convertFreeRowsTo(freeRows,isTaxiStand)
						noDriverRows = mergeCruisingRowsNoDriverRows(freeRows,noDriverRows,freeRowsStartIndex,freeRowsEndIndex,noDriverRowsStartIndex,noDriverRowsEndIndex,fp)
						freeRows =[]
						freeRowsStartIndex = -1
						freeRowsEndIndex = -1
						if POBCount == 0:
							listOfPrevsPOB.append((finalList,start_driver_id,driver_id))
							POBCount = 1
						else:
							prevPOB,POBCount,freeRows,noDriverRows,freeRowsStartIndex,freeRowsEndIndex,noDriverRowsStartIndex,noDriverRowsEndIndex,start_driver_id,driver_id,fp,rowNum,ispickup = isPickUp(prevPOB,POBCount,freeRows,noDriverRows,freeRowsStartIndex,freeRowsEndIndex,noDriverRowsStartIndex,noDriverRowsEndIndex,start_driver_id,driver_id,fp,rowNum,listOfPrevsPOB)
							if ispickup == False:
								prevPOB,POBCount,freeRows,noDriverRows,freeRowsStartIndex,freeRowsEndIndex,noDriverRowsStartIndex,noDriverRowsEndIndex,start_driver_id,driver_id,fp,rowNum,isoccupied = isOccupied(prevPOB,POBCount,freeRows,noDriverRows,freeRowsStartIndex,freeRowsEndIndex,noDriverRowsStartIndex,noDriverRowsEndIndex,start_driver_id,driver_id,fp,rowNum,listOfPrevsPOB)				 	
								if isoccupied == False:
									prevPOB,POBCount,freeRows,noDriverRows,freeRowsStartIndex,freeRowsEndIndex,noDriverRowsStartIndex,noDriverRowsEndIndex,start_driver_id,driver_id,fp,rowNum,isdropoff = is_Drop_Off(prevPOB,POBCount,freeRows,noDriverRows,freeRowsStartIndex,freeRowsEndIndex,noDriverRowsStartIndex,noDriverRowsEndIndex,start_driver_id,driver_id,fp,rowNum,listOfPrevsPOB)
									listOfPrevsPOB = []									
								else:
									listOfPrevsPOB = []
									listOfPrevsPOB.append((finalList,start_driver_id,driver_id))
							else:
								listOfPrevsPOB = []
								listOfPrevsPOB.append((finalList,start_driver_id,driver_id))
							POBCount = POBCount + 1
						prevPOB = True
						if driver_id != "" and driver_id!= " ":
							start_driver_id = driver_id
								
				

				elif status == 'PAYMENT':
					print "current state is payment"
					rowIndex = rowNum - len(listOfPrevsPOB)					
					for i in range (0,len(listOfPrevsPOB)):
						print "Prev POBS are"
						print listOfPrevsPOB[i]
						(storedList,st_id,end_driver_id) = listOfPrevsPOB[i]
						if storedList[6] == 'POB':
							if POBCount ==1:
								storedList.append("PICKUP")
							else:
								storedList.append("OCCUPIED")
						else:
							storedList.append("OCCUPIED")
						if storedList[1] =="" or storedList[1] == " ":
							if noDriverRowsStartIndex == -1:
								noDriverRowsStartIndex = rowIndex
							noDriverRowsEndIndex = rowIndex
							#(storedList,st_id,driver_id) = listOfPrevsPOB[i]
							noDriverRows.append(storedList)
						else:
							freeRows = mergeNoDriverRowsIntoFreeRows(freeRows,noDriverRows,freeRowsStartIndex,freeRowsEndIndex,noDriverRowsStartIndex,noDriverRowsEndIndex,st_id,end_driver_id,fp)
							noDriverRowsEndIndex = -1
							noDriverRowsStartIndex = -1
							noDriverRows =[]
							start_driver_id = driver_id	
							print finalList
							writeIntoFile(storedList,fp)
						rowIndex = rowIndex + 1
					listOfPrevsPOB = []

					freeRows = convertFreeRowsTo(freeRows,isTaxiStand)
					print "free rows before payment"
					print freeRows
					noDriverRows = mergeCruisingRowsNoDriverRows(freeRows,noDriverRows,freeRowsStartIndex,freeRowsEndIndex,noDriverRowsStartIndex,noDriverRowsEndIndex,fp)
					freeRows =[]
					freeRowsStartIndex = -1
					freeRowsEndIndex = -1
					finalList.append("DROP OFF")
					lastPaymentTime = startTime
					if driver_id =="" or driver_id == " ":
						if noDriverRowsStartIndex == -1:
							noDriverRowsStartIndex = rowNum
						noDriverRowsEndIndex = rowNum
						noDriverRows.append(finalList)
					else:
						freeRows = mergeNoDriverRowsIntoFreeRows(freeRows,noDriverRows,freeRowsStartIndex,freeRowsEndIndex,noDriverRowsStartIndex,noDriverRowsEndIndex,start_driver_id,driver_id,fp)
						noDriverRowsEndIndex = -1
						noDriverRowsStartIndex = -1
						noDriverRows = []
						start_driver_id = driver_id					
						print finalList
						writeIntoFile(finalList,fp)
					prevPOB = False
					POBCount = 0
				
				elif status == 'FREE':
					print "FREE is"					
					freeRows,noDriverRows,freeRowsStartIndex,freeRowsEndIndex,noDriverRowsStartIndex,noDriverRowsEndIndex,start_driver_id,driver_id,fp,listOfPrevsPOB,rowNum,isdropoff = is_Drop_Off(prevPOB,POBCount,freeRows,noDriverRows,freeRowsStartIndex,freeRowsEndIndex,noDriverRowsStartIndex,noDriverRowsEndIndex,start_driver_id,driver_id,fp,rowNum,listOfPrevsPOB)
					listOfPrevsPOB = []					
					if 	len(listOfPrevsPOB)	>0:			
						print "list of prev POB in free staus" 
						print listOfPrevsPOB					
					#print "return"					
					#print rowNum					
					if isTaxiStand== True:
						print "the current state is queuing at taxi stand"
						freeRows = convertFreeRowsTo(freeRows,isTaxiStand)
						noDriverRows = mergeCruisingRowsNoDriverRows(freeRows,noDriverRows,freeRowsStartIndex,freeRowsEndIndex,noDriverRowsStartIndex,noDriverRowsEndIndex,fp)
						freeRowsStartIndex = -1
						freeRowsEndIndex = -1
						freeRows =[]
						finalList.append("QUEUING AT TAXI STAND")					
						if driver_id =="" or driver_id == " ":
							if noDriverRowsStartIndex == -1:
								noDriverRowsStartIndex = rowNum
							noDriverRowsEndIndex = rowNum
							noDriverRows.append(finalList)									
						else:
							freeRows = mergeNoDriverRowsIntoFreeRows(freeRows,noDriverRows,freeRowsStartIndex,freeRowsEndIndex,noDriverRowsStartIndex,noDriverRowsEndIndex,start_driver_id,driver_id,fp)					
							noDriverRowsEndIndex = -1
							noDriverRowsStartIndex = -1
							noDriverRows =[]	
							start_driver_id = driver_id					
							print finalList
							writeIntoFile(finalList,fp)

					else:
						if driver_id =="" or driver_id == " ":
							print "no driver id when status is free"
							if noDriverRowsStartIndex == -1:
								noDriverRowsStartIndex = rowNum
							noDriverRowsEndIndex = rowNum
							#print "no driver row start index"
							#print noDriverRowsStartIndex
							#print noDriverRowsEndIndex
							noDriverRows.append(finalList)
							freeRows.append(finalList)
							if freeRowsStartIndex == -1:
								freeRowsStartIndex = rowNum
							freeRowsEndIndex = rowNum
							#print freeRowsStartIndex
							#print freeRowsEndIndex
						else:
							freeRows = mergeNoDriverRowsIntoFreeRows(freeRows,noDriverRows,freeRowsStartIndex,freeRowsEndIndex,noDriverRowsStartIndex,noDriverRowsEndIndex,start_driver_id,driver_id,fp)
							noDriverRowsEndIndex = -1
							noDriverRowsStartIndex = -1
							noDriverRows = []	
							start_driver_id = driver_id
							if freeRowsStartIndex == -1:
								freeRowsStartIndex = rowNum
							freeRowsEndIndex = rowNum					
							freeRows.append(finalList)
					prevPOB = False
					POBCount = 0

				elif status == 'BUSY':
					print "the current state is busy"							
					freeRows = convertFreeRowsTo(freeRows,isTaxiStand)
					noDriverRows = mergeCruisingRowsNoDriverRows(freeRows,noDriverRows,freeRowsStartIndex,freeRowsEndIndex,noDriverRowsStartIndex,noDriverRowsEndIndex,fp)
					freeRows =[]
					freeRowsStartIndex = -1
					freeRowsEndIndex = -1
					if prevList != []:
						if len(prevList) == 10:
							finalList.append(prevList[9])
					else:
						finalList.append("CRUISING")
					if prevPOB == True:
						listOfPrevsPOB.append((finalList,start_driver_id,driver_id))
					else:				
						if driver_id =="" or driver_id == " ":
							if noDriverRowsStartIndex == -1:
								noDriverRowsStartIndex = rowNum
							noDriverRowsEndIndex = rowNum
							noDriverRows.append(finalList)				
						else:
							freeRows = mergeNoDriverRowsIntoFreeRows(freeRows,noDriverRows,freeRowsStartIndex,freeRowsEndIndex,noDriverRowsStartIndex,noDriverRowsEndIndex,start_driver_id,driver_id,fp)
							noDriverRowsEndIndex = -1
							noDriverRowsStartIndex = -1	
							noDriverRows = []
							start_driver_id = driver_id				
							print finalList
							writeIntoFile(finalList,fp)

				elif status == 'BREAK' or status == 'OFFLINE':
					if str(time) == '2010-08-28 18:55:59':
						print "driver id is in BREAK"
						print  str(time)
					freeRows,noDriverRows,freeRowsStartIndex,freeRowsEndIndex,noDriverRowsStartIndex,noDriverRowsEndIndex,start_driver_id,driver_id,fp,listOfPrevsPOB,rowNum,isdropoff = is_Drop_Off(prevPOB,POBCount,freeRows,noDriverRows,freeRowsStartIndex,freeRowsEndIndex,noDriverRowsStartIndex,noDriverRowsEndIndex,start_driver_id,driver_id,fp,rowNum,listOfPrevsPOB)
					listOfPrevsPOB = []					
					print "current state is break"
					print "before merging converting"
					#print noDriverRows
					freeRows = convertFreeRowsTo(freeRows,isTaxiStand)
					print "after merging converting"					
					#print noDriverRows
					noDriverRows = mergeCruisingRowsNoDriverRows(freeRows,noDriverRows,freeRowsStartIndex,freeRowsEndIndex,noDriverRowsStartIndex,noDriverRowsEndIndex,fp)
					freeRowsStartIndex = -1
					freeRowsEndIndex = -1	
					freeRows =[]			
					finalList.append("OUT OF SERVICE")				
					if driver_id =="" or driver_id == " ":
						if noDriverRowsStartIndex == -1:
							noDriverRowsStartIndex = rowNum
						noDriverRowsEndIndex = rowNum
						noDriverRows.append(finalList)				
					else:
						if str(time) == '2010-08-28 18:55:59':
							print "time is  2010-08-28 18:55:59" + str(noDriverRows)
						freeRows = mergeNoDriverRowsIntoFreeRows(freeRows,noDriverRows,freeRowsStartIndex,freeRowsEndIndex,noDriverRowsStartIndex,noDriverRowsEndIndex,start_driver_id,driver_id,fp)			 
						noDriverRowsEndIndex = -1
						noDriverRowsStartIndex = -1	
						noDriverRows = []
						start_driver_id = driver_id				
						print finalList
						writeIntoFile(finalList,fp)
					prevPOB = False
					POBCount = 0

				elif status == 'OUT OF SERVICE':
					print "power off"	
					freeRows,noDriverRows,freeRowsStartIndex,freeRowsEndIndex,noDriverRowsStartIndex,noDriverRowsEndIndex,start_driver_id,driver_id,fp,listOfPrevsPOB,rowNum,isdropoff = is_Drop_Off(prevPOB,POBCount,freeRows,noDriverRows,freeRowsStartIndex,freeRowsEndIndex,noDriverRowsStartIndex,noDriverRowsEndIndex,start_driver_id,driver_id,fp,rowNum,listOfPrevsPOB)
					listOfPrevsPOB = []					
					freeRows = convertFreeRowsTo(freeRows,isTaxiStand)	
					noDriverRows = mergeCruisingRowsNoDriverRows(freeRows,noDriverRows,freeRowsStartIndex,freeRowsEndIndex,noDriverRowsStartIndex,noDriverRowsEndIndex,fp)
					freeRowsStartIndex = -1
					freeRowsEndIndex = -1	
					freeRows =[]
					finalList.append("OUT OF SERVICE")				
					if driver_id =="" or driver_id == " ":
						if noDriverRowsStartIndex == -1:
							noDriverRowsStartIndex = rowNum
						noDriverRowsEndIndex = rowNum
						noDriverRows.append(finalList)				
					else:	
						
						freeRows = mergeNoDriverRowsIntoFreeRows(freeRows,noDriverRows,freeRowsStartIndex,freeRowsEndIndex,noDriverRowsStartIndex,noDriverRowsEndIndex,start_driver_id,driver_id,fp)			 
						noDriverRowsEndIndex = -1
						noDriverRowsStartIndex = -1	
						noDriverRows = []
						start_driver_id = driver_id				
						print finalList
						writeIntoFile(finalList,fp)
					prevPOB = False
					POBCount = 0
				else:
					print "other state"	
					freeRows,noDriverRows,freeRowsStartIndex,freeRowsEndIndex,noDriverRowsStartIndex,noDriverRowsEndIndex,start_driver_id,driver_id,fp,listOfPrevsPOB,rowNum,isdropoff = is_Drop_Off(prevPOB,POBCount,freeRows,noDriverRows,freeRowsStartIndex,freeRowsEndIndex,noDriverRowsStartIndex,noDriverRowsEndIndex,start_driver_id,driver_id,fp,rowNum,listOfPrevsPOB)
					listOfPrevsPOB = []					
					freeRows = convertFreeRowsTo(freeRows,isTaxiStand)	
					noDriverRows = mergeCruisingRowsNoDriverRows(freeRows,noDriverRows,freeRowsStartIndex,freeRowsEndIndex,noDriverRowsStartIndex,noDriverRowsEndIndex,fp)
					freeRowsStartIndex = -1
					freeRowsEndIndex = -1	
					freeRows =[]
					finalList.append("OTHER STATE")				
					if driver_id =="" or driver_id == " ":
						if noDriverRowsStartIndex == -1:
							noDriverRowsStartIndex = rowNum
						noDriverRowsEndIndex = rowNum
						noDriverRows.append(finalList)				
					else:	
						freeRows = mergeNoDriverRowsIntoFreeRows(freeRows,noDriverRows,freeRowsStartIndex,freeRowsEndIndex,noDriverRowsStartIndex,noDriverRowsEndIndex,start_driver_id,driver_id,fp)			 
						noDriverRowsEndIndex = -1
						noDriverRowsStartIndex = -1	
						noDriverRows = []
						start_driver_id = driver_id				
						print finalList
						writeIntoFile(finalList,fp)
					prevPOB = False
					POBCount = 0		
				prevstatus = status
				prevList = finalList
			#end of row iterator loop for a vehicle
			prevPOB,POBCount,freeRows,noDriverRows,freeRowsStartIndex,freeRowsEndIndex,noDriverRowsStartIndex,noDriverRowsEndIndex,start_driver_id,driver_id,fp,rowNum,ispickup = isPickUp(prevPOB,POBCount,freeRows,noDriverRows,freeRowsStartIndex,freeRowsEndIndex,noDriverRowsStartIndex,noDriverRowsEndIndex,start_driver_id,driver_id,fp,rowNum,listOfPrevsPOB)
			if ispickup == False:
				prevPOB,POBCount,freeRows,noDriverRows,freeRowsStartIndex,freeRowsEndIndex,noDriverRowsStartIndex,noDriverRowsEndIndex,start_driver_id,driver_id,fp,rowNum,isoccupied = isOccupied(prevPOB,POBCount,freeRows,noDriverRows,freeRowsStartIndex,freeRowsEndIndex,noDriverRowsStartIndex,noDriverRowsEndIndex,start_driver_id,driver_id,fp,rowNum,listOfPrevsPOB)				 	
				print listOfPrevsPOB			
				if isoccupied == False:
					# do nothing 
					listOfPrevsPOB = []
				else:
					print "final POB is occupied"
					listOfPrevsPOB = []
			else:
				listOfPrevsPOB = []
			
			for i in range (0,len(freeRows)):
				freeRows[i].append("CRUISING")
				print freeRows[i]
			noDriverRows = mergeCruisingRowsNoDriverRows(freeRows,noDriverRows,freeRowsStartIndex,freeRowsEndIndex,noDriverRowsStartIndex,noDriverRowsEndIndex,fp) 
			freeRowsStartIndex = -1
			freeRowsEndIndex = -1	
			freeRows =[]
			freeRows = mergeNoDriverRowsIntoFreeRows(freeRows,noDriverRows,freeRowsStartIndex,freeRowsEndIndex,noDriverRowsStartIndex,noDriverRowsEndIndex,start_driver_id,driver_id,fp)
			freeRows =[]
			noDriverRows = []
			freeRowsStartIndex = -1
			freeRowsEndIndex = -1
			noDriverRowsStartIndex = -1
			noDriverRowsEndIndex = -1
			start_driver_id = ""
			driver_id = ""
			lastPaymentTime = ""
			prevstatus = ""
			listOfPrevsPOB = []
			POBCount = 0
			prevPOB = False
			fp.close()  
	finally:	    
		conn.close()
	
	print "printing remaining free state rows and no driver rows"
	#print freeRows[i]
	return i

def GetAllTrips():
	#get_trips_gps_log(table, veh_id):
	print "start"
	taxiStands,taxiStops = get_all_Taxi_Stand()	
	i =0
	get_trips_gps_log(i,taxiStands,taxiStops)	


GetAllTrips()
