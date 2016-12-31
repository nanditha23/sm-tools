### F-function 
### This function converts Trip Table (from SimMobility ST) to OD matrix 
### Input: i) start_hr~end_hr, ii) Interval of ODdata 
### Output: i) ODdata, Zonedata, for parameter matrix and ii) ODpair, Zonepair for ref. 
### Requirements: i) TripChain table and ii) NodeToZone table
### Developed by SimMobility ShortTerm Team in Feb, 2016 

F_start <- proc.time()
#Ffunction <- function(interval_od_min, start_hr, end_hr) {
  start_hr <- 6; end_hr <- 8 # Previously, start = 10; end = 11; 
  interval_od_min <- 15; #interval_sensor <- 5; no_sensor <- 650;
  
## 1. Environmental setting
  # Set working directory
  setwd('/home/data/SimMobST_Calibration/data/TripChain')
  list.files()
  # Instal packages
    #install.packages("data.table")
    library("data.table") # For "data.table" and "fread"
    #install.packages("tidyr")
    library("tidyr") # For "separate"
  # Input: as input parameter 
    start <- start_hr*60*60 # 10AM (unit: sec)
    end <- end_hr*60*60 # 11AM (unit: sec)
    interval_od <- interval_od_min*60 # time interval: 15min -> 900sec
    
## 2. Data import
  # 2.1 TripChain data
    TripChain_raw <- as.data.table(fread('sample_tripchain.csv', sep = ';'))
    temp <- subset(TripChain_raw, select=c(trip_id, person_id, trip_start_time, 
                                            subtrip_origin_id, subtrip_destination_id,
                                            sequence_num, travel_mode))  
    # Only car and taxi to be considered
    TripChain_anal <- subset(temp , travel_mode=='Car' | travel_mode=='Taxi')  
  
  # 2.2 TAZ data
    TAZ_raw <- as.data.table(fread('node_to_zone.csv'))
  
