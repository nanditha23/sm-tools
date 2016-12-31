### GPS Travel-time data analysis
### Avg. Travel-time (N2N_TT)
### Developed by SimMobility ShortTerm Team in Feb, 2016 

## 1. Environmental setting
# Set working directory
  setwd('/home/chuyaw/Desktop/SimMobST_Calibration/data/TravelTimeData/')
  #setwd('/home/Shahita/Desktop/TravelTimeData')
  list.files()
  # Instal packages
  library("data.table") # For "data.table" and "fread" #install.packages("data.table")
  library("tidyr") # For "separate" #install.packages("tidyr")

## 2. Data import
  TTdata <- read.table("RealData_TravelTime_30min.csv", sep=",", header = TRUE)
  TTdata <- as.data.table(TTdata)
  
## 3. Processing
      # Time Intervals
      time <- strsplit(as.character(TTdata$interval), ":")
      TimeConverter <- function(time){
        time <- as.numeric(time)
        time[1]*3600+time[2]*60+time[3]
      }  
      intervaltime <- sapply(time, TimeConverter) 
      TTdata$interval <- intervaltime # Inserting changed time format 
    
      # Column rearrange consistent with simulation output: time, ori, des, tt, obs  
      TTdata <- subset(TTdata, select=c("interval", "startNode", "endNode", "travelTime", "noObservation"))
      colnames(TTdata) <- c('Time', 'Origin', 'Destination', 'TravelTime', 'NoObservation')
  
## 4. Preprocessing of TT data 
  # 4.1 Extract only ext cbd
  extcbd <- read.table('extcbdnodes.csv', header=TRUE)
  TTdata <- TTdata[(TTdata$Origin %in% extcbd$id & TTdata$Destination %in% extcbd$id),]
  
  # 4.2 complete set
  code <- paste(TTdata$Origin, TTdata$Destination, sep=" ")
  TTdata <- cbind(TTdata, code)
  
  StartingEndTime <- as.data.frame(c('06:00:00', '10:00:00')); colnames(StartingEndTime) <- c('Time')
  time <- strsplit(as.character(StartingEndTime$Time), ":")
  StartingEndTime <- sapply(time, TimeConverter)
  
  Ref_time <- seq(StartingEndTime[1], StartingEndTime[2], by=30*60)
  
  unicode <- unique(paste(TTdata$Origin, TTdata$Destination, sep=" "))
#   t1 <- proc.time()[3]
#   Candidate = TTdata[-seq(1, dim(TTdata)[1]),]; #CandidateCode = array(0)
#   for (i in 1:length(unicode)){  #
#     Candidate_temp <- TTdata[TTdata$code %in%  unicode[i]];
#     if (Candidate_temp$Time[1] >= Ref_time[1] & dim(Candidate_temp)[1] >= length(Ref_time))
#     {Candidate <- rbind(Candidate, Candidate_temp)}
#     #print(i)
#   }
#   t2 <- proc.time()[3]
#   t21 <- t2-t1; t21
#   write.csv(Candidate, file='CandidateTT.csv', row.names = FALSE)

  
## -------------------------------
  TTdata <- read.table("RealData_TravelTime_30min.csv", sep=",", header = TRUE)
  TTdata <- as.data.table(TTdata)
  
  CandidateTT <- read.table('CandidateTT.csv', header=TRUE, sep=',');
  CandidateTT <- as.data.table(CandidateTT);
  
  unicode <- unique(CandidateTT$code)
  
  CandidateTT
  i<-1
  TTdata_reorg <- CandidateTT[CandidateTT$code %in% unicode[i]];
  temp1 <- CandidateTT[CandidateTT$Time %in% Ref_time[1]]; 
  temp2 <- CandidateTT[CandidateTT$Time %in% Ref_time[2]]; 
  temp3 <- CandidateTT[CandidateTT$Time %in% Ref_time[3]]; 
  temp4 <- CandidateTT[CandidateTT$Time %in% Ref_time[4]]; 
  temp5 <- CandidateTT[CandidateTT$Time %in% Ref_time[5]]; 
  temp6 <- CandidateTT[CandidateTT$Time %in% Ref_time[6]]; 
  temp7 <- CandidateTT[CandidateTT$Time %in% Ref_time[7]]; 
  temp8 <- CandidateTT[CandidateTT$Time %in% Ref_time[8]]; 
  temp9 <- CandidateTT[CandidateTT$Time %in% Ref_time[9]]; 
  
  #ShortList <- Reduce(intersect, list(temp1$code, temp2$code, temp3$code, temp4$code, temp5$code, temp6$code, temp7$code, temp8$code, temp9$code))
  ShortList <- Reduce(intersect, list(temp1$code, temp2$code))
  #ShortList <- Reduce(intersect, list(temp1$code))
  ShortList_data <- CandidateTT[CandidateTT$code %in% ShortList]; 
  
  ShortList_data <- ShortList_data[ShortList_data$Time %in% Ref_time]; 
    
  #write.csv(ShortList_data, file='ShortList_data.csv')
  
  write.table(subset(ShortList_data, select=-code), file='RealData_TravelTime.csv', row.names=FALSE, col.names=FALSE)
  
## 5. Export: N2N_TT
  #write.csv(TTdata, file="RealData_TravelTime_30min.csv", row.names=FALSE)
    
## 6. Ref_od_Traveltime  
  ShortList <- as.data.table(ShortList);
  ShortList <- separate(ShortList, col=ShortList, into=c("Origin", "Destination"), sep=" ")  
  ShortList <- lapply(ShortList, as.numeric)
  write.csv(ShortList, file="Ref_od_Traveltime.csv", row.names=FALSE)
  
  
  
  length((unique(TTdata$Time)/1800))
  hist(unique(TTdata$Time)/1800, 48)
  