### Screenline data matching
### This function builds VehicleCounts_Real.csv by modifying the raw sensor data structure (Intersection_01_08_10.txt) into the format of simulation output (VehicleCounts.csv) 
### Input: Intersection_01_08_10.txt 
### Output: VehicleCounts_Real.csv
### Requirements: turning_to_sensor_table_editec.xlsx
### Developed by SimMobility ShortTerm Team in Feb, 2016 

## 1. Environmental setting
  # Set working directory
  setwd('/home/simon/Copy/SimMobility/CalibrationProgram/SimMobST_Calibration/data/ScreenLine/')
  list.files()
  # Instal packages
    library("data.table") # For "data.table" and "fread" #install.packages("data.table")
    library("tidyr") # For "separate" #install.packages("tidyr")
    library("gdata") #install.pachages("gdata")
    library("splitstackshape") #install.packages("splitstackshape")

## 2. Data import
  # 2.1 Intersection Data
    Data_raw <- read.csv('intersection_01_08_10.csv', sep=',', header=FALSE)
    colnames(Data_raw) <- c("Mo", "Da", "Yr", "Ti", "SensorID", paste0("C", seq(1:(dim(Data_raw)[2]-5)))) # Month, Date, Year, Time, Counts...
    Data_raw <- as.data.table(Data_raw)

  # 2.2 Reference table
    Ref_raw <- read.xls("turning_to_sensor_table_edited.xlsx", sheet = 1, header = TRUE)
    Ref_raw <- as.data.table(Ref_raw)
    
    Ref_raw <- subset(Ref_raw, select=(c("Intersection", "fsection.Network.20150227.", "sensors")))
      colnames(Ref_raw) <- c("SensorID", "SegID", "Seq")

      #targetSensorIDs <- unique(Ref_raw$SensorID)
    commonSensorIDs <- intersect(Data_raw$SensorID, Ref_raw$SensorID)
    Data_CBD <- Data_raw[which(Data_raw$SensorID %in% commonSensorIDs),]
  
  # 2.3 Simulation Output
#     SimOut <- fread("VCounts.csv") #VehicleCounts.csv
#       colnames(SimOut) <- c("Time", "SensorID", "SegID", "LaneID", "Counts")

