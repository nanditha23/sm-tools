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
#SQL_getgpslog = '''select vehicle_num, driver_id,report_timestamp, x_lon, y_lat, speed,status from %s order by vehicle_num, report_timestamp'''
SQL_getgpslog = '''select * from %s order by vehicle_no, report_timestamp'''
SQL_taxistand = '''Select lon,lat,type_cd_de,shapeid from supply.taxistands_lat_lon where type_cd_de ='%s' or type_cd_de ='%s' '''
Pool = PooledDB(psycopg2, dsn=DSN)

def writeIntoFile(finalList,fp):
	#print "writing to file"
	printList = str(finalList).strip('[')
	printList = str(printList).strip(']')
	#print "before printing"
	printList = printList.replace("'","")
	#print printList
	#print "after printing"
	fp.write(printList+"\n")

def calCulateTimeDifference(time1,time2):
	print time1
	print time2	
	datetimefields1 = time1.split(" ")
	datetimeval1 = datetimefields1[1]
	yearmonthday1 = datetimeval1.split("-")
	day1 = int(yearmonthday1[2])
	hhmmsec1 = datetimefields1[2]
	hourminsec1 = hhmmsec1.split(":")
	hours1 = int(hourminsec1[0])
	mins1 = int(hourminsec1[1])
	secs1= int(hourminsec1[2])

	datetimefields2 = time2.split(" ")
	datetimeval2 = datetimefields2[1]
	yearmonthday2 = datetimeval2.split("-")
	day2 = int(yearmonthday2[2])
	hhmmsec2 = datetimefields2[2]
	hourminsec2 = hhmmsec2.split(":")
	hours2 = int(hourminsec2[0])
	mins2 = int(hourminsec2[1])
	secs2 = int(hourminsec2[2])
	#if time == '2010-08-27 06:36:54':
	print "time differnce  " + str(-(((day1-day2)*60*60*24) + ((hours1-hours2)*60*60) + ((mins1-mins2)*60) + (secs1-secs2)))
		#print (((day1-day2)*60*60*24) - ((hours1-hours2)*60*60) - ((mins1-mins2)*60) - (secs1-secs2))
	return -(((day1-day2)*60*60*24) + ((hours1-hours2)*60*60) + ((mins1-mins2)*60) + (secs1-secs2))

def checkIfModeToBeChanged(row,storedList,startIndex,curs,prev_vehid,fp):
	subsequentRows = []
	timeCurrRow = row[2]
	iterIndex = startIndex
	if 1<2: 	
		if iterIndex == len(storedList) - 1:
			print "stored list end"
			subRow = curs.fetchone()
			if subRow == None:
				print "end of cursor"
				
				writeIntoFile(row,fp)
				return (storedList,curs,startIndex,subRow)
			subRow = list(subRow)
			veh_id = subRow[0]
			subRow[6] = subRow[6].replace(" ","")
			subRow[9] = subRow[9].replace(" ","")
			storedList.append(subRow)
			if veh_id != prev_vehid:
				writeIntoFile(row,fp)
				return (storedList,curs,startIndex,row)
			iterIndex = iterIndex +1
			subRowTime = subRow[2]
			diff = calCulateTimeDifference(timeCurrRow,subRowTime)
			if row[6] == 'FREE':
				if subRow[6] == 'PAYMENT':
					row[6] = 'POB'
					row[9] = 'OCCUPIED'
				writeIntoFile(row,fp)
				return (storedList,curs,startIndex,subRow)

			else:
				if row[9]== 'PICKUP' and subRow[6] == 'POB' and subRow[9] == 'PICKUP':
					row[6] = 'FREE'
					row[9] = 'CRUISING'
					print "state 1"
					writeIntoFile(row,fp)
					return (storedList,curs,startIndex,row)
				elif row[9]== 'DROPOFF' and subRow[6] == 'POB' and subRow[9] == 'DROPOFF':
					row[6] = 'POB'
					row[9] = 'OCCUPIED'
					print "state 2"
					writeIntoFile(row,fp)
					return (storedList,curs,startIndex,row)
				elif row[6]== 'PAYMENT' and subRow[6] == 'PAYMENT':
					row[6] = 'POB'
					row[9] = 'OCCUPIED'
					print "state 3"
					writeIntoFile(row,fp)
					return (storedList,curs,startIndex,subRow)
				else:
					print "cur iterate other state"
					print "stored list is "+ str(storedList)
					writeIntoFile(row,fp)
					return (storedList,curs,startIndex,subRow)
						
				#else:
				#	print "diff morer than 300"
				#	writeIntoFile(row,fp)
				#	return (storedList,curs,startIndex,subRow)
		else:
			iterIndex = iterIndex + 1
			subRow = storedList[iterIndex]
			veh_id = subRow[0]
			if veh_id != prev_vehid:
				writeIntoFile(row,fp)
				return (storedList,curs,startIndex,subRow)
			storedList.append(subRow)
			subRowTime = subRow[2]
			diff = calCulateTimeDifference(timeCurrRow,subRowTime)
			if row[6] == 'FREE':
				if subRow[6] == 'PAYMENT':
					row[6] = 'POB'
					row[9] = 'OCCUPIED'
				writeIntoFile(row,fp)
				print "return from payment"
				return (storedList,curs,startIndex,subRow)
			else:
				if row[9]== 'PICKUP' and subRow[6] == 'POB' and subRow[9] == 'PICKUP':
					row[6] = 'FREE'
					row[9] = 'CRUISING'
					writeIntoFile(row,fp)
					print "return from pickup"
					return (storedList,curs,startIndex,subRow)
				elif row[9]== 'DROPOFF' and subRow[6] == 'POB' and subRow[9] == 'DROPOFF':
					row[6] = 'POB'
					row[9] = 'OCCUPIED'
					writeIntoFile(row,fp)
					print "return from drop off"
					return (storedList,curs,startIndex,subRow)
				elif row[6]== 'PAYMENT' and subRow[6] == 'PAYMENT':
					row[6] = 'POB'
					row[9] = 'OCCUPIED'
					writeIntoFile(row,fp)
					print "return from occupied"
					return (storedList,curs,startIndex,subRow)
				else:
					print "no case"
					print row
					writeIntoFile(row,fp)
					return (storedList,curs,startIndex,subRow)					
			#else:
				#writeIntoFile(row,fp)
				#return (storedList,curs,startIndex,subRow)
			
			
