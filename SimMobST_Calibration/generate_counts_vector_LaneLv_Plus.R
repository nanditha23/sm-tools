start_time = 6*60; 
end_time = 7*60; 
interval = 5;
warm_up_intervals = 0;

start_interval_slot = (start_time/interval) + warm_up_intervals;
end_interval_slot = end_time / interval;
last_sim_interval = ((end_time-start_time)*60*1000) - 1000;

    get_interval_sim <- function(curr_time){
      start_time = 6*60; 
      end_time = 7*60; 
      interval = 5;
      warm_up_intervals = 0;
      
      start_interval_slot = (start_time/interval) + warm_up_intervals;
      end_interval_slot = end_time / interval;
      last_sim_interval = ((end_time-start_time)*60*1000) - 1000;
      
      if (curr_time == last_sim_interval){
        curr_time = curr_time+1000;}
        mins = (curr_time/(1000*60))
        return (start_interval_slot + (mins/interval)-1)
      }
    
    get_interval_real <- function(curr_time){
      mins = curr_time/60;
      return (mins/interval)
    }

sim_vehicle_counts <- read.table('SimMobility_Plus/avgVehicleCounts.csv', sep = ',')
real_vehicle_counts <- load('data/SensorMapping/RealData_sec_LaneLv5min_Var.RData'); real_vehicle_counts <- Data_avg; rm(Data_avg)
colnames(sim_vehicle_counts) <- c('Time', 'SensorID', 'SegID', 'LaneID', 'Count')
colnames(real_vehicle_counts) <- c('Time', 'SensorID', 'SegID', 'LaneID', 'Count', 'Var', 'Obs')

# Time convert
  sim_vehicle_counts$Time <- sapply(sim_vehicle_counts$Time, get_interval_sim)
  real_vehicle_counts$Time <- sapply(real_vehicle_counts$Time, get_interval_real)

# Mapping on lane level
  # Change lane id of ST to 
  ReferenceTable_STlaneID <- read.table('ReferenceTable_STlaneID.csv', sep=',', header=TRUE) 
  colnames(ReferenceTable_STlaneID) <- c('Original', 'Corrected')

  i <- 1; tempID <- ReferenceTable_STlaneID$Original[i];
  sim_vehicle_counts[(sim_vehicle_counts$LaneID %in% tempID),]$LaneID <- ReferenceTable_STlaneID$Corrected[i]
  for (i in 2:dim(ReferenceTable_STlaneID)[1]){
    tempID <- ReferenceTable_STlaneID$Original[i];
    sim_vehicle_counts[(sim_vehicle_counts$LaneID %in% tempID),]$LaneID <- ReferenceTable_STlaneID$Corrected[i]  
  }

  # Uni code
  uni_code_lane_sim <- as.data.frame(paste(sim_vehicle_counts$Time, sim_vehicle_counts$LaneID)); colnames(uni_code_lane_sim) <- c('Code')
  uni_code_lane_real <- as.data.frame(paste(real_vehicle_counts$Time, real_vehicle_counts$LaneID)); colnames(uni_code_lane_real) <- c('Code')
  sim_vehicle_counts <- cbind(sim_vehicle_counts, uni_code_lane_sim)
  real_vehicle_counts <- cbind(real_vehicle_counts, uni_code_lane_real)

  # Merging
  Data_merge <- merge(sim_vehicle_counts, real_vehicle_counts, by='Code', all=FALSE)
  #Data_merge <- subset(Data_merge, select = c('Time.x', 'SensorID.x', 'SegID.x', 'LaneID.x', 'Count.x', 'Count.y'))
  Data_merge <- subset(Data_merge, select = c('Time.x', 'SensorID.x', 'SegID.x', 'LaneID.x', 'Count.x', 'Count.y', 'Var', 'Obs'))
  colnames(Data_merge) <- c('Time', 'SensorID', 'SegID', 'LaneID', 'Count_Sim', 'Count_Real', 'Var_Real', 'Obs_Real')
  #Data_Seg <- as.data.frame(Data_merge)

