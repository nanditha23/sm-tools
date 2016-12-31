%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% W-SPSA program - CHANGEPARAMETERS function implements simulation

% the Matlab code for WSPSA calibration algorithm 
% Lu Lu, Sep 2012 - Edit by CLA Jul, 2013; 
% Edit by Shi Wang for NTE network, April, 2015

% Edit to sync with SimMobility ShortTerm, Feb, 2016

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [simcount, truecount, simcount_forRM, truecount_forRM, trueTravelTime_forRM, simTravelTime_forRM]=CHANGEPARAMETERS(dbparams, routechoiceparams, iterations, is_initial)
  
    % Declaration
        global counter_glob; global ITERATION_SWITCH;
        global start_time; global end_time; global od_interval; global sensor_interval;
        global free_flow_interval;

    % update driver params
        updateParams = '';    
        for i = 1:size(dbparams)
            updateParams = strcat(updateParams, num2str(dbparams(i)));
            updateParams = strcat(updateParams, ',');
        end

        command = 'python updateDriverParamXML.py';
        command = sprintf('%s %s %s %s', './runApplication.sh', command, 'SimMobility/data/driver_behavior_model/driver_param.xml', updateParams);
        system(command);

     % update driver params
        updatercparams = '';    
        for i = 1:size(routechoiceparams)
            updatercparams = strcat(updatercparams, num2str(routechoiceparams(i)));
            updatercparams = strcat(updatercparams, ',');
        end

        command = 'python updateRouteChoiceParamsXML.py';
        command = sprintf('%s %s %s %s', './runApplication.sh', command, 'SimMobility/data/pathset_config.xml', updatercparams);
        system(command);

    % Truncating OD dash
        system('Rscript data/TripChain/PostF_inLoop.R')

    % TC from g-function 
        command = 'python ODMatrixToTripChain.py';
        command = sprintf('%s %s %s %s', command, num2str(start_time), num2str(end_time), num2str(od_interval));
        system(command);   

    % Run SimMobility
        cd('SimMobility/')
        for n_iterations=1:iterations,      
            fprintf('\n# Replication %d\n\n',n_iterations);
            % CHANGE TO run_xmitsim_bck IF LOCAL RUN             
            run_properly = false;
            while(~run_properly)
                system('./../runApplication.sh ./Release/SimMobility_Short data/simulation.xml data/simrun_ShortTerm.xml > simulation.txt');
                pause(5)
                check_count = load('VehicleCounts.csv');
                if length(check_count) > 0
                    run_properly = true;                
                end
            end
            copyfile('VehicleCounts.csv' , strcat('VehicleCounts_',num2str(n_iterations) ,'.csv'));
            pause(5)            
        end
        cd('..')
        
        command = 'python consolidateLoopData.py';
        command = sprintf('%s %s %d', './runApplication.sh', command, iterations);
        system(command);
    
    % Saving output: Simulated counts, travel-time 
        copyfile('SimMobility/avgVehicleCounts.csv', strcat('RESULT/avgVehicleCounts_', num2str(counter_glob), '.csv'));
        copyfile('SimMobility/od_travel_time.csv', strcat('RESULT/od_travel_time_', num2str(counter_glob), '.csv'));

    % MATRIX_UPDATE: Only for the last run each iteration
         if (counter_glob < ITERATION_SWITCH )    
            % W generation   
            command = 'python data/WMATRIX/generate_wmatrix.py';
            command = sprintf('%s %s %s %s %s', command, num2str(start_time), num2str(end_time), num2str(od_interval), num2str(sensor_interval));
            system(command);
            system('mv SimMobility/assignment_matrix.csv RESULT/lastAssignmentMatrix.csv');
         end   
   
    % Generation of Vectors: simCounts & trueCounts
        command = sprintf('%s %s %s %s %d %d', './runApplication.sh', 'python generate_counts_vector.py', num2str(start_time), num2str(end_time), sensor_interval, free_flow_interval);
        system(command);
        simcount = load('data/simcount.csv'); truecount = load('data/truecount.csv'); simcount_forRM = load('data/simCountsRM.csv'); truecount_forRM = load('data/trueCountsRM.csv');      
                
        arg1=num2str(start_time); arg2=num2str(end_time);
        command = sprintf('%s %s %s', 'Rscript data/generate_traveltime_vector.R', arg1, arg2);
        system(command)
        trueTravelTime_forRM = load('data/TravelTimeData/trueTravelTime_RM.csv'); simTravelTime_forRM = load('data/TravelTimeData/simTravelTime_RM.csv');
end


