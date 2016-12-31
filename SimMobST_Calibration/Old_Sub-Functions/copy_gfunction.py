import csv
import psycopg2
import random
import time
import os
import collections
import sys


interval = int(sys.argv[3]) * 60

#Read the file with the new OD counts
with open('data/TripChain/theta_OD_dash.csv', 'rb') as theta_OD_dash:
    OD_counts = list(csv.reader(theta_OD_dash, delimiter = ','))

#Read the file containing the ODs, index to the above file and the interval for the counts
with open('data/TripChain/ODdata.csv', 'rb') as OD_data:
    OD_intervals = list(csv.reader(OD_data, delimiter = ' '))

try:
    dbConn = psycopg2.connect("dbname='simmobility' user='postgres' host='127.0.0.1' password='5M_S1mM0bility'")
    #dbConn = psycopg2.connect("dbname='simmobility' user='postgres' host='172.25.184.156' password='d84dmiN'")
    cur = dbConn.cursor()
except:
    print "Unable to connect to the database"

#Truncate the demand.temp_trips_activities_shortterm_calibration table
cur.execute("truncate table demand.temp_trips_activities_shortterm_calibration")
cur.execute("truncate table demand.temp_subtrips_shortterm_calibration")
cur.execute("UPDATE demand.trips_activities SET load_factor=1")
cur.execute("UPDATE demand.subtrips SET load_factor=1")


def get_time_string(time_val):
    time_vals_splited = time_val.split(sep=":")
    time_hrs = int(time_vals_splited[0])
    time_mins = 00

    if len(time_vals_splited) > 1:
        mins = "0." + time_vals_splited[1]
        time_mins = int(float(mins) * 60)

    return "%02d:%02d:00" % (time_hrs, time_mins)


def get_interval_slot(time_val):
    time_vals_splitted = time_val.split(sep=":")
    time_hrs = int(time_vals_splitted[0])
    time_mins = int(time_vals_splitted[1])
    time_secs = int(time_vals_splitted[2])

    time = (time_hrs * 60 * 60) + (time_mins * 60) + time_secs

    # Gets the interval slot it belongs to
    # '//' operator gives the floor value of the divided number
    return (time // interval) * interval


query = "select * from demand.trips_activities where"  \
        + "'trip_start_time >= '" + get_time_string(sys.argv[1]) \
        + "' and trip_start_time <= '" + get_time_string(sys.argv[2]) + "'"

cur.execute(query)
trips_activities = cur.fetchall()

trips_activities_dict = collections.OrderedDict()

for item in trips_activities:
    slot = get_interval_slot(item[2])
    trips_activities_dict[(item[7], item[8], slot)] = item

query = "select * from demand.subtrips where"  \
        + "'trip_start_time >= '" + get_time_string(sys.argv[1]) \
        + "' and trip_start_time <= '" + get_time_string(sys.argv[2]) + "'"

cur.execute(query)
sub_trips = cur.fetchall()

sub_trips_dict = collections.OrderedDict()

for item in sub_trips:
    sub_trips_dict[item[0]] = item

#Ensure that both the files have the same number of rows
if len(OD_counts) == len(OD_intervals):
    row = 0
    totalRows = len(OD_intervals)

    print "Total rows = " + str(totalRows)

    #Create the files which will hold the additional trips and sub-trips (the data will then be bulk inserted at the end)
    tripsFile = open('copy_trips.csv', 'w+')
    subTripsFile = open('copy_subtrips.csv', 'w+')

    updated_sub_trips_file = open('update_trips.csv', 'w')

    #Iterate over all the rows in the file
    while row < totalRows:

        #Extract the ODs, the original count and the interval
        origin = OD_intervals[row][1]
        destination = OD_intervals[row][2]
        originalCount = int(OD_intervals[row][5])
        interval = int(OD_intervals[row][6])

        #Extract the required OD counts (generated by the perturbation)
        count = int(float(OD_counts[row][0]))

        #Convert the interval to time (interval is in seconds)

        #Get the HH part of time
        timeHH = interval / 3600
        #Get the MM part of time
        timeMM = (interval % 3600) / 60
        #String representation of the time
        startTime = "%02d:%02d:00" % (timeHH, timeMM)
        endTime = "%02d:%02d:00" % (timeHH, timeMM+15)

        if originalCount > count:

            #If the original demand is higher than the requested demand, set load factor to 0
            #for the extra trips (in the subtrip table)

            # Get the trip ids of the matching trips
            query = "select trip_id,trip_start_time from demand.trips_activities where origin_id = '" + origin + "' and destination_id = '" + destination \
                    + "' and trip_start_time >= '" + startTime + "' and trip_start_time <= '" + endTime + "'"

            #Execute the query
            cur.execute(query)
            subtripIds = cur.fetchall()

            extraTrips = originalCount - count

            if len(subtripIds) <= 0:
                continue

            if len(subtripIds) < extraTrips:
                print "Extra trips changed from ", extraTrips, " to ", len(subtripIds)
                extraTrips = len(subtripIds)

            tripIDs = "("
            while extraTrips > 1:
                if subtripIds[extraTrips-1][0] != endTime:
                    tripIDs = tripIDs + "'" + subtripIds[extraTrips-1][0] + "',"
                extraTrips -= 1

            if subtripIds[extraTrips-1][0] != endTime:
                tripIDs = tripIDs + "'" + subtripIds[extraTrips-1][0] + "')"

            query = "UPDATE demand.subtrips "\
                    "SET load_factor = 0 where origin_id = '" + origin + "' and destination_id = '" + destination + "' and trip_id in " + tripIDs

            #Execute the query
            cur.execute(query)

        elif originalCount < count:

            #If the original demand is lower than the requested demand, create and add additional
            #trips and add the to demand.temp_trips_activities_shortterm_calibration

            while originalCount < count:

                #Generate start time in the 15 min interval
                randomMM = random.randint(timeMM, timeMM + 14)
                randomSS = random.randint(0, 59)
                startTime = "%02d:%02d:%02d" % (timeHH, randomMM, randomSS)
                empty = ""

                #Create dummy trip and person id
                id = origin + "-" + destination + "_" + startTime
                trip_id = "d_t_" + id
                person_id = "p_t_" + id

                tripsFile.write('"%s","%s","%s","%s","%s",1,1,%s,%s,1\n' % (trip_id, person_id, startTime, empty, empty, origin, destination))
                subTripsFile.write('"%s",1,"Car","%s",2,1,1,%s,%s,1\n' % (trip_id, empty, origin, destination))

                originalCount += 1

        #Next row
        #print "Row: " + str(row)
        row = row + 1

    tripsFile.close()
    subTripsFile.close()

    curr_path = os.getcwd()
    curr_path_trips = curr_path + '/copy_trips.csv'
    curr_path_sub_trips = curr_path + '/copy_subtrips.csv'

    #Execute the query
    query = "copy demand.temp_trips_activities_shortterm_calibration(trip_id, person_id, trip_start_time, activity_start_time, activity_end_time, "\
            " origin_type, destination_type, origin_id, destination_id,load_factor) from '" + curr_path_trips + "' csv"
    cur.execute(query)

    query = "copy demand.temp_subtrips_shortterm_calibration(trip_id, sequence_num, travel_mode, pt_line_id, cbd_traverse_type, origin_type, "\
            "destination_type, origin_id, destination_id, load_factor) from '" + curr_path_sub_trips + "' csv"
    cur.execute(query)

    #Commit to db
    dbConn.commit()

else:
    print "Number of rows in the input files do not match!!!"
