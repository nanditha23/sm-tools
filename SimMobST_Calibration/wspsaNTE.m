%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% W-SPSA program

% the Matlab code for WSPSA calibration algorithm 
% Lu Lu, Sep 2012 - Edit by CLA Jul, 2013; 
% Edit by Shi Wang for NTE network, April, 2015

% Edit to sync with SimMobility ShortTerm, Feb, 2016
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Initialization
    fprintf('\n\nSTARTING WSPSA\n\n')
    % Declare Global Variables
        global no_sensors; global no_ODs;  global no_dbparam;  global no_sensor_intervals; 
        global ITERATION_SWITCH; global counter_glob; global no_rcparams;
        global start_time; global end_time; global od_interval; global sensor_interval;
        global initial_db; global initial_rc;
        global free_flow_interval; global mop
        counter_glob=0; global num_det;

    % Read configure.m to set parameter values
        %configure
        configure_Whole_set
        mop = 1;
        
    %% OD and sensor vector for W-matrix and etc.         
        Ref_count_Wmat= load('data/ref_segments.csv');
        num_sensors = size(Ref_count_Wmat); num_sensors = num_sensors(1,1)
        end_T = end_time * 60;
        start_T = start_time * 60;
        N_sensor=num_sensors*((end_T-start_T)/sensor_interval);
        
    %% SEED OD LOAD
        fprintf('Loading seed OD parameters\n')
	system('Rscript data/TripChain/PostF_inLoop.R');
        od_seed = load('data/TripChain/Truncated_theta_od.csv'); % Converted from F-ft by dealing with MT demand
        N_OD = size(od_seed); N_OD=N_OD(1,1);
        no_ODs=N_OD/((end_T-start_T)/od_interval);
	    save('data/TripChain/theta_OD_dash_Plus.csv', 'od_seed', '-ascii');

    %% DRIVER BEHAVIOUR LOAD
        dbparams = initial_db';
        routechoiceparams = initial_rc';
        no_dbparam= size(dbparams);
        no_dbparam=no_dbparam(1,1);
        no_rcparams = size(routechoiceparams);
        no_rcparams = no_rcparams(1,1);
        
    %% INITIAL OBJECTIVE VALUE: Through Plus side simulator
        fprintf('\n\n RUNNIG initial Simulation - simulation %d\n',counter_glob)
              
        pf = 1; 
        [PMstructure] = CHANGEPARAMETERS_pf(dbparams, routechoiceparams, iterations, true, pf);
        
        pf = 1; 
        simcount = PMstructure(pf).simcount; truecount = PMstructure(pf).truecount; simcount_forRM = PMstructure.simcount_forRM; 
        truecount_forRM = PMstructure.truecount_forRM; trueTravelTime_forRM = PMstructure.trueTravelTime_forRM; simTravelTime_forRM = PMstructure.simTravelTime_forRM;
        clear PMstructure
        
        save(strcat('RESULT/simcount_for_RM0.csv'), 'simcount_forRM', '-ascii');      
        save(strcat('RESULT/truecount_for_RM0.csv'), 'truecount_forRM', '-ascii');
        save(strcat('RESULT/trueTravelTime_for_RM0.csv'), 'trueTravelTime_forRM', '-ascii');        
        save(strcat('RESULT/simTravelTime_for_RM0.csv'), 'simTravelTime_forRM', '-ascii');

        od_seed = load('data/TripChain/Truncated_theta_od_Plus.csv'); 
        theta_0 = [od_seed; dbparams; routechoiceparams];
        
        save(strcat('RESULT/od_seed_sim_final0.csv'), 'od_seed', '-ascii');
        save(strcat('RESULT/dbparams_initial.csv'), 'dbparams', '-ascii');
        save(strcat('RESULT/rcparams_initial.csv'), 'routechoiceparams', '-ascii');
        
        copyfile('SimMobility_Plus/DensityMap.csv' , strcat('RESULT/DensityMap_initial.csv'));
        copyfile('data/compare_counts_Plus.csv' , strcat('RESULT/compare_counts_initial.csv'));
        
        system('python UpsertTravelTime_Plus.py');
                
        % Object value computation (...actualparam, seedparams)
            [initial_fn_vector, objv]= FUNC(simcount, truecount, simcount_forRM, truecount_forRM, theta_0, theta_0, trueTravelTime_forRM, simTravelTime_forRM);
            last_y = initial_fn_vector;
            initial_fn_value = objv; %initial_fn_value = sum(initial_fn_vector);
                
        %initialize outputs
            fn_path = [];%objective function value
            fn_path = [fn_path; initial_fn_value];

        %lower bound and upper bound
        %Lower bound
            lb = [];
            lb = [lb; floor((theta_0(1:N_OD)+0.1)*lowerb(1,1))]; %OD
            lb = [lb; lowerb(2:no_dbparam+1,1)]; %db behavior - non ratio
            lb = [lb; lowerb(no_dbparam+1+1:no_dbparam+1+no_rcparams,1)]; %rc behavior - non ratio 
            
        %Upper bound
            ub = [];
            ub = [ub; floor((theta_0(1:N_OD)+0.1)*upperb(1,1))]; %OD
            ub = [ub; upperb(2:no_dbparam+1,1)];%behavior - non ratio 10EA
            ub = [ub; upperb(no_dbparam+1+1:no_dbparam+1+no_rcparams,1)]; %rc behavior - non ratio 11EA

        %load purturbation step size and advance step size
            perturb_step = perturb_step_init;
            perturb_od = ones(N_OD,1) * perturb_step(1,1); % S: c_k

        %Initialize the vector of parameters 
            simulation = theta_0;
            ods = od_seed;
            dbs = dbparams;
            rcs = routechoiceparams;

        %Initialize the vector of parameters 
            prev_y =[];
            prev_y = [prev_y; initial_fn_value];
            
            CheckITERATION_SWITCH =[];
            CheckITERATION_SWITCH =[CheckITERATION_SWITCH; ITERATION_SWITCH];
            
            InverseNeedless = []; InverseReject = []; InverseAccept = []; Steepness = []; 
        WD = 1; % Initial plus
      
