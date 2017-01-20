#!/bin/bash
#
#
#  Executing preday in Loop
#
#
readonly LOOPSIZE=160
readonly OUTPUT_FILES_DIR=/home/shahita/input/mt_newNW/olga
for ((i=146; i <=$LOOPSIZE ; i++))
do		
	#Export output collections to csv files 
        echo "Export: $i"
	#mongoexport --db preday --collection daypattern_02Mar16_$i --csv --out $OUTPUT_FILES_DIR/mongoExports/daypattern_02Mar16_$i.csv --fieldFile dphdrs
        #mongoexport --db preday --collection tour_02Mar16_$i --csv --out $OUTPUT_FILES_DIR/mongoExports/tour_02Mar16_$i.csv --fieldFile tourhdrs
        #mongoexport --db preday --collection activity_02Mar16_$i --csv --out $OUTPUT_FILES_DIR/mongoExports/activity_02Mar16_$i.csv --fieldFile activityhdrs
        #mongoexport --db preday --collection wbst_02Mar16_$i --csv --out $OUTPUT_FILES_DIR/mongoExports/wbst_02Mar16_$i.csv --fieldFile wbsthdrs

        #Delete output collections from mongo 
        mongo preday --eval "db.daypattern_02Mar16_$i.drop()"
        mongo preday --eval "db.tour_02Mar16_$i.drop()"
        mongo preday --eval "db.activity_02Mar16_$i.drop()"
        mongo preday --eval "db.wbst_02Mar16_$i.drop()"
done

