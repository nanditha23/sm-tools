### GPS Travel-time data analysis
### Avg. Travel-time (N2N_TT)
### Developed by SimMobility ShortTerm Team in Feb, 2016 

## 1. Environmental setting
# Set working directory
  #setwd('/home/simon/Copy/SimMobility/Calibration Program/SimMob_ST_Calibration_SGE - Simon/data/TravelTimeData/')
  setwd('/home/chuyaw/Desktop/SimMobST_Calibration/data/TravelTimeData')
  list.files()
  # Instal packages
  library("data.table") # For "data.table" and "fread" #install.packages("data.table")
  library("tidyr") # For "separate" #install.packages("tidyr")

## 2. Data import
  TTdata <- read.table("travel_time_0108_0508_daily_5min.txt", sep=",", header = TRUE)
  TTdata <- read.table("RealData_TravelTime_30min.csv", sep=",", header = TRUE)
  TTdata <- as.data.table(TTdata)
  
## 3. Processing
  # Time Intervals
  TTdata <- separate(TTdata, col=interval, into=c("Date", "Time"), sep=" ")
    
  # Code
  code <- paste(TTdata$startNodeID, TTdata$endNodeID)
  TTdata <- cbind(TTdata, code)

  # EigenCode
  EigenCode <- paste(TTdata$code, TTdata$Time) #  6391
  TTdata <- cbind(TTdata, EigenCode)
  uniEigen <- unique(TTdata$EigenCode) # 6352
  
  # using unique T and Code
  i<-1; #<length(TTdata$EigenCode)
  TravelTime <- TTdata[which(TTdata$EigenCode==uniEigen[i]),]  
  
  for (i in 2:length(uniEigen)){ #i<-19 length(EigenCode)
    TravelTime_temp <- TTdata[which(TTdata$EigenCode==uniEigen[i]),]  
      if(dim(TravelTime_temp)[1]==1){ # for single travel-time data for specific Time and Code combination
        TravelTime <- rbind(TravelTime, TravelTime_temp)
      }else{
        TT_val <- sum(TravelTime_temp$observations*TravelTime_temp$TravelTime)/(sum(TravelTime_temp$observations))
        Obs_val <-sum(TravelTime_temp$observations)
        TravelTime_temp <- TravelTime_temp[1,]
        
          TravelTime_temp$observations <- Obs_val
          TravelTime_temp$TravelTime <- TT_val
        
        TravelTime <- rbind(TravelTime, TravelTime_temp)
      }
    }      
  
## 4. Export: N2N_TT
  write.csv(TravelTime, file="RealData_TravelTime.csv")
  
  
  
  