## 3. Re-structure
    # 3.1 Time
      time <- strsplit(as.character(Data_CBD$Ti), ":")
      TimeConverter <- function(time){
        time <- as.numeric(time)
        time[1]*3600+time[2]*60
      }  
      startingtime <- sapply(time, TimeConverter) 
      Data_CBD$Ti <- startingtime # Inserting changed time format 

    # 3.2 Matching (Data_CBD vs Ref_raw)
      # 3.2.1 Generation of LaneID in Ref_raw
      size_uni_seq <- length(unique(Ref_raw$SegID)) # 683
        
        # LaneIDgenerator  
        LaneIDgenerator <- function(i){ # i<-5
          temp <- Ref_raw[which(Ref_raw$SegID==unique(Ref_raw$SegID)[i]),] 
            temp <- subset(temp, subset=(as.character(levels(temp$Seq)[temp$Seq])!=""))
            temp2<-temp[1,]; temp2$Seq <- paste(c(levels(temp$Seq)[temp$Seq]), collapse =","); temp<-temp2
          if(is.na(temp$SensorID)==FALSE){
          # Making sequence
            j <- 1 # user factor (<size) Always j=1
            
          # Case 1: Single value
          if (nchar(as.character(temp$Seq[j]))<=2)
          {
            #a <- as.character(levels(temp$Seq[j]))[temp$Seq[j]]; a <- as.numeric(a)
            #a <- as.data.frame(temp$Seq); colnames(a)<-c('a')
            a <- as.numeric(temp$Seq); 
          } 
          
          # Case 2: Both "," and "-"  
          if (unlist(gregexpr(pattern=',',temp$Seq[j]))!=-1 && unlist(gregexpr(pattern='-',temp$Seq[j]))!=-1) 
          {
            #a <- as.data.frame((levels(temp$Seq[j]))[temp$Seq[j]]); colnames(a) <- c('a')
            a <- as.data.frame(temp$Seq); colnames(a)<-c('a')
              s <- as.character(a$a); p <-","; s2 <-gsub(p,"",s); 
              num0cc <-nchar(s)-nchar(s2);
            b <- separate(a, col=a, into=c(paste0("s", seq(1:(num0cc+1)))), sep=",") # firstly
              s <- as.character(b); p <-"-"; s2 <-gsub(p,"",s); 
              n0cc <- nchar(s)-nchar(s2);
              
                k<-1; a_temp <- b[which(n0cc==1)][k]; colnames(a_temp) <- c("s")
                  b_temp <- separate(a_temp, col=s, into=c("sub_from", "sub_to"), sep="-")
                  a_temp <- seq(as.numeric(b_temp$sub_from), as.numeric(b_temp$sub_to))
                  a_from <- a_temp
                if (sum(n0cc)>1){
                  for (k in 2:sum(n0cc)){ 
                  a_temp <- b[which(n0cc==1)][k]; colnames(a_temp) <- c("s")
                  b_temp <- separate(a_temp, col=s, into=c("sub_from", "sub_to"), sep="-")
                  a_temp <- seq(as.numeric(b_temp$sub_from), as.numeric(b_temp$sub_to))
                  a_from <- c(a_from, a_temp)}}
            
            a_temp <- b[which(n0cc==0)]
            a_from_temp <- as.numeric(b[which(n0cc==0)])
            a <- c(a_from, a_from_temp)
          }
          
          # Case 3: Only one "-"
          if (unlist(gregexpr(pattern='-',temp$Seq[j]))!=-1 && unlist(gregexpr(pattern=',',temp$Seq[j]))==-1) 
          {
            #a <- as.data.frame((levels(temp$Seq[j]))[temp$Seq[j]]); colnames(a) <- c('a')
            a <- as.data.frame(temp$Seq); colnames(a)<-c('a')
            b <- separate(a, col=a, into=c("from", "to"), sep="-")
            a <- seq(as.numeric(b$from), as.numeric(b$to))
          }
          
          # Case 4: Only one ","
          if (unlist(gregexpr(pattern=',',temp$Seq[j]))!=-1 && unlist(gregexpr(pattern='-',temp$Seq[j]))==-1) 
          {
            #a <- as.data.frame((levels(temp$Seq[j]))[temp$Seq[j]]); colnames(a) <- c('a')
            a <- as.data.frame(temp$Seq); colnames(a)<-c('a')
            b <- cSplit(a, 1, ",")
            a <- as.numeric(b)
          }
          
          # Duplications
          a <- unique(a)
          
          # LaneID generation
          c <- paste(rep(0, length(a)), seq(0, length(a)-1), sep="")
          LaneID <- paste0(temp$SegID[1], c)
          
          SensorID <- rep(temp$SensorID[1], length(a))
          SegID <- as.character(rep(temp$SegID[1], length(a)))
          Data_CBD_reformed <- as.data.frame(cbind(SensorID, SegID, LaneID))      
          return(Data_CBD_reformed)  
          }
        }

        # Using the LaneIDgenerator ... 
        i <- 1 # user factor (<size_uni_seq)
        Data_CBD_reformed <- LaneIDgenerator(i);
        for (i in 2:size_uni_seq){
          Data_CBD_reformed_temp <- LaneIDgenerator(i)
          Data_CBD_reformed <- rbind(Data_CBD_reformed, Data_CBD_reformed_temp)
        }
        
        # Ordering with Seq. in a identical sensor ID
        SensorList <- unique(Data_CBD_reformed$SensorID)

        i<-1; # i<length(SensorList)
        unorderedData <- Data_CBD_reformed[which(Data_CBD_reformed$SensorID==SensorList[i]),]
        refTable <- Ref_raw[which(Ref_raw$SensorID==SensorList[i]),]
          refTable <- subset(refTable, subset=(as.character(levels(refTable$Seq)[refTable$Seq])!=""))
        SegList <- unique(as.character(unorderedData$Seg))
          nseg <- length(SegList)
        # Ordering Ft  
        OrderingGen <- function(l){ # l<-2
          temp <- Ref_raw[which(Ref_raw$SegID==SegList[l]),] 
          temp <- subset(temp, subset=(as.character(levels(temp$Seq)[temp$Seq])!=""))
          temp2<-temp[1,]; temp2$Seq <- paste(c(levels(temp$Seq)[temp$Seq]), collapse =","); temp<-temp2
          if(is.na(temp$SensorID)==FALSE){
            # Making sequence
            j <- 1 # user factor (<size) Always j=1
            
            # Case 1: Single value
            if (nchar(as.character(temp$Seq[j]))<=2)
            {
              #a <- as.character(levels(temp$Seq[j]))[temp$Seq[j]]; a <- as.numeric(a)
              a <- as.numeric(temp$Seq); 
            } 
            
            # Case 2: Both "," and "-"  
            if (unlist(gregexpr(pattern=',',temp$Seq[j]))!=-1 && unlist(gregexpr(pattern='-',temp$Seq[j]))!=-1) 
            {
              #a <- as.data.frame((levels(temp$Seq[j]))[temp$Seq[j]]); colnames(a) <- c('a')
              a <- as.data.frame(temp$Seq); colnames(a)<-c('a')
              s <- as.character(a$a); p <-","; s2 <-gsub(p,"",s); 
              num0cc <-nchar(s)-nchar(s2);
              b <- separate(a, col=a, into=c(paste0("s", seq(1:(num0cc+1)))), sep=",") # firstly
              s <- as.character(b); p <-"-"; s2 <-gsub(p,"",s); 
              n0cc <- nchar(s)-nchar(s2);
              
              k<-1; a_temp <- b[which(n0cc==1)][k]; colnames(a_temp) <- c("s")
              b_temp <- separate(a_temp, col=s, into=c("sub_from", "sub_to"), sep="-")
              a_temp <- seq(as.numeric(b_temp$sub_from), as.numeric(b_temp$sub_to))
              a_from <- a_temp
              if (sum(n0cc)>1){
                for (k in 2:sum(n0cc)){ 
                  a_temp <- b[which(n0cc==1)][k]; colnames(a_temp) <- c("s")
                  b_temp <- separate(a_temp, col=s, into=c("sub_from", "sub_to"), sep="-")
                  a_temp <- seq(as.numeric(b_temp$sub_from), as.numeric(b_temp$sub_to))
                  a_from <- c(a_from, a_temp)}}
              
              a_temp <- b[which(n0cc==0)]
              a_from_temp <- as.numeric(b[which(n0cc==0)])
              a <- c(a_from, a_from_temp)
            }
            
            # Case 3: Only one "-"
            if (unlist(gregexpr(pattern='-',temp$Seq[j]))!=-1 && unlist(gregexpr(pattern=',',temp$Seq[j]))==-1) 
            {
              #a <- as.data.frame((levels(temp$Seq[j]))[temp$Seq[j]]); colnames(a) <- c('a')
              a <- as.data.frame(temp$Seq); colnames(a)<-c('a')
              b <- separate(a, col=a, into=c("from", "to"), sep="-")
              a <- seq(as.numeric(b$from), as.numeric(b$to))
            }
            
            # Case 4: Only one ","
            if (unlist(gregexpr(pattern=',',temp$Seq[j]))!=-1 && unlist(gregexpr(pattern='-',temp$Seq[j]))==-1) 
            {
              #a <- as.data.frame((levels(temp$Seq[j]))[temp$Seq[j]]); colnames(a) <- c('a')
              a <- as.data.frame(temp$Seq); colnames(a)<-c('a')
              b <- cSplit(a, 1, ",")
              a <- as.numeric(b)
            }
            
            # Duplications
            a <- unique(a)
                            
            return(a)  
          }
        }
        # Using Ordering Ft
        l<-1 # j<nseg
        A <- OrderingGen(l)
        if (nseg>1){
          for (l in 2:nseg){
            A_temp <-OrderingGen(l)
            A <- c(A, A_temp)
          }}
        A<-as.data.frame(A); colnames(A) <- c("SeqInData")
        orderedData <- cbind(unorderedData, A)
        for (i in 2:length(SensorList)){ #i<-34 
         unorderedData <- Data_CBD_reformed[which(Data_CBD_reformed$SensorID==SensorList[i]),]
         refTable <- Ref_raw[which(Ref_raw$SensorID==SensorList[i]),]
         refTable <- subset(refTable, subset=(as.character(levels(refTable$Seq)[refTable$Seq])!=""))
         SegList <- unique(as.character(unorderedData$Seg))
         nseg <- length(SegList)
          # Ordering Ft 
          # Using Ordering Ft
          l<-1 # j<nseg
          A <- OrderingGen(l);
          if (nseg>1){
            for (l in 2:nseg){ #l<-2
              A_temp <-OrderingGen(l)
              A <- c(A, A_temp)
            }}
          A<-as.data.frame(A); colnames(A) <- c("SeqInData")
         orderedData_temp <- cbind(unorderedData, A)
         orderedData <- rbind(orderedData, orderedData_temp)
        }

  # Time generation
    Time_eigen <- unique(Data_CBD$Ti)
    Time <- as.data.table(rep(unique(Data_CBD$Ti), each=dim(orderedData)[1])); 
    orderedData_time <- cbind(Time, 
          rep(as.character(orderedData$SensorID), length(Time_eigen)), rep(as.character(orderedData$SegID), length(Time_eigen)), 
          rep(as.character(orderedData$LaneID), length(Time_eigen)), rep(as.character(orderedData$SeqInData), length(Time_eigen)))
    orderedData_time <- as.data.table(orderedData_time); colnames(orderedData_time) <- c("Time", colnames(orderedData))
        
    # 3.2.2 Matching with Data_CBD 
