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

# This code changes the busy state in TAXI GPS data into previous stateIf there exists a previous state 
#else busy is changed to free state
#Forward ,poweroff,offline states are changed to out of service
#Arrived is changed to passenger on board
#STC state is changed to free

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

def writeIntoFile(finalList,fp):
	#print "writing to file"
	printList = str(finalList).strip('[')
	printList = str(printList).strip(']')
	#print "before printing"
	printList = printList.replace("'","")
	#print printList
	#print "after printing"
	fp.write(printList+"\n")


def get_trips_gps_log():
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
	print "start"
	#proj = Proj(init = "epsg:32648")
	try:
		#conn = psycopg2.connect(DSN)
		conn =""
		with open ("testwrite.csv","w") as fp:
			conn = Pool.dedicated_connection()
			curs = conn.cursor()
			table = "gps.comfort_gps_logs_20100802_20100803"
			#table = "gps.comfort_gps_logs_20100804_20100805"
			#table = "externaldata.comfort_gps_logs_20100801_20100831"
			#table = "externaldata.test3"
			curs.execute(SQL_getgpslog %(table)) #, veh_id,'2010-08-02'))            
			prevstatus = "";			
			start_driver_id = ""			
			rowNum = -1
			prev_veh_id = ""
			prevList = []
			for row in curs:
				veh_id = row[0]
				#print "row is"
				#print row
				if veh_id != prev_veh_id:
					# reset the driver viables 
					freeRowsStartIndex = -1
					freeRowsEndIndex = -1	
					freeRows =[]
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
				finalList =[]
				driver_id = (str(row[1])).replace(" ","")
				time = str(row[2])
				status = row[6]	
				if status  != "OUT OF SERVICE":
					status = (str(status)).replace(" ","")			
				lon = row[3]
				lat = row[4]
				speed = row[5]
				#gps_status = row[7]
				XY = (lon, lat)
				rowNum = rowNum+1
				startTime=str(time).split(" ")[0]+" "+str(time).split(" ")[1]
				finalList.append(startTime)
				finalList.append(veh_id)
				finalList.append(driver_id)
				finalList.append(XY[0])
				finalList.append(XY[1])
				finalList.append(speed)
				finalList.append(status)
				#finalList.append(gps_status)
				if status == 'BUSY':
					if prevList == []:
						finalList[6] = 'FREE'
						finalList.append('FREE')
					else:
						finalList[6] = prevList[6]
						finalList.append(prevList[7])
				elif status == 'FORWARD' or status == 'POWEROFF' or status == 'OFFLINE':
					finalList[6] = "OUT OF SERVICE"
					finalList.append("OUT OF SERVICE")
				elif status == 'STC':
					finalList[6] = "FREE"
					finalList.append("FREE")
				
				elif status == 'ARRIVED':
					finalList[6] = "POB"
					finalList.append("POB")
				else:
					finalList[6] = status
					finalList.append(status)
				#print finalList
				writeIntoFile(finalList,fp)
				prevList = finalList
	finally:
		fp.close()

def GetAllTrips():
	get_trips_gps_log()

GetAllTrips()