%% Start Calibration loop
 %while k <= n
 for k = 1 : n
      counter_glob = counter_glob + 1;   
      fprintf('\n ##### Iteration %d\n',k)
      %% SWITCH TO BASIC SPSA
      if k < ITERATION_SWITCH 
        if WD == 1 %Reject inverse? Keep original?
            fprintf('Loading updated weight Matrix_Plus\n')
            % Fill with W-mat from Python
            sim_weights=load('data/WMATRIX/wmatrix_Plus.csv');
            wmatrix = sparse(N_OD, N_sensor); 
            size_w = size(sim_weights);
            for item = 1:size_w(1,1)
                wmatrix((sim_weights(item,1)+1), (sim_weights(item,2)+1)) = sim_weights(item,3);
            end
        end
        if WD == 2 %Accept inverse? 
            fprintf('Loading updated weight Matrix_Minus\n')
            % Fill with W-mat from Python
            sim_weights=load('data/WMATRIX/wmatrix_Minus.csv');
            wmatrix = sparse(N_OD, N_sensor); 
            size_w = size(sim_weights);
            for item = 1:size_w(1,1)
                wmatrix((sim_weights(item,1)+1), (sim_weights(item,2)+1)) = sim_weights(item,3);
            end
        end
      else 
        fprintf('Selecting SPSA\n');
      end
      
      if k > num_det % Random perturbation from the beginning 
          perturb_style(1,1) = 1;
      end     
    
      if k < ITERATION_SWITCH % 
          mop = 1;
          a					= 0.16*2; % Bugis: 0.16*2
          A = 60; sf_k = 1; a_k = a / (A + k^(sf_k) + 1)^alpha; 
          perturb_step_dynamic_plus =[5];
          perturb_od_plus = ones(N_OD,1) * perturb_step_dynamic_plus; % S: c_k 
          
          perturb_step_dynamic_minus =[5];
          perturb_od_minus = ones(N_OD,1) * perturb_step_dynamic_minus; % S: c_k 
      else
          mop = 3;
          a					= 0.16*0.05; % Bugis: 0.16*0.05
          A = 100; sf_k = 1; a_k = a / (A + k^(sf_k) + 1)^alpha;     
          perturb_step_dynamic_plus = [1];
          perturb_od_plus = ones(N_OD,1) * perturb_step_dynamic_plus; % S: c_k 
          
          perturb_step_dynamic_minus = [1];
          perturb_od_minus = ones(N_OD,1) * perturb_step_dynamic_minus; % S: c_k 
      end
      
      %% COMPUTE PERTURBATIONS
      % perturbation vector decided by perturbation style and step size for ODs
      if perturb_style(1,1) == 0 %fixed perturbation, all in a same direction
        delta_ods_plus = ones(N_OD,1) .* perturb_od_plus;
        delta_ods_minus = ones(N_OD,1) .* perturb_od_minus;
        %delta_ods = ones(N_OD,1) .* perturb_od;
      else
        delta_ods = 2 * round(rand(N_OD,1)) - 1; %random perturbation directions  
        %delta_ods = delta_ods .* perturb_od; % S: c_k.*delta_k
        delta_ods_plus = delta_ods .* perturb_od_plus; 
        delta_ods_minus = delta_ods .* perturb_od_minus; 
      end
      
      %for dbparams
      for j=1:no_dbparam % j=10
