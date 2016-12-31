## Environmental setting
#setwd('~/Desktop/0_SimMobST_Calibration/data/TravelTimeData/')
setwd('~/SimMobST_Calibration/data/TravelTimeData/')
  start_time = 6; end_time=7; 
  #  args <- commandArgs(TRUE)
  #  start_time = as.numeric(args[1]); end_time=as.numeric(args[2]); 
  interval = 15; 
  
## Data import
  # Simulation data
    SimTT <- read.csv('../../SimMobility_SPSA/od_travel_time.csv', header=FALSE, sep=',')
    SimTT <- as.data.frame(SimTT); colnames(SimTT) <-  c('Time', 'Origin', 'Destination', 'TravelTime', 'NoObservation')  
  # Real data (SimMobST_Calibration/data/TravelTimeData/RealData_TravelTime.csv)
    #RealTT <- read.csv('RealData_TravelTime.csv', header=FALSE, sep=' ')
    #RealTT <- read.csv('RealData_TravelTime_30min_with1294.csv')
    load('New_RealData_TravelTime_CBD.RData'); RealTT <- Data_des; rm(Data_des)
    RealTT <- as.data.frame(RealTT); colnames(RealTT) <- c('Time', 'Origin', 'Destination', 'TravelTime', 'Var', 'NoObservation')  

## Time match
    SimTT$Time <- start_time*3600 + (SimTT$Time/(1000*60)-SimTT$Time[1]/(1000*60))*60

    RealTT <- RealTT[which(RealTT$Time %in% unique(SimTT$Time)),]

## Code (Origin, Destination) match 
  code <- paste(SimTT$Time, SimTT$Origin, SimTT$Destination); SimTT <- cbind(SimTT, code)
  code <- paste(RealTT$Time, RealTT$Origin, RealTT$Destination); RealTT<- cbind(RealTT, code)

## Generate vector
  TravelTime <- merge(RealTT, SimTT, by='code', all=FALSE) #FALSE
  TravelTime_Syn <- merge(RealTT, SimTT, by='code', all.x = TRUE)
  
  compare_TravelTime <- subset(TravelTime, select=c('Time.x', 'Origin.x', 'Destination.x', 'TravelTime.x', 'TravelTime.y', 'Var', 'NoObservation.x'))
  colnames(compare_TravelTime) <- c('Time', 'Origin', 'Destination', 'TravelTime_Real', 'TravelTime_Sim', 'Real_Var', 'Real_Obs')

  compare_TravelTime_Syn <- subset(TravelTime_Syn, select=c('Time.x', 'Origin.x', 'Destination.x', 'TravelTime.x', 'TravelTime.y', 'Var', 'NoObservation.x'))
  colnames(compare_TravelTime_Syn) <- c('Time', 'Origin', 'Destination', 'TravelTime_Real', 'TravelTime_Sim', 'Real_Var', 'Real_Obs')

  #compare_TravelTime_Syn$TravelTime_Sim[is.na(compare_TravelTime_Syn$TravelTime_Sim)] <- 0
  compare_TravelTime_Syn$TravelTime_Sim[is.na(compare_TravelTime_Syn$TravelTime_Sim)] <- compare_TravelTime_Syn$TravelTime_Real[is.na(compare_TravelTime_Syn$TravelTime_Sim)]

  # truetTavelTime
  trueTravelTime <- as.data.frame(compare_TravelTime_Syn$TravelTime_Real)    
  # simTravelTime
  simTravelTime <- as.data.frame(compare_TravelTime_Syn$TravelTime_Sim)
  # truetTavelTime_RM
  trueTravelTime_RM <- as.data.frame(compare_TravelTime$TravelTime_Real)    
  # simTravelTime_RM
  simTravelTime_RM <- as.data.frame(compare_TravelTime$TravelTime_Sim)
  # Real_Var
  trueTravelTime_Var <- as.data.frame(compare_TravelTime_Syn$Real_Var)    
  # Real_Obs
  trueTravelTime_Obs <- as.data.frame(compare_TravelTime_Syn$Real_Obs)    
  
  ## Save vector
  write.table(trueTravelTime, file='trueTravelTime_SPSA.csv', sep = ',', row.names = FALSE, col.names = FALSE) 
  write.table(simTravelTime, file='simTravelTime_SPSA.csv', sep = ',', row.names = FALSE, col.names = FALSE) 
  write.table(trueTravelTime_RM, file='trueTravelTime_RM_SPSA.csv', sep = ',', row.names = FALSE, col.names = FALSE) 
  write.table(simTravelTime_RM, file='simTravelTime_RM_SPSA.csv', sep = ',', row.names = FALSE, col.names = FALSE) 
  write.table(trueTravelTime_Var, file='trueTravelTime_Var_SPSA.csv', sep = ',', row.names = FALSE, col.names = FALSE) 
  write.table(trueTravelTime_Obs, file='trueTravelTime_Obs_SPSA.csv', sep = ',', row.names = FALSE, col.names = FALSE) 


  