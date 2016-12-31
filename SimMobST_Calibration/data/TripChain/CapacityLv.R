setwd('/media/simon/USB DISK')
list.files()
RealData <- read.csv('RealData_sec.csv', header=FALSE, sep=' ')
colnames(RealData) <- c('Ti','Sen','Seg','Lane', 'Count')
head(RealData)
UniLane<-unique(RealData$Lane)
i<-1
max.flow <- max(subset(RealData, subset=(RealData$Lane==UniLane[i]), select=Count)$Count)
for (i in 2:length(UniLane)){
  max.flow_temp <- max(subset(RealData, subset=(RealData$Lane==UniLane[i]), select=Count)$Count)
  max.flow <- rbind(max.flow, max.flow_temp)
}

mean(max.flow)*4
median(max.flow)*4
hist(max.flow*4, xlab=c('Maximum flow (veh/h/lane)'))
