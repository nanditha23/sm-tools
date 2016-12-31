### WG-function
### This function generates Weighting Matrix for W-SPSA function implementation
### Input: i) start_hr~end_hr, ii) Interval of ODdata, iii) Interval of sensor data 
### Output: i) Weighting matrix (wmatrix.dat)
### Requirements: i) Assingment matrix and ii) OD pair information
### Edited by SimMobility ShortTerm Team in Feb, 2016 

comtime1<-proc.time()[3]
# Environmental setting
library("data.table") # For "data.table" and "fread" #install.packages("data.table")
  start_hr <- 6; end_hr <- 6.5 # Previously, start = 10; end = 11; 
  interval_od_min <- 15; interval_sensor_min <- 5; 
  
  wd <- c("/home/simon/Copy/SimMobility/CalibrationProgram/SimMobST_Calibration/"); setwd(wd)

  Ref_count_Wmat <- fread('data/Ref_count_Wmat.csv', header=FALSE);
    no_sensor <- dim(Ref_count_Wmat)[1] # no_sensor <- 2732; # no_sensor revise!!

  Ref_od_Wmat <- fread('data/Ref_od_Wmat.csv', header=FALSE);
    no_od <- dim(Ref_od_Wmat)[1] # no_sensor <- 2732; # no_sensor revise!!

  #commonIDs <- fread('data/commonIDs.csv', header=FALSE);
  #no_sensor <- dim(commonIDs)[1] # no_sensor <- 2732; # no_sensor revise!!

# PARAMETER TO BE REVISED
  # Input: as input parameter
  start <- start_hr*60*60 # 10AM (unit: sec)
  end <- end_hr*60*60 # 11AM (unit: sec)
  interval_od <- interval_od_min*60 # time interval: 15min -> 900sec
  interval_sensor <-  interval_sensor_min*60  # time interval: 5min -> 900sec
  no_sensor <-  no_sensor # To be defined
    
# Time interval
  no_interval_od = (end-start)/interval_od; # Classify simulation time into each time interval
  no_interval_sensor = (end-start)/interval_sensor;
  
  ass <- fread("SimMobility/assignment_matrix.csv", sep=",", header=FALSE) # Assignment matrix from SimMobility
    colnames(ass) <- c('sensorID', 'SegID', 'LaneID', 'sensor_time','agent_id','origin_id','destination_id', 'trip_start_time')
  ass <- subset(ass, select=c(-sensorID, -SegID))
  head(ass)

  odpair <- fread("data/TripChain/ODpair.csv") 
    #odpair <- fread("WMATRIX/baseFile.csv")
    #colnames(odpair) <- c('zonecode', 'zone_o', 'zone_d', 'index_forzone')
  colnames(odpair) <- c('index_a', 'subtrip_origin_id', 'subtrip_destination_id', 'zone_o', 'zone_d')
  odpair <- subset(odpair, select=c('subtrip_origin_id', 'subtrip_destination_id'))

    #odpair <- subset(odpair, select=c('V2', 'V3'))
  #no_od = length(odpair[[1]])
  
  cat("Initializing ODs ..")
  t_od <- array(0, dim=no_interval_od);
  t_od[1] = start;
  for (i in 2:no_interval_od){
    t_od[i] = t_od[i-1] + interval_od;
  }
  
  cat("Initializing sensors ..")
  t_sensor <- array(0, dim=no_interval_sensor);
  t_sensor[1] = start;  
  for (i in 2:no_interval_sensor){
    t_sensor[i] = t_sensor[i-1] + interval_sensor;
  } 
  
  # Convert of time in assignment matrix 
  ass$sensor_time <- round(ass$sensor_time/1000+t_sensor[1])
  ass$trip_start_time <- round(ass$trip_start_time/1000+t_od[1])

  wmatrix = array(0, dim=c(no_sensor*no_interval_sensor, no_od*no_interval_od)); # 16392 by 33310
  
  code <- paste(ass$origin_id, ass$destination_id)
  ass <- cbind(ass, code)

  cat("Generating weight matrix ..")
  for (j in 1:length(ass[[1]])){ # 671988 j<-1
    sensor_index = which(ass[[1]][j] == Ref_count_Wmat$V1)
    #od_index = which(odpair[[1]] == ass[[4]][j] & odpair[[2]] == ass[[5]][j])
    od_index = which(ass[[7]][j] == Ref_od_Wmat)
    
    #intersect(odpair[[1]], ass[[4]])
    #intersect(odpair[[2]], ass[[5]])
    
    time_index_sensor = which(ass[[2]][j]>=t_sensor & ass[[2]][j]<t_sensor+interval_sensor)
    time_index_od = which(ass[[6]][j]>=t_od & ass[[6]][j]<t_od+interval_od)
    row = sensor_index+no_sensor*(time_index_sensor-1)
    col = od_index+no_od*(time_index_od-1)
    
    wmatrix[row,col] = wmatrix[row,col]+1 }
  
  cat("Post Processing ..")
  wmatrix=t(wmatrix);
  
  for (i in 1:nrow(wmatrix)){ 
    if (sum(wmatrix[i,]) != 0) {wmatrix[i,]=wmatrix[i,]/sum(wmatrix[i,])}
  }

comtime2<- proc.time()[3]
comtime <- comtime2-comtime1

  od_id=array(1:(no_od*no_interval_od), dim=c((no_od*no_interval_od),1));
  result=cbind(od_id,wmatrix);
  
  write.table(result,file="data/WMATRIX/wmatrix.dat",row.names = FALSE, col.names = FALSE)
  cat(" Weight matrix generation done ")

  write.table(wmatrix[1:10,], file="JustFirstRowWmat.csv")