# # Segment lv. 
#   uniSeg <- unique(Data_merge$SegID); uniTime <- unique(Data_merge$Time)
#   i<-1; j<-1;
#   Data_Seg <- subset(Data_merge, subset=(SegID==uniSeg[i] & Time==uniTime[j]))
#   Data_Seg_temp <- append(append(Data_Seg$Time[1], Data_Seg$Seg[1]),  append(sum(Data_Seg$Count_Sim), sum(Data_Seg$Count_Real)))
#   for (j in 2:length(uniTime)){
#     Data_Seg <- subset(Data_merge, subset=(SegID==uniSeg[i] & Time==uniTime[j]))
#     Data_Seg_temp_temp <- append(append(Data_Seg$Time[1], Data_Seg$Seg[1]),  append(sum(Data_Seg$Count_Sim), sum(Data_Seg$Count_Real)))    
#     Data_Seg_temp <- rbind(Data_Seg_temp, Data_Seg_temp_temp)
#   }
#   for (i in 2:length(uniSeg)){
#     j<-1
#     Data_Seg <- subset(Data_merge, subset=(SegID==uniSeg[i] & Time==uniTime[j]))
#     Data_Seg_temp2 <- append(append(Data_Seg$Time[1], Data_Seg$Seg[1]),  append(sum(Data_Seg$Count_Sim), sum(Data_Seg$Count_Real)))
#     for (j in 2:length(uniTime)){
#       Data_Seg <- subset(Data_merge, subset=(SegID==uniSeg[i] & Time==uniTime[j]))
#       Data_Seg_temp_temp <- append(append(Data_Seg$Time[1], Data_Seg$Seg[1]),  append(sum(Data_Seg$Count_Sim), sum(Data_Seg$Count_Real)))    
#       Data_Seg_temp2 <- rbind(Data_Seg_temp2, Data_Seg_temp_temp)
#     }
#     Data_Seg_temp <- rbind(Data_Seg_temp, Data_Seg_temp2)
#   }
# colnames(Data_Seg_temp) <- c('Time', 'SegID', 'Count_Sim', 'Count_Real')
# rownames(Data_Seg_temp) <- seq(1:dim(Data_Seg_temp)[1])
# Data_Seg <- as.data.frame(Data_Seg_temp)

Data_Seg <- as.data.frame(Data_merge)

# How to NA values
  assumedCOV=0.2; 
  Data_Seg$Var_Real[is.na(Data_Seg$Var_Real)] <- Data_Seg$Count_Real[is.na(Data_Seg$Var_Real)]*assumedCOV
  Data_Seg$Var_Real[which(Data_Seg$Var_Real==0)] <- 1

# File export
  # data/truecount_Plus.csv
  write.table(Data_Seg$Count_Real, file='data/truecount_Plus.csv', row.names = F, col.names=F)
  # data/simcount_Plus.csv
  write.table(Data_Seg$Count_Sim, file='data/simcount_Plus.csv', row.names = F, col.names=F)
  # data/trueCountsRM_Plus.csv
  write.table(Data_Seg$Count_Real, file='data/trueCountsRM_Plus.csv', row.names = F, col.names=F)
  # data/simCountsRM_Plus.csv
  write.table(Data_Seg$Count_Sim, file='data/simCountsRM_Plus.csv', row.names = F, col.names=F)
  # data/compare_counts_Plus.csv
  write.table(Data_Seg, file='data/compare_counts_Plus.csv', row.names = F, col.names=F)
  # data/trueCountsVar_Plus.csv
  write.table(Data_Seg$Var_Real, file='data/trueCountsVar_Plus.csv', row.names = F, col.names=F)
  # data/trueCountsObs_Plus.csv
  write.table(Data_Seg$Obs_Real, file='data/trueCountsObs_Plus.csv', row.names = F, col.names=F)
  