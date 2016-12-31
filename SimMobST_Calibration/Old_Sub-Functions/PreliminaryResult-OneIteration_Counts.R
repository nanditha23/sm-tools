### Preliminary Result for One Iteration
### Comparison between simulated counts and real data 
### Developed by SimMobility ShortTerm Team in Feb, 2016 

## 1. Environmental setting
setwd("/home/simon/Copy/SimMobility/CalibrationProgram/SimMobST_Calibration/")
  SimResult <- read.csv(file = 'RESULT/avgVehicleCounts_1.csv')
    colnames(SimResult) <- c("Time_ms", "SensorID", "SegID", "LaneID", "Counts")
  RealData <- read.csv("RESULT/RealData_sec.csv", sep=" ")
    colnames(RealData) <- c("Time", "SensorID", "SegID", "LaneID", "Counts")
  dim(SimResult)
  dim(RealData)
  length(unique(SimResult$LaneID))
  
  ## 2. Preprocessing
  # Simulation Result Ordering according to the Time
  SimResult_ordered <- SimResult[order(SimResult$Time_ms),]
  head(SimResult_ordered)
    length(unique(RealData$Time))
    length(unique(SimResult$Time_ms))
  
  # Time convert of Real data: sec -> ms 
  head(RealData)
  head(SimResult_ordered)
  rate <- unique(SimResult_ordered$Time_ms)/unique(RealData$Time)
    
  for (i in 1:length(rate)){
    RealData[which(RealData$Time==unique(RealData$Time)[i]),]$Time <- (RealData[which(RealData$Time==unique(RealData$Time)[i]),]$Time)*rate[i]  
  }
  
  for (i in 1:length(rate)){
    RealData[which(RealData$Time==unique(RealData$Time)[i]),]$Time <- unique(SimResult_ordered$Time)[i]
  }
  
