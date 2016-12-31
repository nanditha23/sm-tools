%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% W-SPSA program - CHANGEPARAMETERS function implements simulation

% the Matlab code for WSPSA calibration algorithm 
% Lu Lu, Sep 2012 - Edit by CLA Jul, 2013; 
% Edit by Shi Wang for NTE network, April, 2015

% Edit to sync with SimMobility ShortTerm, Feb, 2016

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [PMstructure] = CHANGEPARAMETERS_pf(dbparams, routechoiceparams, iterations, pf, WhichType)
    %% Plus
        if (pf==1) % Plus
            % update driver params
                updateParams = '';    
                for i = 1:size(dbparams)
                    updateParams = strcat(updateParams, num2str(dbparams(i)));
                    updateParams = strcat(updateParams, ',');
                end

                command = 'python updateDriverParamXML_Whole_set.py';
                command = sprintf('%s %s %s %s', './runApplication.sh', command, 'SimMobility_Plus/data/driver_behavior_model/driver_param.xml', updateParams);
                system(command);
                
             % update driver params
                updatercparams = '';    
                for i = 1:size(routechoiceparams)
                    updatercparams = strcat(updatercparams, num2str(routechoiceparams(i)));
                    updatercparams = strcat(updatercparams, ',');
                end

                command = 'python updateRouteChoiceParamsXML.py';
                command = sprintf('%s %s %s %s', './runApplication.sh', command, 'SimMobility_Plus/data/pathset_config.xml', updatercparams);
                system(command);

            % Truncating OD dash
                system('Rscript data/TripChain/PostF_inLoop_Plus.R')
            % TC from g-function
                system('python ODMatrixToTripChain_Plus.py');

            % Run SimMobility
                cd('SimMobility_Plus/')
                for n_iterations=1:iterations,      
                    fprintf('\n# Replication %d\n\n',n_iterations);
                    % CHANGE TO run_xmitsim_bck IF LOCAL RUN             
                    run_properly = false;
                    while(~run_properly)
                        %system('./../runApplication.sh ./Release/SimMobility_Short_out data/simulation_out.xml data/simrun_ShortTerm_out.xml > simulation.txt');
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

                pause(5)

                command = 'python consolidateLoopData_Plus.py';
                command = sprintf('%s %s %d', './runApplication.sh', command, iterations);
                system(command);

            % MATRIX_UPDATE: Only for the last run each iteration
                % W generation   
                system('python data/WMATRIX/generate_wmatrix_Plus.py');
                if (strcmp(WhichType,'perturbation'))
                    system('python data/WMATRIX/generate_wmatrix_plusside.py');
                end
                system('mv SimMobility_Plus/assignment_matrix.csv RESULT/lastAssignmentMatrix_Plus.csv');
                
            % Generation of Vectors: simCounts & trueCounts
                %command = sprintf('%s %s %s %s %d %d', './runApplication.sh', 'python generate_counts_vector_Plus.py', num2str(start_time), num2str(end_time), sensor_interval, free_flow_interval);
                %system(command);           
                system('Rscript generate_counts_vector_LaneLv_Plus.R')
                simcount = load('data/simcount_Plus.csv'); truecount = load('data/truecount_Plus.csv'); simcount_forRM = load('data/simCountsRM_Plus.csv'); truecount_forRM = load('data/trueCountsRM_Plus.csv');      
                truecount_var = load('data/trueCountsVar_Plus.csv'); truecount_obs = load('data/trueCountsObs_Plus.csv');
    
            % Generation of Vectors: simTravelTime & trueTravelTime 
                system('Rscript data/generate_traveltime_vector_Generous_Plus.R')
                trueTravelTime_forRM = load('data/TravelTimeData/trueTravelTime_RM_Plus.csv'); simTravelTime_forRM = load('data/TravelTimeData/simTravelTime_RM_Plus.csv');
                trueTravelTime_var = load('data/TravelTimeData/trueTravelTime_Var_Plus.csv'); trueTravelTime_obs = load('data/TravelTimeData/trueTravelTime_Obs_Plus.csv');
                trueTravelTime = load('data/TravelTimeData/trueTravelTime_Plus.csv'); simTravelTime = load('data/TravelTimeData/simTravelTime_Plus.csv');

        end % Plus
    %% Minus
       if (pf==2) % Minus
        % update driver params
            updateParams = '';    
            for i = 1:size(dbparams)
                updateParams = strcat(updateParams, num2str(dbparams(i)));
                updateParams = strcat(updateParams, ',');
            end

            command = 'python updateDriverParamXML_Whole_set.py';
            command = sprintf('%s %s %s %s', './runApplication.sh', command, 'SimMobility_Minus/data/driver_behavior_model/driver_param.xml', updateParams);
            system(command);
            
         % update driver params
            updatercparams = '';    
            for i = 1:size(routechoiceparams)
                updatercparams = strcat(updatercparams, num2str(routechoiceparams(i)));
                updatercparams = strcat(updatercparams, ',');
            end

            command = 'python updateRouteChoiceParamsXML.py';
            command = sprintf('%s %s %s %s', './runApplication.sh', command, 'SimMobility_Minus/data/pathset_config.xml', updatercparams);
            system(command);

        % Truncating OD dash
            system('Rscript data/TripChain/PostF_inLoop_Minus.R')
            % TC from g-function
            system('python ODMatrixToTripChain_Minus.py');
            
        % Run SimMobility
            cd('SimMobility_Minus/')
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
           
            pause(5);
 
            command = 'python consolidateLoopData_Minus.py';
            command = sprintf('%s %s %d', './runApplication.sh', command, iterations);
            system(command);

        % MATRIX_UPDATE: Only for the last run each iteration
            system('python data/WMATRIX/generate_wmatrix_Minus.py');
            if (strcmp(WhichType,'perturbation'))
                system('python data/WMATRIX/generate_wmatrix_minusside.py');
            end
            system('mv SimMobility_Minus/assignment_matrix.csv RESULT/lastAssignmentMatrix_Minus.csv');
             
        % Generation of Vectors: simCounts & trueCounts
            system('Rscript generate_counts_vector_LaneLv_Minus.R')
            simcount = load('data/simcount_Minus.csv'); truecount = load('data/truecount_Minus.csv'); simcount_forRM = load('data/simCountsRM_Minus.csv'); truecount_forRM = load('data/trueCountsRM_Minus.csv');
            truecount_var = load('data/trueCountsVar_Minus.csv'); truecount_obs = load('data/trueCountsObs_Minus.csv');
            
        % Generation of Vectors: simTravelTime & trueTravelTime 
            system('Rscript data/generate_traveltime_vector_Generous_Minus.R')
            trueTravelTime_forRM = load('data/TravelTimeData/trueTravelTime_RM_Minus.csv'); simTravelTime_forRM = load('data/TravelTimeData/simTravelTime_RM_Minus.csv');
            trueTravelTime_var = load('data/TravelTimeData/trueTravelTime_Var_Minus.csv'); trueTravelTime_obs = load('data/TravelTimeData/trueTravelTime_Obs_Minus.csv');
            trueTravelTime = load('data/TravelTimeData/trueTravelTime_Minus.csv'); simTravelTime = load('data/TravelTimeData/simTravelTime_Minus.csv');
            
       end % Minus 
       
       %% SPSA
        if (pf==3) % spsa
            % update driver params
                updateParams = '';    
                for i = 1:size(dbparams)
                    updateParams = strcat(updateParams, num2str(dbparams(i)));
                    updateParams = strcat(updateParams, ',');
                end

                command = 'python updateDriverParamXML_Whole_set.py';
                command = sprintf('%s %s %s %s', './runApplication.sh', command, 'SimMobility_SPSA/data/driver_behavior_model/driver_param.xml', updateParams);
                system(command);
                
             % update driver params
                updatercparams = '';    
                for i = 1:size(routechoiceparams)
                    updatercparams = strcat(updatercparams, num2str(routechoiceparams(i)));
                    updatercparams = strcat(updatercparams, ',');
                end

                command = 'python updateRouteChoiceParamsXML.py';
                command = sprintf('%s %s %s %s', './runApplication.sh', command, 'SimMobility_SPSA/data/pathset_config.xml', updatercparams);
                system(command);

            % Truncating OD dash
                system('Rscript data/TripChain/PostF_inLoop_SPSA.R')
            % TC from g-function
                system('python ODMatrixToTripChain_SPSA.py');

            % Run SimMobility
                cd('SimMobility_SPSA/')
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

                pause(5)

                command = 'python consolidateLoopData_SPSA.py';
                command = sprintf('%s %s %d', './runApplication.sh', command, iterations);
                system(command);

            % MATRIX_UPDATE: Only for the last run each iteration
                % W generation   
                system('python data/WMATRIX/generate_wmatrix_SPSA.py');
                system('mv SimMobility_SPSA/assignment_matrix.csv RESULT/lastAssignmentMatrix_SPSA.csv');
                
            % Generation of Vectors: simCounts & trueCounts
                %command = sprintf('%s %s %s %s %d %d', './runApplication.sh', 'python generate_counts_vector_Plus.py', num2str(start_time), num2str(end_time), sensor_interval, free_flow_interval);
                %system(command);           
                system('Rscript generate_counts_vector_LaneLv_SPSA.R')
                simcount = load('data/simcount_SPSA.csv'); truecount = load('data/truecount_SPSA.csv'); simcount_forRM = load('data/simCountsRM_SPSA.csv'); truecount_forRM = load('data/trueCountsRM_SPSA.csv');      
                truecount_var = load('data/trueCountsVar_SPSA.csv'); truecount_obs = load('data/trueCountsObs_SPSA.csv');
    
            % Generation of Vectors: simTravelTime & trueTravelTime 
                system('Rscript data/generate_traveltime_vector_Generous_SPSA.R')
                trueTravelTime_forRM = load('data/TravelTimeData/trueTravelTime_RM_SPSA.csv'); simTravelTime_forRM = load('data/TravelTimeData/simTravelTime_RM_SPSA.csv');
                trueTravelTime_var = load('data/TravelTimeData/trueTravelTime_Var_SPSA.csv'); trueTravelTime_obs = load('data/TravelTimeData/trueTravelTime_Obs_SPSA.csv');
                trueTravelTime = load('data/TravelTimeData/trueTravelTime_SPSA.csv'); simTravelTime = load('data/TravelTimeData/simTravelTime_SPSA.csv');

        end % SPSA
       
       %% Make vector
       
        PMstructure.simcount = simcount;
        PMstructure.truecount = truecount;
        PMstructure.simcount_forRM = simcount_forRM;
        PMstructure.truecount_forRM = truecount_forRM;
        PMstructure.trueTravelTime_forRM = trueTravelTime_forRM;
        PMstructure.simTravelTime_forRM = simTravelTime_forRM;
        PMstructure.truecount_var = truecount_var;
        PMstructure.truecount_obs = truecount_obs;
        PMstructure.trueTravelTime_var = trueTravelTime_var;
        PMstructure.trueTravelTime_obs = trueTravelTime_obs;
        PMstructure.trueTravelTime = trueTravelTime;
        PMstructure.simTravelTime = simTravelTime;

end