# Taking 6-10AM from Data_CBD & orderedData_time
  st <- TimeConverter(c(17,30)) # 7AM
  et <- TimeConverter(c(19,30)) # 7:30AM
  Data_CBD_target <- subset(Data_CBD, subset=(Data_CBD$Ti>=st & Data_CBD$Ti<=et))
  orderedData_target <- subset(orderedData_time, subset=(orderedData_time$Time>=st & orderedData_time$Time<=et))
  Time_eigen_terget <- Time_eigen[which(Time_eigen>=st & Time_eigen<=et)]

# Generation of Real Data
  i <- 1; orderedData_time_temp <- orderedData_target[which(orderedData_target$SensorID==SensorList[i]),]
    Data_CBD_temp <- Data_CBD_target[which(Data_CBD_target$SensorID==SensorList[i]),] 
  t <- 1;  orderedData_time_temp_2 <- subset(orderedData_time_temp, subset=(orderedData_time_temp$Time==Time_eigen_terget[t]))
    Data_CBD_temp_2 <- subset(Data_CBD_temp, subset=(Data_CBD_temp$Ti==Time_eigen_terget[t]))
  #Counts
  f<-1; Counts <- as.data.frame(Data_CBD_temp_2)[,(as.numeric(orderedData_time_temp_2$SeqInData[f])+5)]
  for (f in 2:dim(orderedData_time_temp_2)[1]){ # f <- 3
    Counts_temp <- as.data.frame(Data_CBD_temp_2)[,(as.numeric(orderedData_time_temp_2$SeqInData[f])+5)]
    Counts <- rbind(Counts, Counts_temp)
  }
  RealData <- cbind(orderedData_time_temp_2, Counts); colnames(RealData) <- c(colnames(orderedData_target), "Counts")
  for (t in 2:length(Time_eigen_terget)-1){ # #t <- 100;  
    orderedData_time_temp_2 <- subset(orderedData_time_temp, subset=(orderedData_time_temp$Time==Time_eigen_terget[t]))
    Data_CBD_temp_2 <- subset(Data_CBD_temp, subset=(Data_CBD_temp$Ti==Time_eigen_terget[t]))
    #Counts
    f<-1; Counts <- as.data.frame(Data_CBD_temp_2)[,(as.numeric(orderedData_time_temp_2$SeqInData[f])+5)]
    for (f in 2:dim(orderedData_time_temp_2)[1]){ # f <- 3
      Counts_temp <- as.data.frame(Data_CBD_temp_2)[,(as.numeric(orderedData_time_temp_2$SeqInData[f])+5)]
      Counts <- rbind(Counts, Counts_temp)
    }
    RealData_temp <- cbind(orderedData_time_temp_2, Counts); colnames(RealData_temp) <- c(colnames(orderedData_target), "Counts")    
    RealData <- rbind(RealData, RealData_temp)
  }

  for (i in 2:length(SensorList)){ # i<-212
    orderedData_time_temp <- orderedData_target[which(orderedData_target$SensorID==SensorList[i]),]
    Data_CBD_temp <- Data_CBD_target[which(Data_CBD_target$SensorID==SensorList[i]),] 
    if (dim(Data_CBD_temp)[1]!=0){
    t <- 1;  orderedData_time_temp_2 <- subset(orderedData_time_temp, subset=(orderedData_time_temp$Time==Time_eigen_terget[t]))
    Data_CBD_temp_2 <- subset(Data_CBD_temp, subset=(Data_CBD_temp$Ti==Time_eigen_terget[t]))
    #Counts
    f<-1; Counts <- as.data.frame(Data_CBD_temp_2)[,(as.numeric(orderedData_time_temp_2$SeqInData[f])+5)]
    if (dim(orderedData_time_temp_2)[1]!=1){
      for (f in 2:dim(orderedData_time_temp_2)[1]){ # f <- 5
        if (orderedData_time_temp_2$SeqInData[f]<=22){
          Counts_temp <- as.data.frame(Data_CBD_temp_2)[,(as.numeric(orderedData_time_temp_2$SeqInData[f])+5)]
        }else {Counts_temp <- NA}
        Counts <- rbind(Counts, Counts_temp)
        }
      Temp_RealData <- cbind(orderedData_time_temp_2, Counts); colnames(Temp_RealData) <- c(colnames(orderedData_target), "Counts")
        
    for (t in 2:length(Time_eigen_terget)-1){ # t <- 2;  
      orderedData_time_temp_2 <- subset(orderedData_time_temp, subset=(orderedData_time_temp$Time==Time_eigen_terget[t]))
      Data_CBD_temp_2 <- subset(Data_CBD_temp, subset=(Data_CBD_temp$Ti==Time_eigen_terget[t]))
      if (dim(Data_CBD_temp_2)[1]!=0){
        #Counts
        f<-1; Counts <- as.data.frame(Data_CBD_temp_2)[,(as.numeric(orderedData_time_temp_2$SeqInData[f])+5)]
        if (dim(orderedData_time_temp_2)[1]!=1){
          for (f in 2:dim(orderedData_time_temp_2)[1]){ # f <- 3
            if (orderedData_time_temp_2$SeqInData[f]<=22){
              Counts_temp <- as.data.frame(Data_CBD_temp_2)[,(as.numeric(orderedData_time_temp_2$SeqInData[f])+5)]
            }else {Counts_temp <- NA}
            Counts <- rbind(Counts, Counts_temp)
          }}
        RealData_temp <- cbind(orderedData_time_temp_2, Counts); colnames(RealData_temp) <- c(colnames(orderedData_target), "Counts")     
        Temp_RealData <- rbind(Temp_RealData, RealData_temp)
      }
    }    
    RealData <- rbind(RealData, Temp_RealData)
    } } }

  # Time Change to Simulation format
    RealData_Save <- subset(RealData, select=c(-SeqInData)); 
  
  # RealData_Save$Counts[which(RealData_Save$Counts>2040)] <- 0
  # RealData_Save$Counts[which(is.na(RealData_Save$Counts))] <- 0
  # Remove NA values and 0
    TooMuch <- which(RealData_Save$Counts>2040); 
    NAvalues <- which(is.na(RealData_Save$Counts)); 
    NoGood <- c(TooMuch, NAvalues); 
  
    dim(RealData_Save) # 12150 5
    RealData_Save <- RealData_Save[-NoGood,] # dim(RealData_Save) 5294 5
  
  # Screenline  
  head(RealData_Save)  
  screenline <- read.table("screenline_mapping_segments_Extended_CBD", sep=";", header=TRUE)
  head(screenline)
    colnames(screenline)[1] <- c("SegID")
    screenline$SegID <- as.character(screenline$SegID)
  converted_data <- merge(RealData_Save, screenline, by=c("SegID"))

  head(converted_data)
  uniqueT <- unique(converted_data$Time)
  uniqueSeg <- unique(converted_data$SegID)
    length(uniqueSeg); length(uniqueT); 
  
  token <- c(seq(1, length(uniqueT), by=3))
  
  
  i<-1 # < length(token) # For 15min
  agg <- c(token[i], token[i]+1, token[i]+2) 
  uniqueT[agg]
  
  j<-1 # For specific segment
  head(converted_data)
  temp_1 <- subset(converted_data, subset=(converted_data$SegID==uniqueSeg[j]))
  temp_2 <- subset(temp_1, subset=(temp_1$Time>=uniqueT[agg[1]] & temp_1$Time<=uniqueT[agg[3]]))
  temp_3 <- temp_2[1,]; temp_3 <- subset(temp_3, select=c("SegID", "Time", "Counts", "screenLineSegmet"))
  temp_3$Counts <- sum(temp_2$Counts)  
  NewData <- temp_3
  for (j in 2:length(uniqueSeg)){
    temp_1 <- subset(converted_data, subset=(converted_data$SegID==uniqueSeg[j]))
    temp_2 <- subset(temp_1, subset=(temp_1$Time>=uniqueT[agg[1]] & temp_1$Time<=uniqueT[agg[3]]))
    temp_3 <- temp_2[1,]; temp_3 <- subset(temp_3, select=c("SegID", "Time", "Counts", "screenLineSegmet"))
    temp_3$Counts <- sum(temp_2$Counts)  
    NewData <- rbind(NewData, temp_3)
  }
  
  # For Loops for time
  for (i in 2:length(token)){
    #i<-1 # < length(token) # For 15min
    agg <- c(token[i], token[i]+1, token[i]+2) 
    uniqueT[agg]
    
    j<-1 # For specific segment
    head(converted_data)
    temp_1 <- subset(converted_data, subset=(converted_data$SegID==uniqueSeg[j]))
    temp_2 <- subset(temp_1, subset=(temp_1$Time>=uniqueT[agg[1]] & temp_1$Time<=uniqueT[agg[3]]))
    temp_3 <- temp_2[1,]; temp_3 <- subset(temp_3, select=c("SegID", "Time", "Counts", "screenLineSegmet"))
    temp_3$Counts <- sum(temp_2$Counts)  
    NewData_temp <- temp_3 
    for (j in 2:length(uniqueSeg)){ #j<-14 i
      temp_1 <- subset(converted_data, subset=(converted_data$SegID==uniqueSeg[j]))
      temp_2 <- subset(temp_1, subset=(temp_1$Time>=uniqueT[agg[1]] & temp_1$Time<=uniqueT[agg[3]]))
      temp_3 <- temp_2[1,]; temp_3 <- subset(temp_3, select=c("SegID", "Time", "Counts", "screenLineSegmet"))
      temp_3$Counts <- sum(temp_2$Counts)  
      NewData_temp <- rbind(NewData, temp_3)
    }
    NewData <- rbind(NewData, NewData_temp)
  }
    
## 4. Write Actual 
    write.table(NewData, file='NewCountData1730to1930.csv', row.names=FALSE, col.names=TRUE)
    

  