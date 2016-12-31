  # Set working directory
    setwd('/home/simon/Copy/SimMobility/Calibration Program/SimMob_ST_Calibration_SGE - Simon/SimMobility/')
    
    listoffiles<-list.files(pattern = "VehicleCounts")
  # Instal packages
    #install.packages("data.table")
    library("data.table") # For "data.table" and "fread"
    #install.packages("tidyr")
    library("tidyr") # For "separate"

  f<-1
  data <- fread(list.files(pattern = "VehicleCounts")[f<-1])
  colnames(data) <- c('Time', 'SensorID', 'SegmentID', 'LaneID', 'Count')      
  
  code <- paste(data$Time, data$SensorID, sep=" ")

  start <- proc.time()
    data <- cbind(data, code) 
    unicode <- unique(data$code)
    sortedData <- subset(data, subset=(data$code==unicode[i<-1]))
    data_sorted <- as.data.table(cbind(sortedData$Time[1], sortedData$SensorID[1], sum(sortedData$Count)))

    for (i in 2:length(unicode)){
      sortedData <- subset(data, subset=(data$code==unicode[i]))
      data_sorted_temp <- as.data.table(cbind(sortedData$Time[1], sortedData$SensorID[1], sum(sortedData$Count)))
      data_sorted <- rbind(data_sorted, data_sorted_temp)
    }
  end <- proc.time()
  totaltime <- end[3]-start[3]  
    colnames(data_sorted) <- c('Time','SensorID','AggCount')

    assign(paste("ds", f, sep = "."), data_sorted)

