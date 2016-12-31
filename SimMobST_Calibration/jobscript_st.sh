#!/bin/bash -l

#### set num of cores (make it equal to 
#### num of threads in your xml input)
#$ -pe smp 40

#### batch job's name
#$ -N simmob_st

#### set the queue
#$ -q deadline

#### join stderr and stdout as a single file
#$ -j y

#### set the shell
#$ -S /bin/bash
#$ -V

#### set current dir as working dir
#$ -cwd

#### execute your command/application
/usr/local/MATLAB/R2015b/bin/matlab -nodisplay < wspsaNTE.m

##### How to submit job ############
##### qsub jobscript.sh ############
##### NOTE: make sure the folder where the jobscript found is writable by hpcusers group #######
##### To change mode: chmod g+rw .