## 3. Data assimilation of TripChain & TAZ ==> Table 1 & 2
  # 3.1 Table 1 (Refefence table): OD pair 
    ODpair_temp <- subset(TripChain_anal, select=c(subtrip_origin_id, subtrip_destination_id))
    ODpair <- unique(ODpair_temp)
        
  # Generation of OD pair table *NEED TO BE IMPROVED, TAKES TOO MUCH TIME (29/Jan, 2016) *IMPROVED THROU through Vectorization (1/Feb, 2016)
        NtoZ <- function(node1, node2){
          zone <- c(TAZ_raw$zone_id[which(TAZ_raw$id==node1)], TAZ_raw$zone_id[which(TAZ_raw$id==node2)])
          return(zone)
        }
    zone <- t(mapply(NtoZ, ODpair$subtrip_origin_id, ODpair$subtrip_destination_id))
    zone <- as.data.table(zone); colnames(zone) <- c('zone_o', 'zone_d')
    index <- c(1:dim(ODpair)[1])    
    ODpair <- cbind(index, ODpair, zone)
  
  # 3.2 Table 2 (Data table): OD data
    # Starting Time 
    # Converting time unit into 'sec'
    time <- strsplit(TripChain_anal$trip_start_time, ":")
        TimeConverter <- function(time){
          time <- as.numeric(time)
          time[1]*3600+time[2]*60+time[3]
        }  
    startingtime <- sapply(time, TimeConverter) 
    TripChain_anal$trip_start_time <- startingtime # Inserting changed time format 
    
    # Time interval 
    no_interval_od = (end-start)/interval_od; # Classify simulation time into each time interval
      t_od <- array(0, dim=no_interval_od);
      t_od[1] = start;
      for (i in 2:no_interval_od){
        t_od[i] = t_od[i-1] + interval_od;
      }
    
    # Vehicle count through individual allocation for each time interval and OD pairs      
      uni_tinterval <- t_od
      #1 Based on time interval
        # OD index to TripChain
        ODpair_temp <- ODpair
        code <- paste(TripChain_anal$subtrip_origin_id,TripChain_anal$subtrip_destination_id, sep=" ")
        TripChain_anal <- cbind(TripChain_anal, code)
        code <- paste(ODpair$subtrip_origin_id,ODpair$subtrip_destination_id, sep=" ")
        ODpair_temp <- cbind(ODpair_temp, code)
  
        #index
        index_match <- match(TripChain_anal$code, ODpair_temp$code)
        TripChain_anal <- cbind(TripChain_anal, index_match)
               
       # Split TripChain into each time interval  
        for (i in 1:length(uni_tinterval)){ 
            if (i==length(uni_tinterval)){
              ad <- which(TripChain_anal$trip_start_time>uni_tinterval[i] & TripChain_anal$trip_start_time<=(uni_tinterval[i]+900))
              ti <- as.data.table(rep(uni_tinterval[i], time=length(ad))); colnames(ti) <- c('ti')
              sl <- cbind(TripChain_anal[ad], ti)   
              assign(paste("sl", i, sep = "."), sl)
            } else {
              ad <- which(TripChain_anal$trip_start_time>=uni_tinterval[i] & TripChain_anal$trip_start_time<uni_tinterval[i+1])
              ti <- as.data.table(rep(uni_tinterval[i], time=length(ad))); colnames(ti) <- c('ti')
              sl <- cbind(TripChain_anal[ad], ti)
              assign(paste("sl", i, sep = "."), sl)
            }
        }    
  
      #2 Based on OD pair
      myList <- ls(pattern = "sl.")
      for (i in 1:length(myList)){ 
        myTemp <- get(myList[i])
        myTable <- as.data.frame(table(myTemp$index))
          colnames(myTable) <-c('index_a', 'count')
        ODpair <- as.data.frame(ODpair); colnames(ODpair) <- c('index_a', colnames(ODpair)[2:5])
          # should we? ODpair$index_a <- as.numeric(ODpair$index_a) myTable$index_a <- as.numeric(myTable$index_a) 
        if (i==1){
          ODdata <- merge(ODpair, myTable, by='index_a', all=TRUE)
        } else {
          temp <- merge(ODpair, myTable, by='index_a', all=TRUE)
          ODdata <- rbind(ODdata, temp)
        } 
      }  
      
      #3 NA count to be 0
      ODdata[which(is.na(ODdata$count)),]$count <- 0
  
      #4 Add Time Interval
      time_interval <- as.data.table(rep(uni_tinterval, each=dim(ODpair)[1])); colnames(time_interval) <- c('time_interval')
      ODdata <- cbind(ODdata, time_interval) 
      # -> Dimension of ODdata is (44,077*4=176,308). So, Zone data 
  
  # 3.3 Table 3 (Data table): Zone data
        zonecode <- as.data.table(paste(ODdata$zone_o, ODdata$zone_d, sep=" ")); colnames(zonecode) <- c("zonecode")      
        ODdata_forzone <- ODdata; 
      ODdata_forzone <- cbind(ODdata_forzone, zonecode)
  
      Zonepair <- as.data.table(unique(ODdata_forzone$zonecode)); colnames(Zonepair) <- c("zonecode")
        temp <- separate(Zonepair, col=zonecode, into=c("zone_o", "zone_d"), sep=" ")
        index_forzone <- c(1:dim(Zonepair)[1])
      Zonepair <- cbind(Zonepair, temp, index_forzone)  
    
      for (i in 1:length(uni_tinterval)){ 
        temp1 <- subset(ODdata_forzone, subset=(time_interval==uni_tinterval[i]))
        myTable_forzone <- as.data.frame(table(temp1$zonecode)); colnames(myTable_forzone) <- c("zonecode", "count")
        if (i==1){
          Zonedata <- merge(Zonepair, myTable_forzone, by='zonecode', all=TRUE)
            Zonedata <- Zonedata[order(Zonedata$index_forzone),] # Ordering
            Zonedata <- cbind(Zonedata, rep(uni_tinterval[i], dim(Zonedata)[1]))
        } else {
          temp2 <- merge(Zonepair, myTable_forzone, by='zonecode', all=TRUE)
            temp2 <- temp2[order(temp2$index_forzone),] # Ordering
            temp2 <- cbind(temp2, rep(uni_tinterval[i], dim(temp2)[1]))
          Zonedata <- rbind(Zonedata, temp2)
        }       
      }
      colnames(Zonedata) <- c(colnames(Zonedata)[1:(dim(Zonedata)[2]-1)], "time_interval")
      # -> Dimension of ODdata is (37,351*4=149,404). 15% reduced from size of OD data. 
  
  # 3.4 Table 4 (Calibration table): Theta
    # OD theta
      theta_od = subset(ODdata, select=c('count'))
  
    # Zone theta
      theta_zone = subset(Zonedata, select=c('count'))
            
  # 4. Saving
      write.table(ODdata, file='ODdata.csv', row.names=FALSE, col.names=FALSE)
      write.table(Zonedata, file='Zonedata.csv', row.names=FALSE, col.names=FALSE)
      write.table(ODpair, file='ODpair.csv', row.names=FALSE, col.names=FALSE)
      write.table(Zonepair, file='Zonepair.csv', row.names=FALSE, col.names=FALSE)
      write.table(theta_od, file='theta_OD.csv', row.names=FALSE, col.names=FALSE)
      write.table(theta_zone, file='theta_zone.csv', row.names=FALSE, col.names=FALSE)
F_end <- proc.time()
F_computationtime <- (F_end-F_start)[3] #unit: sec
    write.csv(F_computationtime, file='F_computationtime.csv')
    
  # Confg. Output
      # N_OD=no_ODs*no_od_intervals;
      N_OD <- dim(theta_zone)[1]
      no_od_intervals <- no_interval_od
      no_ODs <- N_OD/no_od_intervals
      OD_confg <- as.data.frame(c(N_OD, no_od_intervals, no_ODs))
      write.table(OD_confg, file='OD_config.csv', row.names=FALSE, col.names=FALSE)
#}

  
