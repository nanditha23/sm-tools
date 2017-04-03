from pymongo import MongoClient
import csv
import psycopg2
import time
import numpy as np

def getWindowIdx(time):
    time = time.replace(".5",":30")
    time += ':00'
    res = 0
    splitTime = time.split(":")
    hour = int(splitTime[0])
    if hour > 24 or hour < 0: raise RuntimeError('invalid time - ' + time)
    if hour < 3: hour = hour + 24 #0, 1 and 2 AM are 24, 25 and 26 hours respectively
    minute = int(splitTime[1])
    if minute > 59 or minute < 0: raise RuntimeError('invalid time - ' + time)
    totalMins = ((hour*60) + minute) - 180 #day starts at 3:00 AM
    return (totalMins/30)+1

class TT_Aggregator:
    def initializer(self, csv_name, suffix_str):
        #Re-write the csvFile with no hearders/strings before adding to DB
        import re
        if suffix_str == "PLUS_PERTURB/SimMobility/":
            suffix_str = "PLUS_PERTURB"
        elif suffix_str == "MINUS_PERTURB/SimMobility/":
            suffix_str = "MINUS_PERTURB"
        elif suffix_str == "GRADIENT_RUN/SimMobility/":
            suffix_str = "GRADIENT_RUN"
        csvFile = open(csv_name)
        csvData = [line for line in csvFile.read().splitlines() if not re.search('origin',line,re.I)]
        csvFile.close()
        csvFile = open(csv_name,'w')
        for line in csvData:
            csvFile.write(line+'\n')
        csvFile.close()
        table_name = "subtrip_tt_"+suffix_str
        conn_string = "dbname='simmobility' user='postgres' host='172.25.184.156' port='5432' password='d84dmiN'"
        conn = psycopg2.connect(conn_string)
        cursor = conn.cursor()

        # truncate existing table
        query = "CREATE TABLE "+table_name+"(person_id character varying,trip_id character varying,subtrip_id character varying,origin_node character varying,origin_taz integer,destination_node character varying, destination_taz integer, mode character varying,start_time character varying,end_time character varying,travel_time double precision,total_distance double precision,ptt_wt integer,pt_walk integer,cbd_entry_node character varying,  cbd_exit_node character varying,  cbd_entry_time character varying,  cbd_exit_time character varying,  cbd_travel_time double precision,  non_cbd_travel_time double precision,  cbd_distance double precision,  non_cbd_distance double precision)WITH (  OIDS=FALSE);ALTER TABLE "+table_name+"  OWNER TO postgres;"
        cursor.execute(query)
        conn.commit()

        # copy csv data into table
        csvFile = open(csv_name, 'r')
        cursor.copy_from(csvFile, table_name, ',')
        csvFile.close()

        # load aggregated records
        query = "SELECT origin_taz, destination_taz, min(mode) as mode, min(start_time) as start_time, sum(travel_time) as travel_time FROM public."+table_name+" GROUP BY person_id, trip_id, origin_taz, destination_taz"
        cursor.execute(query)
        self.inputCsv = cursor.fetchall()
        conn.commit()

        query = "DROP table "+table_name
        cursor.execute(query)
        conn.commit()

        #connect to local mongodb
        self.client = MongoClient('172.25.184.156', 27017)
        self.db = self.client.preday

        self.zone = self.db.Zone_2012

        self.zoneId = {} # dictionary of <zone_code> : <zone_id>
        self.zoneCode = {} #dictionary of <zone_id> : <zone_code>
        self.NUM_ZONES = self.zone.count() #meant to be constant

        for z in range(1, self.NUM_ZONES+1):

            zoneDoc = self.zone.find_one({"zone_id" : z})
            self.zoneId[int(zoneDoc["zone_code"])] = z
            self.zoneCode[z] = int(zoneDoc["zone_code"])

        self.ttCar = [[[0 for k in xrange(48)] for j in xrange(self.NUM_ZONES)] for i in xrange(self.NUM_ZONES)]
        self.ttCarCount = [[[0 for k in xrange(48)] for j in xrange(self.NUM_ZONES)] for i in xrange(self.NUM_ZONES)]

    def addTTCar(self, origin, destination, tripStartTime, value):
        orgZid = self.zoneId[origin] - 1
        desZid = self.zoneId[destination] - 1
        timeIdx = getWindowIdx(tripStartTime) - 1
        self.ttCar[orgZid][desZid][timeIdx] = self.ttCar[orgZid][desZid][timeIdx] + value
        self.ttCarCount[orgZid][desZid][timeIdx] = self.ttCarCount[orgZid][desZid][timeIdx] + 1
        return

    #process input csv
    def processInput(self):
        #process each row of input csv
        for row in self.inputCsv:
            #origin_taz, destination_taz, mode, start_time, travel_time
            orgZ = int(row[0])
            desZ = int(row[1])
            mode = str(row[2]).strip()
            tripStartTime = str(row[3])
            travelTime = float(row[4])
            if mode == "Car" or mode == "Motorcycle" or mode == "Taxi":
                self.addTTCar(orgZ, desZ, tripStartTime, travelTime)
        return

    def computeMeans(self):
        for i in range(self.NUM_ZONES):
            for j in range(self.NUM_ZONES):
                for k in range(48):
                    self.ttCar[i][j][k] = (float(self.ttCar[i][j][k])/self.ttCarCount[i][j][k]) if self.ttCarCount[i][j][k] > 0 else 0
        return

    def writeToFile(self, filename):

        taxi_gps_data_raw = list(csv.reader(open("data/Taxi_GPS_Data.csv", "rb"), delimiter=","))
        taxi_gps_data = [str(item[0])+"-"+str(item[1]) for item in taxi_gps_data_raw]

        f = open(filename,"w")
        f.write("Origin_Zone, Destination_Zone,tt_7.25,tt_7.75,tt_8.25,tt_8.75,tt_9.25,tt_9.75,tt_10.25,tt_10.75,tt_11.25,tt_11.75")
        f.write('\n')
        for i in range(self.NUM_ZONES):
            orgZ = self.zoneCode[i+1]
            for j in range(self.NUM_ZONES):
                desZ = self.zoneCode[j+1]
                if orgZ == desZ: continue
                odpair = str(orgZ)+"-"+str(desZ)
                if odpair in taxi_gps_data:
                    printlist = []
                    printlist.insert(0,orgZ)
                    printlist.insert(1,desZ)
                    for k in range(8, 18):
                        printlist.append(self.ttCar[i][j][k])
                    f.write(','.join([str(x) for x in printlist]))
                    f.write('\n')
        f.close()
        return


    def generate_travel_time_list(self,filename,start_time,end_time,suffixstr):

        self.initializer(filename, suffixstr)
        self.processInput()
        self.computeMeans()
        zone_filename = "zonetraveltimes"+str(int(time.time()))+".csv"
        self.writeToFile(zone_filename)
        sim_list = []
        real_list = []
        travel_time_real = list(csv.reader(open("data/Taxi_GPS_Data.csv", "rb"), delimiter=","))
        travel_time_simulated = list(csv.reader(open(zone_filename, "rb"), delimiter=","))

        od_travel_time_real = [str(item[0])+"-"+str(item[1]) for item in travel_time_real]
        od_travel_time_sim = [str(item[0])+"-"+str(item[1]) for item in travel_time_simulated]
        start = getWindowIdx(str(start_time))
        end = getWindowIdx(str(end_time))
                if start > 18 or end < 9:
                        return np.array(sim_list),np.array(real_list)
                if start < 9:
                        start = 9
                if end > 18:
                        end = 19
                start = start-7
                end = end-7

        for i in range(start,end):
            for  idx_sim, od in enumerate(od_travel_time_sim):
                if od in od_travel_time_real:
                    idx_real = od_travel_time_real.index(od)
                    real_list.append(float(travel_time_real[idx_real][i]))
                    sim_list.append(float(travel_time_simulated[idx_sim][i]))
        return (np.array(sim_list),np.array(real_list))

#s = datetime.datetime.now()
#parser = argparse.ArgumentParser()
#parser.add_argument("csv_name", default="tt.csv", help="travel times experienced by persons in withinday")
#args = parser.parse_args()

#1.
#print "1. initializing and loading CSV"
#aggregator = TT_Aggregator(str(args.csv_name))
#2.

#print "2. processing input"
#aggregator.processInput()
#3.
#print "3. writing to csv"
#aggregator.writeToFile('zonetraveltimes.csv')

#4.
#print "4. generating lists"
#aggregator.generate_travel_time_list()

