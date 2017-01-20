#!/bin/bash
#
#
#  Executing preday in Loop
#
#
date
# Loop count
readonly LOOPSIZE=200

#File Paths
readonly SIMULATION_CONFIG=data/simulation.xml
readonly SIMRUN_CONFIG=data/simrun_MidTerm.xml
readonly SIMRUN_CONFIG_BACKUP=data/simrun_MidTerm_backup.xml
readonly EXECUTABLE=Debug/SimMobility_Medium
readonly LUA_ORIGIN=olga
readonly LUA_DEST=scripts/lua/mid/behavior-models/
readonly OUTPUT_FILES_DIR=olga


#backup config file before the run
cp $SIMRUN_CONFIG $SIMRUN_CONFIG_BACKUP

for ((i=189; i <=$LOOPSIZE ; i++))
do
        #Modify output collections
        dayPatternFileName="\"daypattern_02Mar16_$i\""
        tourFileName="\"tour_02Mar16_$i\""
        activityFileName="\"activity_02Mar16_$i\""
        wbstFileName="\"wbst_02Mar16_$i\""

        sed -i "s/\"daypattern_.*\"/${dayPatternFileName}/g" $SIMRUN_CONFIG
        sed -i "s/\"tour_.*\"/${tourFileName}/g" $SIMRUN_CONFIG
        sed -i "s/\"activity_.*\"/${activityFileName}/g" $SIMRUN_CONFIG
        sed -i "s/\"wbst_.*\"/${wbstFileName}/g" $SIMRUN_CONFIG

        #Change runmode to logsum 
        sed -i "s/\"simulation\"/\"logsum\"/g" $SIMRUN_CONFIG

        #Copy the right lua scripts to the folder 
        cp $LUA_ORIGIN/luadir_$i/* $LUA_DEST

        #Execute Logsum computation
        date
        echo "Logsum run $i"
	$EXECUTABLE $SIMULATION_CONFIG $SIMRUN_CONFIG  | tee logsum_output_$i.txt
	
	#Change runmode to simulation 
        sed -i "s/\"logsum\"/\"simulation\"/g" $SIMRUN_CONFIG

	#Execute preday simulation
        date
        echo "Simulation run $i"
 	$EXECUTABLE $SIMULATION_CONFIG $SIMRUN_CONFIG | tee simulation_output_$i.txt
       
	#move day activity schedule files to output dir
	mv activity_schedule activity_schedule_$i
        mv activity_schedule_$i  $OUTPUT_FILES_DIR/day_activity_schedule/
        rm activity_schedule*.log

done

#copy back the original simrun_MidTerm config file
cp $SIMRUN_CONFIG_BACKUP $SIMRUN_CONFIG

date
echo "Done!"