## 3. Accuracy
  Ref_Time <- unique(RealData$Time)
  Ref_LaneID <- intersect(RealData$LaneID, SimResult_ordered$LaneID)
    Ref_LaneID <- Ref_LaneID[order(Ref_LaneID)]
  
  # RMSN: for Whole network according to time
  t <- 1 # t<-12
  l <- 1 # l<-1901
  
  temp_real <- subset(RealData, subset=(RealData$Time==Ref_Time[t] & RealData$LaneID==Ref_LaneID[l]))[1,] # Issue!!! 
  temp_sim <-  subset(SimResult_ordered, subset=(SimResult_ordered$Time==Ref_Time[t] & SimResult_ordered$LaneID==Ref_LaneID[l]))  
  diff_temp <- temp_real$Counts-temp_sim$Counts
  diff <- diff_temp*diff_temp
  #diff <- sqrt(diff_temp*diff_temp)
  DIFF <- as.data.frame(cbind(Ref_Time[t], diff))
  gap <- temp_real$Counts-temp_sim$Counts
  real <- temp_real$Counts
  forccplot <- as.data.frame(cbind(temp_real$Counts, temp_sim$Counts)); colnames(forccplot) <- c('Real','Sim')
  
  for (l in 2:length(Ref_LaneID)){ #l<- 1654
    #t<-1; l<-2
    temp_real <- subset(RealData, subset=(RealData$Time==Ref_Time[t] & RealData$LaneID==Ref_LaneID[l]))[1,] # Issue!!! 
    temp_sim <-  subset(SimResult_ordered, subset=(SimResult_ordered$Time==Ref_Time[t] & SimResult_ordered$LaneID==Ref_LaneID[l]))
    if (dim(temp_sim)[1]!=0 & rownames(temp_real)!="NA"){
      diff_temp <- temp_real$Counts-temp_sim$Counts
      diff <- diff_temp*diff_temp
      #diff <- sqrt(diff_temp*diff_temp)
      DIFF_temp <- as.data.frame(cbind(Ref_Time[t], diff))
      DIFF <- rbind(DIFF, DIFF_temp) 
      gap_temp <- temp_real$Counts-temp_sim$Counts
      gap <- rbind(gap, gap_temp)
      real_temp <- temp_real$Counts
      real <- rbind(real, real_temp)
      forccplot_temp <- as.data.frame(cbind(temp_real$Counts, temp_sim$Counts)); colnames(forccplot_temp) <- c('Real','Sim')
      forccplot <- rbind(forccplot, forccplot_temp)
    }
  }
  RMSN <- sum(sqrt(DIFF$diff), na.rm=TRUE)/sum(real[,1], na.rm=TRUE)
  #RMSN <- sum(DIFF$diff, na.rm = TRUE)/length(DIFF$diff)
  GAPP <- gap
  FORCCPLOT <- forccplot
  
  for (t in 2:length(Ref_Time)){
    #t<-2
    l <- 1
    temp_real <- subset(RealData, subset=(RealData$Time==Ref_Time[t] & RealData$LaneID==Ref_LaneID[l]))[1,] # Issue!!! 
    temp_sim <-  subset(SimResult_ordered, subset=(SimResult_ordered$Time==Ref_Time[t] & SimResult_ordered$LaneID==Ref_LaneID[l]))  
    if (dim(temp_sim)[1]!=0 & rownames(temp_real)!="NA"){
    diff_temp <- temp_real$Counts-temp_sim$Counts
    diff <- diff_temp*diff_temp
    #diff <- sqrt(diff_temp*diff_temp)
    DIFF <- as.data.frame(cbind(Ref_Time[t], diff))
    gap <- temp_real$Counts-temp_sim$Counts
    real <- temp_real$Counts
    forccplot <- as.data.frame(cbind(temp_real$Counts, temp_sim$Counts)); colnames(forccplot) <- c('Real','Sim')
    }
    for (l in 2:length(Ref_LaneID)){
      #t<-1; l<-2
      temp_real <- subset(RealData, subset=(RealData$Time==Ref_Time[t] & RealData$LaneID==Ref_LaneID[l]))[1,] # Issue!!! 
      temp_sim <-  subset(SimResult_ordered, subset=(SimResult_ordered$Time==Ref_Time[t] & SimResult_ordered$LaneID==Ref_LaneID[l]))  
      if (dim(temp_sim)[1]!=0 & rownames(temp_real)!="NA"){
      diff_temp <- temp_real$Counts-temp_sim$Counts
      diff <- diff_temp*diff_temp
      #diff <- sqrt(diff_temp*diff_temp)
      DIFF_temp <- as.data.frame(cbind(Ref_Time[t], diff))
      DIFF <- rbind(DIFF, DIFF_temp)
      gap_temp <- temp_real$Counts-temp_sim$Counts
      gap <- rbind(gap, gap_temp)
      real_temp <- temp_real$Counts
      real <- rbind(real, real_temp)
      forccplot_temp <- as.data.frame(cbind(temp_real$Counts, temp_sim$Counts)); colnames(forccplot_temp) <- c('Real','Sim')
      forccplot <- rbind(forccplot, forccplot_temp)
      }
    }
    #RMSN_temp <- sum(DIFF$diff, na.rm = TRUE)/length(DIFF$diff)
    RMSN_temp <- sum(sqrt(DIFF$diff), na.rm=TRUE)/sum(real[,1], na.rm=TRUE)
    
    RMSN <- rbind(RMSN, RMSN_temp)
    GAPP <- rbind(GAPP, gap)
    FORCCPLOT <- rbind(FORCCPLOT, forccplot)
  }
  RMSN <- as.data.frame(RMSN); rownames(RMSN) <- seq(1:dim(RMSN)[1])
  RMSN <- cbind(Ref_Time, RMSN); colnames(RMSN) <- c("Time_ms", "RMSNval")
    
  CountError <- as.numeric(mean(RMSN$RMSNval))
  
  write.table(CountError, file=paste0(args[3], "/data/CountError.csv"), row.names=FALSE, col.names=FALSE) 
  
  # Plot...
  plot(RMSN$Time_ms, RMSN$RMSNval, xlim = c(min(RMSN$Time_ms), max(RMSN$Time_ms)), ylim=c(0, max(RMSN$RMSNval)+0.3),
       xlab=c('Time'), ylab=c('RMSN'))
  plot(ecdf(gap))
  mean(gap)
  dim(FORCCPLOT)  
  dim(GAPP)
  
  plot(FORCCPLOT$Real, FORCCPLOT$Sim, xlim = c(0, 150), ylim=c(0,150))
  FORCCPLOT_NONZERO <-subset(FORCCPLOT, subset=(FORCCPLOT$Real!=0))
  plot(FORCCPLOT_NONZERO$Real, FORCCPLOT_NONZERO$Sim, xlim = c(0, 150), ylim=c(0,150), xlab=c('Observed counts (veh/5min)'), ylab=c('Simulated counts (veh/5min)'))
  abline(lm(FORCCPLOT_NONZERO$Real~FORCCPLOT_NONZERO$Sim), col='red')
  summary(lm(FORCCPLOT_NONZERO$Real~FORCCPLOT_NONZERO$Sim))
  
  
  
  
  
  