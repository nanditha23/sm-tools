# Construction of Frame of W-Matrix 
# Common lane ID extraction
  args = c('SimMobility/avgVehicleCounts.csv', 'data/TripChain/TripChain.csv',  '/home/simon/Copy/SimMobility/CalibrationProgram/SimMobST_Calibration');   
  
  #args <- commandArgs(trailingOnly = TRUE)
  c(args[1],args[2], args[3])
  
  setwd(args[3])
  SimResult_count <- read.csv(args[1]); 
    SimResult_count <- as.data.table(SimResult_count); colnames(SimResult_count) <- c("Time_ms", "SensorID", "SegID", "LaneID", "Counts")
  SimResult_od <- as.data.table(fread(args[2], sep = ';'))
    temp <- subset(SimResult_od, select=c(trip_id, person_id, trip_start_time, 
                                           subtrip_origin_id, subtrip_destination_id,
                                           sequence_num, travel_mode))  
    # Only car and taxi to be considered
  SimResult_od <- subset(temp , travel_mode=='Car' | travel_mode=='Taxi') 
    
# 1. Reference mat for Count
  Ref_count_Wmat <- as.data.table(unique(SimResult_count$LaneID));  colnames(Ref_count_Wmat) <- c("uniq_LaneID")
  
# 2. Reference mat for OD
  # Code
  code <- paste(SimResult_od$subtrip_origin_id, SimResult_od$subtrip_destination_id, sep = " ")
  SimResult_od <- cbind(SimResult_od, code)
  Ref_od_Wmat <- as.data.table(unique(SimResult_od$code)); colnames(Ref_od_Wmat) <- c("uniq_OD")
  
# 3. Export
  write.table(Ref_count_Wmat, file=paste0(args[3], "/data/Ref_count_Wmat.csv"), row.names=FALSE, col.names=FALSE)
  write.table(Ref_od_Wmat, file=paste0(args[3], "/data/Ref_od_Wmat.csv"), row.names=FALSE, col.names=FALSE)
  
  
  