def get_trips_gps_log(i):
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
	prevRowTime = ""
	prevAcceptedRow = ""
	#proj = Proj(init = "epsg:32648")
	try:
		#conn = psycopg2.connect(DSN)
		conn =""
		with open ("testwrite.csv","w") as fp:
			conn = Pool.dedicated_connection()
			curs = conn.cursor()
			#table = "externaldata.stage2"
			#table = "externaldata.test3"
			table = "taxigps_finalstage.comfort_gps_logs_20100803_20100804"
			#table = "externaldata.comfort_gps_logs_20100801_20100831"
			#table = "gps.comfort_gps_logs_20100803_20100804"
			curs.execute(SQL_getgpslog %(table)) #, veh_id,'2010-08-02'))            
			prevstatus = "";			
			start_driver_id = ""			
			rowNum = -1
			prev_veh_id = ""
			prevRowTime = ""
			prevRow =[]
			useCursor = True
			useIterateList = False
			row = []
			storedList = []
			while 1<2:
				if useCursor:
					row = curs.fetchone()
					if row == None:
						break
					veh_id = row[0]
					if veh_id != prev_veh_id:
						y =9
						# reset the driver viables
					prev_veh_id = veh_id
					#print row[9]
					row = list(row)
					row[6] = row[6].replace(" ","")
					row[9] = row[9].replace(" ","")
					if	row[9] == 'PICKUP' or row[6] == 'PAYMENT' or row[9] == 'DROPOFF' or row[6] == 'FREE': 
						print row[9]
						storedList.append(row)
						startIndex = 0						
						(storedList,curs,startIndex,row) = checkIfModeToBeChanged(row,storedList,startIndex,curs,veh_id,fp)
						if startIndex == len(storedList) -1:
							useIterateList = False
							useCursor = True
							storedList = []
							if row == None:
								break
						else:
							useIterateList = True
							useCursor = False
							startIndex = startIndex +1
					else:
						writeIntoFile(row,fp)
				elif useIterateList:
					row = storedList[startIndex]
                                        veh_id = row[0]
					if veh_id != prev_veh_id:
						y =9
						# reset the driver viables
					if	row[9] == 'PICKUP' or row[6] == 'PAYMENT' or row[9] == 'DROPOFF' or row[6] == 'FREE':
						(storedList,curs,startIndex,row) = checkIfModeToBeChanged(row,storedList,startIndex,curs,veh_id,fp)
					else:
						print "occupied row is"
						
						writeIntoFile(row,fp)
					if startIndex == len(storedList) -1:
						print "end of list 2nd"
						useIterateList = False
						useCursor = True
						storedList = []
						if row == None:
							break
					else:
						startIndex = startIndex +1 
									
	finally:	    
		conn.close()

def GetAllTrips():
	i =0
	get_trips_gps_log(i)

GetAllTrips()