%           if perturb_style(j+1,1) == 0 %fixed perturbation, all in a same direction
%             delta_db(j) = perturb_step(j+1,1);
%           else
            delta_db(j) = 2 * round(rand(1,1)) - 1; %random perturbation directions
            delta_db(j) = delta_db(j) * perturb_step(j+1,1);
%           end
      end
      
      %for rc
      for j=1:no_rcparams % j=10
          if perturb_style(j+10+1,1) == 0 %fixed perturbation, all in a same direction
            delta_rc(j) = perturb_step(j+10+1,1);
          else
            delta_rc(j) = 2 * round(rand(1,1)) - 1; %random perturbation directions
            delta_rc(j) = delta_rc(j) * perturb_step(j+10+1,1);
          end
      end
      
      % SELECT ODs TO PERTURB BASED ON WMATRIX
      fprintf('Performing the perturbation\n')
      % Perturb the current vector based on ratio-nonratio
      % for ODs only perturb those in the wmatrix 
      OD_table = [];
      index = 1;
      max_index = N_OD;
      while (index <= max_index)
        if (k >= ITERATION_SWITCH)
           OD_table = [OD_table, index];
        elseif (sum(wmatrix(index,1:((N_sensor))))~=0)
           max_index = size(wmatrix,1);
           OD_table = [OD_table; index];
        end
        index = index + 1;
      end
            
      % Perform the Perturbation
      % Calculate the ODs need to skip because the warm up period and the non-midnight starting item
      past_od = 1 + no_ODs * warm_up;
      ods_plus = ods;
      ods_minus = ods;
      
      if ratio_nonratio(1,1) == 0 %non-ratio
        for i=1:length(OD_table)
          j=OD_table(i);
          if (j>= past_od)
              ods_plus(j,1) =  ods_plus(j,1) + delta_ods_plus(j,1);
              ods_minus(j,1) = ods_minus(j,1) - delta_ods_minus(j,1);
          end
        end
      else %ratio
        for i=1:length(OD_table)
            j=OD_table(i);
            if (j>= past_od)
                ods_plus(j,1) = ods_plus(j,1) * (1 + delta_ods_plus(j,1));
                ods_minus(j,1) = ods_minus(j,1) * (1 - delta_ods_minus(j,1));
            end
        end
      end
      
      % PERTURB DB PARAMS
      if ratio_nonratio(2,1) == 0 %non-ratio
        dbs_plus= dbs + delta_db';
        dbs_minus = dbs - delta_db';
      else
        dbs_plus = dbs .* (1 + delta_db');
        dbs_minus = dbs .* (1 - delta_db');
      end

      % PERTURB rc PARAMS
      if ratio_nonratio(2,1) == 0 %non-ratio
        rcs_plus= rcs + delta_rc';
        rcs_minus = rcs - delta_rc';
      else
        rcs_plus = rcs .* (1 + delta_rc');
        rcs_minus = rcs .* (1 - delta_rc');
      end
      
      % Boundaries
      sim_plus = [round(ods_plus); dbs_plus; rcs_plus];
      sim_plus(isnan(sim_plus))=0;
      sim_minus = [round(ods_minus); dbs_minus; rcs_minus];
      sim_minus(isnan(sim_minus))=0;
      sim_plus = min(sim_plus, ub); sim_plus = max(sim_plus, lb);
      sim_minus = min(sim_minus, ub); sim_minus = max(sim_minus, lb);
      
      isInitial = false;      
      
      % OD par save
      od_seed_plus = sim_plus(1:(end-no_rcparams-no_dbparam)); 
      save('data/TripChain/theta_OD_dash_Plus.csv', 'od_seed_plus', '-ascii');
      od_seed_minus = sim_minus(1:(end-no_rcparams-no_dbparam));
      save('data/TripChain/theta_OD_dash_Minus.csv', 'od_seed_minus', '-ascii');
            
    noPMrun=2;
    parpool('local', noPMrun);
    % Run SimMobility twice 
    parfor pf=1:noPMrun % pf=1: Plus, pf=2: Minus
        if pf==1 % Plus side 
            dbparams =  sim_plus((end-no_rcparams-no_dbparam+1):(end-no_rcparams));
            rcparams =  sim_plus((end-no_rcparams+1):end);
        end
        if pf==2 % Minus side 
            dbparams =  sim_minus((end-no_rcparams-no_dbparam+1):(end-no_rcparams));
            rcparams =  sim_minus((end-no_rcparams+1):end);
        end
        PMstructure(pf) = CHANGEPARAMETERS_pf(dbparams, rcparams, iterations, isInitial, pf);
    end
    delete(gcp); 

      % for plus
      pf = 1; 
      simcount = PMstructure(pf).simcount; 
      truecount = PMstructure(pf).truecount; 
      simcount_forRM = PMstructure(pf).simcount_forRM; 
      truecount_forRM = PMstructure(pf).truecount_forRM; 
      trueTravelTime_forRM = PMstructure(pf).trueTravelTime_forRM; 
      simTravelTime_forRM = PMstructure(pf).simTravelTime_forRM;
      
      [yplus, objv_plus] = FUNC(simcount_forRM, truecount_forRM, simcount_forRM, truecount_forRM, sim_plus, theta_0, trueTravelTime_forRM, simTravelTime_forRM);                  
      od_seed_plus = load('data/TripChain/Truncated_theta_od_Plus.csv'); save(strcat('RESULT/od_seed_sim_plus', num2str(k), '.csv'), 'od_seed_plus', '-ascii');
      
      % for minus
      pf = 2; 
      simcount = PMstructure(pf).simcount; 
      truecount = PMstructure(pf).truecount; 
      simcount_forRM = PMstructure(pf).simcount_forRM; 
      truecount_forRM = PMstructure(pf).truecount_forRM; 
      trueTravelTime_forRM = PMstructure(pf).trueTravelTime_forRM; 
      simTravelTime_forRM = PMstructure(pf).simTravelTime_forRM;
      
      [yminus, objv_minus] = FUNC(simcount_forRM, truecount_forRM, simcount_forRM, truecount_forRM, sim_minus, theta_0, trueTravelTime_forRM, simTravelTime_forRM);
      od_seed_minus = load('data/TripChain/Truncated_theta_od_Minus.csv'); save(strcat('RESULT/od_seed_sim_minus', num2str(k), '.csv'), 'od_seed_minus', '-ascii');
      
%% Original gradient & Inverse gradient
%% Original gradient: Calculate new od vector
      ydiff = yplus - yminus; % squared error vector
      simdiff = sim_plus - sim_minus;
      ysmat=[];
      gradient_ods = sparse(N_OD, 1); size_gods = size(gradient_ods);
      %a_k = a / (A + k^(sf_k) + a)^alpha ; %a_k = a / (A + k + 1)^alpha ;      
      for i = 1:N_OD
          total_diff = 0;
          if k >= ITERATION_SWITCH 
            gradient_ods(i,1) = total_diff + sum(ydiff); % minus in inverse case
            c=1.9; gamma = 0.101; %1.9
            c_k = c/(k+1)^gamma;
            gradient_ods_final = gradient_ods./(c_k*(ods_plus - ods_minus));
            ods_beforeConfirm = ods - a_k * gradient_ods_final;
          else
            gradient_ods(i,1) = total_diff + sum(wmatrix(i,1:(N_sensor))*(ydiff));
            c=1.9; gamma = 0.101; %1.9
            c_k = c/(k+1)^gamma;
            gradient_ods_final = gradient_ods./(c_k*(ods_plus - ods_minus));
            %gain= a_k * gradient_ods_final;
                %mag_scale = numel(num2str(gain));                
                %gradient_ods_final = gradient_ods_final .* (10.^(-(mag_scale-1)));
            ods_beforeConfirm = ods - a_k * gradient_ods_final;
          end
      end
%       ods_beforeConfirm = round(ods_beforeConfirm);
%       ods_beforeConfirm (isnan(ods_beforeConfirm ))=0;     
%       ods_beforeConfirm(ods_beforeConfirm<0)=0;
%       RMSN(ods_beforeConfirm, ods)
%       sum(ods_beforeConfirm)

      %supply and other parameters
        sum_ydiff = sum(ydiff);
        gradient_dbs = sum_ydiff ./ (dbs_plus - dbs_minus);
        for item=1:length(dbs)
            dbs_obj_val_exp(item) = floor(log10(abs(gradient_dbs(item))));
            dbs_val_exp(item) = floor(log10(abs(dbs(item))));
            dbs_weight(item) = 10 ^ (-(dbs_obj_val_exp(item) - dbs_val_exp(item))+1);
        end
        
        gradient_rcs = sum_ydiff ./ (rcs_plus - rcs_minus);
        for item=1:length(rcs)
            rcs_obj_val_exp(item) = floor(log10(abs(gradient_rcs(item))));
            rcs_val_exp(item) = floor(log10(abs(rcs(item))));
            rcs_weight(item) = 10 ^ (-(rcs_obj_val_exp(item) - rcs_val_exp(item))+1);
        end
                
        dbs_beforeConfirm = dbs - a_k *  gradient_dbs .* dbs_weight' ; %w_dbs = []
        rcs_beforeConfirm = rcs - a_k *  gradient_rcs .* rcs_weight' ; %w_rcs = []
        
      % Boundary for the new mistim vector
      ods_beforeConfirm(ods_beforeConfirm<0)=0;
      simulation = [round(ods_beforeConfirm);dbs_beforeConfirm; rcs_beforeConfirm];
      simulation(isnan(simulation))=0;     
      simulation = min(simulation, ub);
      simulation = max(simulation, lb);
      
      od_seed_sim = simulation(1:(end-no_rcparams-no_dbparam));
      dbparams_sim =  simulation((end-no_rcparams-no_dbparam+1):(end-no_rcparams)); 
      rcparams_sim =  simulation((end-no_rcparams+1):end); 
%% Inverse gradient: Calculate new od vector
      gradient_ods_final = - gradient_ods_final;
      gradient_rcs = - gradient_rcs;
      gradient_dbs = - gradient_dbs;

      %Calculate new od vector  
       ods_Inverse = ods - a_k * gradient_ods_final;

      %supply and other parameters
        sum_ydiff = sum(ydiff);
        gradient_dbs = sum_ydiff ./ (dbs_plus - dbs_minus);
        for item=1:length(dbs)
            dbs_obj_val_exp(item) = floor(log10(abs(gradient_dbs(item))));
            dbs_val_exp(item) = floor(log10(abs(dbs(item))));
            dbs_weight(item) = 10 ^ (-(dbs_obj_val_exp(item) - dbs_val_exp(item))+1);
        end

        gradient_rcs = sum_ydiff ./ (rcs_plus - rcs_minus);
        for item=1:length(rcs)
            rcs_obj_val_exp(item) = floor(log10(abs(gradient_rcs(item))));
            rcs_val_exp(item) = floor(log10(abs(rcs(item))));
            rcs_weight(item) = 10 ^ (-(rcs_obj_val_exp(item) - rcs_val_exp(item))+1);
        end

        dbs_Inverse = dbs - a_k *  gradient_dbs .* dbs_weight' ; %w_dbs = []
        rcs_Inverse = rcs - a_k *  gradient_rcs .* rcs_weight' ; %w_rcs = []

      %Boundary for the new mistim vector
      ods_Inverse(ods_Inverse<0)=0;
      simulation_Inverse = [round(ods_Inverse);dbs_Inverse; rcs_Inverse];
      simulation_Inverse(isnan(simulation_Inverse))=0;     
      simulation_Inverse = min(simulation_Inverse, ub);
      simulation_Inverse = max(simulation_Inverse, lb);

      od_seed_sim_Inverse = simulation_Inverse(1:(end-no_rcparams-no_dbparam));
      dbparams_sim_Inverse =  simulation_Inverse((end-no_rcparams-no_dbparam+1):(end-no_rcparams)); 
      rcparams_sim_Inverse =  simulation_Inverse((end-no_rcparams+1):end);       
  
 %% OD dash for 2nd SimMobility Implementation (Input for g-function)
      % OD dash par save
      od_seed_plus = simulation(1:(end-no_rcparams-no_dbparam)); 
      save('data/TripChain/theta_OD_dash_Plus.csv', 'od_seed_plus', '-ascii');
      od_seed_minus = simulation_Inverse(1:(end-no_rcparams-no_dbparam));
      save('data/TripChain/theta_OD_dash_Minus.csv', 'od_seed_minus', '-ascii');
            
 %% Running simultaneously
    %CHANGEPARAMETERS(SimMobility);  
     noPMrun=2;
     parpool('local', noPMrun);
     parfor pf =1:noPMrun
      if pf == 1 % Plus side (with Original gradient)
          dbparams_sim =  simulation((end-no_rcparams-no_dbparam+1):(end-no_rcparams)); 
          rcparams_sim =  simulation((end-no_rcparams+1):end);       
      end
      if pf == 2 % Minus side (with Inverse gradient)
         dbparams_sim =  simulation_Inverse((end-no_rcparams-no_dbparam+1):(end-no_rcparams)); 
         rcparams_sim =  simulation_Inverse((end-no_rcparams+1):end);       
      end          
          PMstructure(pf) = CHANGEPARAMETERS_pf(dbparams_sim, rcparams_sim, iterations, isInitial, pf);
     end 
     delete(gcp); 

      % for plus
      pf = 1; 
      simcount = PMstructure(pf).simcount; 
      truecount = PMstructure(pf).truecount; 
      simcount_forRM = PMstructure(pf).simcount_forRM; 
      truecount_forRM = PMstructure(pf).truecount_forRM; 
      trueTravelTime_forRM = PMstructure(pf).trueTravelTime_forRM; 
      simTravelTime_forRM = PMstructure(pf).simTravelTime_forRM;
      
      [last_y, objv_last] = FUNC(simcount_forRM, truecount_forRM, simcount_forRM, truecount_forRM, simulation, theta_0, trueTravelTime_forRM, simTravelTime_forRM);                  
      od_seed_plus = load('data/TripChain/Truncated_theta_od_Plus.csv'); save(strcat('RESULT/od_seed_sim_plus', num2str(k), '.csv'), 'od_seed_plus', '-ascii');
      
      sum_last_y = objv_last; %sum_last_y = sum(last_y);
    
      % for minus
      pf = 2; 
      simcount_Inverse = PMstructure(pf).simcount; 
      truecount = PMstructure(pf).truecount; 
      simcount_forRM_Inverse = PMstructure(pf).simcount_forRM; 
      truecount_forRM = PMstructure(pf).truecount_forRM; 
      trueTravelTime_forRM_Inverse = PMstructure(pf).trueTravelTime_forRM; 
      simTravelTime_forRM_Inverse = PMstructure(pf).simTravelTime_forRM;
      
      [last_y, objv_last] = FUNC(simcount_forRM_Inverse, truecount_forRM, simcount_forRM_Inverse, truecount_forRM, simulation_Inverse, theta_0, trueTravelTime_forRM_Inverse, simTravelTime_forRM_Inverse);
      od_seed_minus = load('data/TripChain/Truncated_theta_od_Minus.csv'); save(strcat('RESULT/od_seed_sim_minus', num2str(k), '.csv'), 'od_seed_minus', '-ascii');   
      
      sum_last_y_Inverse = objv_last; %sum_last_y = sum(last_y);
          
      % Decision between Original and Opposite
          if (sum_last_y_Inverse > sum_last_y)  %  Back to before Confirm (InverseReject): Plus won (1)
            ods = simulation(1:(end-no_rcparams-no_dbparam));
            dbs =  simulation((end-no_rcparams-no_dbparam+1):(end-no_rcparams)); 
            rcs =  simulation((end-no_rcparams+1):end);       
            prev_y(1+k) = sum_last_y; 

            copyfile('SimMobility_Plus/data/driver_behavior_model/driver_param.xml' , strcat('SimMobility_Plus/data/driver_behavior_model/driver_param_',num2str(k) ,'.xml'));
            save(strcat('RESULT/simcount_for_RM', num2str(k), '.csv'), 'simcount_forRM', '-ascii');      
            save(strcat('RESULT/truecount_for_RM', num2str(k), '.csv'), 'truecount_forRM', '-ascii');
            save(strcat('RESULT/simTravelTime_for_RM', num2str(k), '.csv'), 'simTravelTime_forRM', '-ascii');      
            save(strcat('RESULT/trueTravelTime_for_RM', num2str(k), '.csv'), 'trueTravelTime_forRM', '-ascii');

            save(strcat('RESULT/od_seed_sim_final', num2str(k), '.csv'), 'od_seed_sim', '-ascii');
            save(strcat('RESULT/dbparams_sim', num2str(k), '.csv'), 'dbparams_sim', '-ascii');
            save(strcat('RESULT/rcparams_sim', num2str(k), '.csv'), 'rcparams_sim', '-ascii');
            copyfile('SimMobility_Plus/DensityMap.csv' , strcat('RESULT/DensityMap_',num2str(k) ,'.csv'));
            copyfile('data/compare_counts_Plus.csv' , strcat('RESULT/compare_counts_', num2str(k), '_gradient.csv'));   

            InverseReject = [InverseReject; k; RMSN(truecount_forRM, simcount_forRM); RMSN(truecount_forRM, simcount_forRM_Inverse); RMSN(truecount_forRM, simcount_forRM)-RMSN(truecount_forRM, simcount_forRM_Inverse)];
            aux='RESULT/InverseReject.dat';
            save(aux,'InverseReject','-ascii'); 

            Steepness = [Steepness; k; a_k; sum(ydiff); nanmean(full(abs(gradient_ods_final))); nansum(full(abs(gradient_ods_final)))];
            aux='RESULT/Steepness.dat';
            save(aux,'Steepness','-ascii');
            
            % Update travel time in data base   
                system('python UpsertTravelTime_Plus.py');
            
            % W decision
                WD = 1;
        else % Accept inverse case: Minus won (2)
            ods = simulation_Inverse(1:(end-no_rcparams-no_dbparam));
            dbs =  simulation_Inverse((end-no_rcparams-no_dbparam+1):(end-no_rcparams)); 
            rcs =  simulation_Inverse((end-no_rcparams+1):end);       
            prev_y(1+k) = sum_last_y_Inverse; 

            copyfile('SimMobility_Minus/data/driver_behavior_model/driver_param.xml' , strcat('SimMobility_Minus/data/driver_behavior_model/driver_param_',num2str(k) ,'.xml'));
            save(strcat('RESULT/simcount_for_RM', num2str(k), '.csv'), 'simcount_forRM_Inverse', '-ascii');      
            save(strcat('RESULT/truecount_for_RM', num2str(k), '.csv'), 'truecount_forRM', '-ascii');
            save(strcat('RESULT/simTravelTime_for_RM', num2str(k), '.csv'), 'simTravelTime_forRM_Inverse', '-ascii');      
            save(strcat('RESULT/trueTravelTime_for_RM', num2str(k), '.csv'), 'trueTravelTime_forRM', '-ascii');

            save(strcat('RESULT/od_seed_sim_final', num2str(k), '.csv'), 'od_seed_sim_Inverse', '-ascii');
            save(strcat('RESULT/dbparams_sim', num2str(k), '.csv'), 'dbparams_sim_Inverse', '-ascii');
            save(strcat('RESULT/rcparams_sim', num2str(k), '.csv'), 'rcparams_sim_Inverse', '-ascii');
            copyfile('SimMobility_Minus/DensityMap.csv' , strcat('RESULT/DensityMap_',num2str(k) ,'.csv'));
            copyfile('data/compare_counts_Minus.csv' , strcat('RESULT/compare_counts_', num2str(k), '_gradient.csv')); 

            InverseAccept = [InverseAccept; k; RMSN(truecount_forRM, simcount_forRM); RMSN(truecount_forRM, simcount_forRM_Inverse); RMSN(truecount_forRM, simcount_forRM)-RMSN(truecount_forRM, simcount_forRM_Inverse)];
            aux='RESULT/InverseAccept.dat';
            save(aux,'InverseAccept','-ascii');

            Steepness = [Steepness; k; a_k; sum(ydiff); nanmean(full(abs(gradient_ods_final))); nansum(full(abs(gradient_ods_final)))];
            aux='RESULT/Steepness.dat';
            save(aux,'Steepness','-ascii');
          
            % Update travel time in data base   
                system('python UpsertTravelTime_Minus.py');
                
            % W decision
                WD = 2;
          end   
        
          if k > (wind*2+wind_buffer) 
              previous = mean(prev_y((end-(2*wind-1)):(end-wind)));
              current = mean(prev_y((end-(wind-1)):end));
              if (previous-current)/previous <= 0.01 % Less than 1% improvement? 
                  ITERATION_SWITCH = k+1;
              end
          end
          
          termi = find(CheckITERATION_SWITCH(:) ~= CheckITERATION_SWITCH(1));
          if length(termi) ~= 0
              termi = termi(1)-1;
          else
              termi = n; % To avoid early termination
          end
          
          if k<=2 | termi(1)==n
              ITERATION_SWITCH = ITERATION_SWITCH_ORIGINAL;
          else
              ITERATION_SWITCH = termi(1);
          end
          
        CheckITERATION_SWITCH(1+k) = ITERATION_SWITCH;
        aux='RESULT/CheckITERATION_SWITCH.dat';
        save(aux,'CheckITERATION_SWITCH','-ascii');
        
        aux='RESULT/prev_y.dat';
        save(aux,'prev_y','-ascii');
        
      if (k == termi+termi_buffer) | (k==n)
          break;
      end

 end %iterations (k=1:n)
       
     
     
     
