import psycopg2

try:
    dbConn = psycopg2.connect("dbname='SimMobility_ShortTerm' user='postgres' host='127.0.0.1' password='5M_S1mM0bility'")
    cur = dbConn.cursor()
except:
    print "Unable to connect to the database"

cur.execute("SELECT upsert_realtime('/home/chuyaw/SimMobST_Calibration/SimMobility_SPSA/supply.link_travel_time.txt', 'supply.link_travel_time', 0.5)")
#Commit to db
dbConn.commit()
