# Merging Simulation and Loop Counts by same order
# Argument setting (Path) 

  args = c('SimMobility/avgVehicleCounts.csv', 'data/SensorMapping/RealData_sec.csv',  '/home/simon/Copy/SimMobility/CalibrationProgram/SimMobST_Calibration');   
  #args <- commandArgs(trailingOnly = TRUE)
  setwd(args[3])
  c(args[1],args[2], args[3])

# Import Real data after sensor mapping
  RealData <- read.csv(args[2], sep=' ')
  colnames(RealData) <- c("Time", "SensorID", "SegID", "LaneID", "SimCounts")
  #dim(RealData)  
  
# Importing Simulation data
  SimResult <- read.csv(args[1])
  colnames(SimResult) <- c("Time", "SensorID", "SegID", "LaneID", "SimCounts")
  head(SimResult)
  head(RealData)
  
# Ordering Simulation Data
      SimResult_ordered <- SimResult[order(SimResult$Time),]
            
      # Time convert of Real data: sec -> ms 
      rate <- unique(SimResult_ordered$Time)/unique(RealData$Time)
      
      for (i in 1:length(rate)){
        RealData[which(RealData$Time==unique(RealData$Time)[i]),]$Time <- (RealData[which(RealData$Time==unique(RealData$Time)[i]),]$Time)*rate[i]  
      }
      
      for (i in 1:length(rate)){
        RealData[which(RealData$Time==unique(RealData$Time)[i]),]$Time <- unique(SimResult_ordered$Time)[i]
      }
  
  # Using Code
  code <- paste(RealData$Time, RealData$LaneID)
  RealData <- cbind(RealData, code)
  code <- paste(SimResult_ordered$Time, SimResult_ordered$LaneID)
  SimResult_ordered <- cbind(SimResult_ordered, code)
  
  head(RealData); dim(RealData)
  head(SimResult_ordered); dim(SimResult_ordered)
  
  SimResult_ToMerge <- subset(SimResult_ordered, select=c(code, SimCounts))
  #RealData_ToMerge <- subset(RealData, select=c(code, Counts))
  #length(intersect(SimResult_ToMerge$code, RealData_ToMerge$code))
  head(SimResult_ToMerge); colnames(SimResult_ToMerge) <- c('code', 'SimCounts')
  
  # Merging with Simulated and Real counts 
  ForVectors <- merge(RealData, SimResult_ToMerge, all=FALSE)
  
  head(RealData)
  head(SimResult_ToMerge)
  head(ForVectors); dim(ForVectors)
  
  merge(SimResult_ToMerge, RealData)
  Vectors <- merge(RealData, SimResult_ToMerge, by = "code")
  head(Vectors)
  
  write.table(ForVectors$Counts, file=paste0(args[3], "/data/trueCounts.csv"), row.names=FALSE, col.names=FALSE)
  write.table(ForVectors$SimCounts, file=paste0(args[3], "/data/simCounts.csv"), row.names=FALSE, col.names=FALSE)
    
  
  
  