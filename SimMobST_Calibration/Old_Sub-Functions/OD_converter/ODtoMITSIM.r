################################################################
## OD MITSIM converter
## Author: Carlos, revised by Shi
## Date: Feb 2015
################################################################
################################################################
rm(list = ls())
library (gdata)
library (chron)
################################################################
# LOADING FILES

# Periods
start=4*3600;
end=8.5*3600;
od_intvl=900;
no_od=4103;
no_od_intvl=(end-start)/od_intvl;






if(FALSE)#Generate seed OD matrix according to sensor weight
{
sensor_analysis<-read.csv(file="/home/shiwang/Dropbox (MIT)/FINAL_NETWORK_convert/REAL_DATA/sensor_analysis.csv",sep=",",header=FALSE)
weight<-sensor_analysis[(start/od_intvl+1):(end/od_intvl),4];
dayOD<-read.csv(file="dayOD.csv",sep=",",header=FALSE)
temp<-array(0,dim=no_od*no_od_intvl)
for (i in 1:no_od_intvl){
temp[(1+(i-1)*no_od):(i*(no_od))]<-(weight[i]*dayOD*3600/od_intvl)[,1]}
write.table(temp,file="seedOD.csv",col.names=FALSE,row.names=FALSE)
OD <-  read.csv(file="seedOD.csv",header=FALSE,sep=",")
}








if (FALSE){#maybe need relace NA with blank in excel manually,  RECHECK
#Cauclate path id for each od
pathtable<-read.table(file="all_paths_for_mitsim.csv",sep=",")
path<-pathtable[,2:4]
Lpath=length(path[,2])

basefile <- read.table("baseFile(nopath).csv",sep=",",header=FALSE)
LOD<-length(basefile[,2]);
Ntemp=6 #col 6~10 is reserved for filling with path id

for (i in 1:LOD){
for (j in 1:Lpath){
    if (basefile[i,2]==path[j,2] & basefile[i,3]==path[j,3])
    {basefile[i,Ntemp]<-path[j,1];Ntemp=Ntemp+1;}
    }
    Ntemp=6;
}
    
write.table(basefile,file="baseFile.csv",row.names = FALSE,col.names=FALSE)
}##End of If False








OD <-  read.csv(file="resultOD.csv",header=FALSE,sep=",")
basefileTOT<-matrix(NA,0,12) ### 12 is Col #num in base file

#Combine by time interval    
for (k in 1:no_od_intvl){

    basefile <- read.table("baseFile.csv",sep=",",header=FALSE)
    basefile[,4]<-OD[((k-1)*no_od+1):(k*no_od),1]
    class(basefile[,1])<-"string"
    basefile[,1]<-"{"
    basefile[,5]<-"}"
    tstring<-start+(k-1)*od_intvl   
    basefileTOT<-rbind(basefileTOT,c(tstring,0,1.0,"{",rep(NA,7)),basefile,c("}",rep(NA,11)))
}

basefileTOT<-rbind(basefileTOT,c("<END>",rep(NA,1),rep(NA,1),rep(NA,1),rep(NA,1),rep(NA,1),rep(NA,1),rep(NA,1),rep(NA,1),rep(NA,1),rep(NA,1)))


write.table(basefileTOT,file="demand.dat",na="",quote=FALSE,sep="\t",row.names=FALSE,col.names=FALSE)
