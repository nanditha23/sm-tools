## Environmental setting
setwd('data/TravelTimeData/')
  #start_time = 6; end_time=7; 
    args <- commandArgs(TRUE)
    start_time = as.numeric(args[1]); end_time=as.numeric(args[2]); 
  interval = 30; 
  
## Data import
  # Simulation data
    SimTT <- read.csv('../../SimMobility_Plus/od_travel_time.csv', header=FALSE, sep=',')
    SimTT <- as.data.frame(SimTT); colnames(SimTT) <-  c('Time', 'Origin', 'Destination', 'TravelTime', 'NoObservation')  
  # Real data (SimMobST_Calibration/data/TravelTimeData/RealData_TravelTime.csv)
    RealTT <- read.csv('RealData_TravelTime.csv', header=FALSE, sep=' ')
    RealTT <- as.data.frame(RealTT); colnames(RealTT) <- c('Time', 'Origin', 'Destination', 'TravelTime', 'NoObservation')  
      
## Time match
    SimTT$Time <- start_time*3600 + (SimTT$Time/(1000*60)-SimTT$Time[1]/(1000*60))*60

## Code (Origin, Destination) match 
  code <- paste(SimTT$Time, SimTT$Origin, SimTT$Destination); SimTT <- cbind(SimTT, code)
  code <- paste(RealTT$Time, RealTT$Origin, RealTT$Destination); RealTT<- cbind(RealTT, code)
    
## Generate vector
  TravelTime <- merge(RealTT, SimTT, by='code', all=FALSE) #FALSE
  compare_TravelTime <- subset(TravelTime, select=c('Time.x', 'Origin.x', 'Destination.x', 'TravelTime.x', 'TravelTime.y'))
  colnames(compare_TravelTime) <- c('Time', 'Origin', 'Destination', 'TravelTime_Real', 'TravelTime_Sim')

  if (dim(compare_TravelTime)[1]!=0) {
    # trueTravelTime
    # simTravelTime
    # truetTavelTime_RM
    trueTravelTime_RM <- as.data.frame(compare_TravelTime$TravelTime_Real)    
    # simTravelTime_RM
    simTravelTime_RM <- as.data.frame(compare_TravelTime$TravelTime_Sim)
  }
  if (dim(compare_TravelTime)[1]==0) {
    # truetTavelTime_RM
    trueTravelTime_RM <- as.data.frame(RealTT$TravelTime)
    # simTravelTime_RM
    simTravelTime_RM <- as.data.frame(RealTT$TravelTime)
  }
  
  ## Save vector
  write.table(trueTravelTime_RM, file='trueTravelTime_RM_Plus.csv', sep = ',', row.names = FALSE, col.names = FALSE) 
  write.table(simTravelTime_RM, file='simTravelTime_RM_Plus.csv', sep = ',', row.names = FALSE, col.names = FALSE) 
  