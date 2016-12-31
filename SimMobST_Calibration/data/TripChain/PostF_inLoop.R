setwd('/home/chuyaw/SimMobST_Calibration/data/TripChain')
#setwd('/home/neeraj/calib2/SimMobST_Calibration/data/TripChain')
#setwd('data/TripChain/')

list.files()

ODdata <- read.csv('ODdata.csv', header=FALSE, sep = ' '); colnames(ODdata) <- c('Index', 'Node_O', 'Node_D', 'Zone_O', 'Zone_D', 'Trips', 'Time')
#theta_OD_dash <- read.csv('Truncated_theta_od.csv', header=FALSE, sep = ' '); colnames(theta_OD_dash) <- c('Trips')
theta_OD_dash <- read.table('theta_OD.csv', header=FALSE); colnames(theta_OD_dash) <- c('Trips')

ODdata$Trips <- theta_OD_dash$Trips; 

# Possible Set
ODdata <- cbind(ODdata, paste(ODdata$Node_O, ODdata$Node_D)); colnames(ODdata) <- c('Index', 'Node_O', 'Node_D', 'Zone_O', 'Zone_D', 'Trips', 'Time', 'Code')
PossibleSet <- unique(ODdata$Code)

length(PossibleSet)*4

# Regarding Starting Point
# Number of Starting Point
  head(ODdata)
  SPset <-  unique(ODdata$Node_O)
  UniTime <- unique(ODdata$Time)
  q <- 50 # Originally it was 1000
  QC <- 2*q/4 #(3lanes * 900(veh/h) * (15/60h))

  i <- 1; j <- 1;
  SPset_data <- subset(ODdata, subset=(ODdata$Node_O==SPset[i])); SPset_data <- subset(SPset_data, subset=(SPset_data$Time==UniTime[j])); SPset_data_time <- SPset_data
  sum(SPset_data_time$Trips) # 932 >>> QC
  if (sum(SPset_data_time$Trips)>QC){
    portion <- SPset_data_time$Trips/sum(SPset_data_time$Trips)
    SPset_data_time$Trips <- round(portion*QC)
  }
  if (sum(SPset_data_time$Trips)<=QC){ SPset_data_time$Trips <- SPset_data_time$Trips  }
  trODdata <- SPset_data_time

  for (j in 2:length(UniTime)){
    SPset_data <- subset(ODdata, subset=(ODdata$Node_O==SPset[i])); SPset_data <- subset(SPset_data, subset=(SPset_data$Time==UniTime[j])); SPset_data_time <- SPset_data    
    #sum(SPset_data_time$Trips) # 932 >>> QC
    if (sum(SPset_data_time$Trips)>QC){
      portion <- SPset_data_time$Trips/sum(SPset_data_time$Trips)
      SPset_data_time$Trips <- round(portion*QC)    }
    if (sum(SPset_data_time$Trips)<=QC){ SPset_data_time$Trips <- SPset_data_time$Trips }  
    trODdata <- rbind(trODdata, SPset_data_time)
  }
  
  for (i in 2:length(SPset)){
    j <- 1; SPset_data <- subset(ODdata, subset=(ODdata$Node_O==SPset[i])); SPset_data <- subset(SPset_data, subset=(SPset_data$Time==UniTime[j])); SPset_data_time <- SPset_data
    #sum(SPset_data_time$Trips) # 932 >>> QC
    if (sum(SPset_data_time$Trips)>QC){
      portion <- SPset_data_time$Trips/sum(SPset_data_time$Trips)
      SPset_data_time$Trips <- round(portion*QC)
    }
    if (sum(SPset_data_time$Trips)<=QC){ SPset_data_time$Trips <- SPset_data_time$Trips  }
    trODdata_temp <- SPset_data_time
    
    for (j in 2:length(UniTime)){
      SPset_data <- subset(ODdata, subset=(ODdata$Node_O==SPset[i])); SPset_data <- subset(SPset_data, subset=(SPset_data$Time==UniTime[j])); SPset_data_time <- SPset_data    
      #sum(SPset_data_time$Trips) # 932 >>> QC
      if (sum(SPset_data_time$Trips)>QC){
        portion <- SPset_data_time$Trips/sum(SPset_data_time$Trips)
        SPset_data_time$Trips <- round(portion*QC)    }
      if (sum(SPset_data_time$Trips)<=QC){ SPset_data_time$Trips <- SPset_data_time$Trips }  
      trODdata_temp <- rbind(trODdata_temp, SPset_data_time)
    }
    trODdata <- rbind(trODdata, trODdata_temp)
  }
 
ODdata <- cbind(ODdata, paste(ODdata$Time, ODdata$Code), seq(1, dim(ODdata)[1]));  colnames(ODdata) <- c('Index', 'Node_O', 'Node_D', 'Zone_O', 'Zone_D', 'Trips', 'Time', 'Code', 'RealCode', 'Seq')
trODdata <- cbind(trODdata, paste(trODdata$Time, trODdata$Code)); colnames(trODdata) <- c('Index', 'Node_O', 'Node_D', 'Zone_O', 'Zone_D', 'Trips', 'Time', 'Code', 'RealCode')

# As original sequence of OD data
trODdata_temp <- merge(ODdata, trODdata, by= 'RealCode', sort= T)
TruncatedODdata <- trODdata_temp[,c(2:7, 16, 8, 10)]
#TruncatedODdata <- subset(trODdata_temp, select=c('Index.x', 'Node_O.x', 'Node_D.x', 'Zone_O.x', 'Zone_D.x', 'Trips.x', 'Trips.y', 'Time.x', 'Seq'))
  colnames(TruncatedODdata) <-  c('Index', 'Node_O', 'Node_D', 'Zone_O', 'Zone_D', 'Trips', 'trTrips',  'Time', 'Seq')

TruncatedODdata <- TruncatedODdata[order(TruncatedODdata$Seq),]
#TruncatedODdata$trTrips <- 2
Truncated_theta_od = subset(TruncatedODdata, select=c('trTrips'))
TruncatedODdata <- subset(TruncatedODdata, select=-c(Trips, Seq))

# Write.csv
# ODdata
  #write.table(TruncatedODdata, file='TruncatedODdata.csv', row.names=FALSE, col.names=FALSE)
  write.table(Truncated_theta_od, file='Truncated_theta_od.csv', row.names=FALSE, col.names=FALSE)

# Reference OD pair
  #Ref_od_Wmat <- data.frame(unique(paste(TruncatedODdata$Node_O, TruncatedODdata$Node_D)))
  #write.table(Ref_od_Wmat, file='Ref_od_Wmat.csv')

#   plot(TruncatedODdata$Trips-TruncatedODdata$trTrips)
# 
#   plot(TruncatedODdata$Trips, ylim=c(0, 650), ylab=c('# of trips'))
#   plot(TruncatedODdata$trTrips, ylim=c(0, 650), ylab=c('# of trips'))
# 
#   sum(TruncatedODdata$Trips)-sum(TruncatedODdata$trTrips)
#   sum(TruncatedODdata$trTrips)/sum(TruncatedODdata$Trips)*100



