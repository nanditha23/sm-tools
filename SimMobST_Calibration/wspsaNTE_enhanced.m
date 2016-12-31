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
        global free_flow_interval; global mop; global N_Param
        counter_glob=0; global num_det;

    % Read configure.m to set parameter values
        %configure
        configure_Whole_set
        mop = 1;
        
    %% OD and sensor vector for W-matrix and etc.         
        Ref_count_Wmat= load('data/ref_segments_LaneLv5min.csv');
        num_sensors = size(Ref_count_Wmat); num_sensors = num_sensors(1,1);
        end_T = end_time * 60;
        start_T = start_time * 60;
        N_sensor=num_sensors*((end_T-start_T)/sensor_interval);
        
    %% SEED OD LOAD
        fprintf('Loading seed OD parameters\n')
        system('Rscript data/TripChain/PostF_inLoop.R');
        od_seed = load('data/TripChain/Truncated_theta_od.csv'); % Converted from F-ft by dealing with MT demand
        N_OD = size(od_seed); N_OD=N_OD(1,1);
        no_ODs = N_OD/((end_T-start_T)/od_interval);
	    save('data/TripChain/theta_OD_dash_Plus.csv', 'od_seed', '-ascii');

    %% DRIVER BEHAVIOUR LOAD
        dbparams = initial_db';
        routechoiceparams = initial_rc';
        no_dbparam= size(dbparams);
        no_dbparam=no_dbparam(1,1);
        no_rcparams = size(routechoiceparams);
        no_rcparams = no_rcparams(1,1);
        
        N_Param = N_OD+no_dbparam+no_rcparams; 
    %% INITIAL OBJECTIVE VALUE: Through Plus side simulator
        fprintf('\n\n RUNNIG initial Simulation - simulation %d\n',counter_glob)
              
        pf = 1; 
        [PMstructure] = CHANGEPARAMETERS_pf(dbparams, routechoiceparams, iterations, pf, 'initial');
        
        pf = 1; 
        simcount = PMstructure(pf).simcount; truecount = PMstructure(pf).truecount; 
        simcount_forRM = PMstructure(pf).simcount_forRM; truecount_forRM = PMstructure(pf).truecount_forRM; 
        trueTravelTime_forRM = PMstructure(pf).trueTravelTime_forRM; simTravelTime_forRM = PMstructure(pf).simTravelTime_forRM;
        truecount_var = PMstructure(pf).truecount_var; truecount_obs = PMstructure(pf).truecount_obs; 
        trueTravelTime_var = PMstructure(pf).trueTravelTime_var; trueTravelTime_obs = PMstructure(pf).trueTravelTime_obs; 
        trueTravelTime = PMstructure(pf).trueTravelTime; simTravelTime = PMstructure(pf).simTravelTime;

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
            %[initial_fn_vector, objv]= FUNC(simcount, truecount, simcount_forRM, truecount_forRM, theta_0, theta_0, trueTravelTime_forRM, simTravelTime_forRM, truecount_var, truecount_obs, trueTravelTime_var, trueTravelTime_obs);            
            [initial_fn_vector_C, initial_fn_vector_T, initial_fn_vector_OD, initial_fn_vector_P, objv] = FUNC(simcount, truecount, simcount_forRM, truecount_forRM, theta_0, theta_0, trueTravelTime, simTravelTime, trueTravelTime_forRM, simTravelTime_forRM, truecount_var, truecount_obs, trueTravelTime_var, trueTravelTime_obs);
            
            %last_y = initial_fn_vector;
            initial_fn_value = objv; 
                
        %initialize outputs
            fn_path = [];%objective function value
            fn_path = [fn_path; initial_fn_value];

        %lower bound and upper bound
        %Lower bound
            lb = [];
            %lb = [lb; floor((theta_0(1:N_OD)+0.1)*lowerb(1,1))]; %OD
            lb = [lb; ones(N_OD,1).*lowerb(1,1)]; %OD
            lb = [lb; lowerb(2:no_dbparam+1,1)]; %db behavior - non ratio
            lb = [lb; lowerb(no_dbparam+1+1:no_dbparam+1+no_rcparams,1)]; %rc behavior - non ratio 
            
        %Upper bound
            ub = [];
            %ub = [ub; floor((theta_0(1:N_OD)+0.1)*upperb(1,1))]; %OD
            ub = [ub; ones(N_OD,1).*upperb(1,1)]; %OD
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
            
        WD = 1; % Initial plus
      
%% Start Calibration loop
 for k = 1 : n
     counter_glob = counter_glob + 1;   
      %% Loading w-matrix
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
%         if WD == 3 
%             fprintf('Loading updated weight Matrix_SPSA\n')
%             % Fill with W-mat from Python
%             sim_weights=load('data/WMATRIX/wmatrix_SPSA.csv');
%             wmatrix = sparse(N_OD, N_sensor); 
%             size_w = size(sim_weights);
%             for item = 1:size_w(1,1)
%                 wmatrix((sim_weights(item,1)+1), (sim_weights(item,2)+1)) = sim_weights(item,3);
%             end
%         end
        if WD == 3 
            fprintf('Loading updated weight Matrix_SPSA\n')
            % Fill with W-mat from Python
            sim_weights=load('data/WMATRIX/wmatrix_plusside.csv');
            wmatrix = sparse(N_OD, N_sensor); 
            size_w = size(sim_weights);
            for item = 1:size_w(1,1)
                wmatrix((sim_weights(item,1)+1), (sim_weights(item,2)+1)) = sim_weights(item,3);
            end
        end
        if WD == 4 
            fprintf('Loading updated weight Matrix_SPSA\n')
            % Fill with W-mat from Python
            sim_weights=load('data/WMATRIX/wmatrix_minusside.csv');
            wmatrix = sparse(N_OD, N_sensor); 
            size_w = size(sim_weights);
            for item = 1:size_w(1,1)
                wmatrix((sim_weights(item,1)+1), (sim_weights(item,2)+1)) = sim_weights(item,3);
            end
        end
      end
      
      if k > num_det % Random perturbation from the beginning 
          perturb_style(1,1) = 1;
      end     
      
      % Perturbation for normalized param vector
      perturb_step = 0.01; % 1 percent?? NEED TO BE IMPROVED 
      perturb_step = ones(N_Param,1) * perturb_step;
      
      %% Normalization of parameter
      % Generate Etha
      Etha_i = [ods; dbs; rcs];
      Theta_LB = [repelem(upperb(1), N_OD), up_db, up_rc]';
      Theta_UB = [repelem(lowerb(1), N_OD), lb_db, lb_rc]';
      Etha = (Etha_i-Theta_LB)./(Theta_UB-Theta_LB);
      Etha(find(isnan(Etha)))=0;
      
      %% COMPUTE PERTURBATIONS
      % Perturbation of normalized parameter, Etha
      delta_params = 2 * round(rand(N_Param,1)) - 1; %random perturbation directions  
      delta_params = delta_params .* perturb_step;
      
      % Plus & Minus of Etha +/-
      % OD      
      % SELECT ODs TO PERTURB BASED ON WMATRIX
      fprintf('Performing the perturbation\n')
      % for ODs only perturb those in the wmatrix 
      OD_table = []; index = 1; max_index = N_OD;
      past_od = 1 + no_ODs * warm_up;

      while (index <= max_index)
        if (k >= ITERATION_SWITCH)
           OD_table = [OD_table, index];
        elseif (sum(wmatrix(index,1:((N_sensor))))~=0)
           max_index = size(wmatrix,1);
           OD_table = [OD_table; index];
        end
        index = index + 1;
      end
      delta_ods=delta_params(1:N_OD);
      ods_plus = Etha(1:N_OD);
      ods_minus = Etha(1:N_OD);
        for i=1:length(OD_table)
          j=OD_table(i);
          if (j>= past_od)
              ods_plus(j,1) =  ods_plus(j,1) + delta_ods(j,1);
              ods_minus(j,1) = ods_minus(j,1) - delta_ods(j,1);
          end
        end
      
      % DB / RC
      Etha_plus_DBRC = Etha(N_OD+1:end) + delta_params(N_OD+1:end);
      Etha_minus_DBRC = Etha(N_OD+1:end) - delta_params(N_OD+1:end);
      
      Etha_plus = [ods_plus; Etha_plus_DBRC];
      Etha_minus = [ods_minus; Etha_minus_DBRC];
            
      % Transfer from Etha to Theta
      Theta_temp_plus = Theta_LB + Etha_plus.*(Theta_UB - Theta_LB);
      Theta_temp_minus = Theta_LB + Etha_minus.*(Theta_UB - Theta_LB);
      
      ods_plus = Theta_temp_plus(1:N_OD); dbs_plus = Theta_temp_plus(1+N_OD:N_OD+no_dbparam); rcs_plus = Theta_temp_plus(1+N_OD+no_dbparam:end);
      ods_minus = Theta_temp_minus(1:N_OD); dbs_minus = Theta_temp_minus(1+N_OD:N_OD+no_dbparam); rcs_minus = Theta_temp_minus(1+N_OD+no_dbparam:end);
            
      % Boundaries on Theta
      sim_plus = [round(ods_plus); dbs_plus; rcs_plus]; sim_plus(isnan(sim_plus))=0;
      sim_minus = [round(ods_minus); dbs_minus; rcs_minus]; sim_minus(isnan(sim_minus))=0;
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
        PMstructure(pf) = CHANGEPARAMETERS_pf(dbparams, rcparams, iterations, pf, 'perturbation');
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
      truecount_var = PMstructure(pf).truecount_var;
      truecount_obs = PMstructure(pf).truecount_obs; 
      trueTravelTime_var = PMstructure(pf).trueTravelTime_var; 
      trueTravelTime_obs = PMstructure(pf).trueTravelTime_obs; 
      trueTravelTime = PMstructure(pf).trueTravelTime;
      simTravelTime = PMstructure(pf).simTravelTime;

      [yplus_C, yplus_T, yplus_OD, yplus_P, objv_plus] = FUNC(simcount, truecount, simcount_forRM, truecount_forRM, sim_plus, theta_0, trueTravelTime, simTravelTime, trueTravelTime_forRM, simTravelTime_forRM, truecount_var, truecount_obs, trueTravelTime_var, trueTravelTime_obs);                  
      
      od_seed_plus = load('data/TripChain/Truncated_theta_od_Plus.csv'); 
      save(strcat('RESULT/od_seed_sim_plus', num2str(k), '.csv'), 'od_seed_plus', '-ascii');
      
      % for minus
      pf = 2; 
      simcount = PMstructure(pf).simcount; 
      truecount = PMstructure(pf).truecount; 
      simcount_forRM = PMstructure(pf).simcount_forRM; 
      truecount_forRM = PMstructure(pf).truecount_forRM; 
      trueTravelTime_forRM = PMstructure(pf).trueTravelTime_forRM; 
      simTravelTime_forRM = PMstructure(pf).simTravelTime_forRM;
      truecount_var = PMstructure(pf).truecount_var;
      truecount_obs = PMstructure(pf).truecount_obs; 
      trueTravelTime_var = PMstructure(pf).trueTravelTime_var; 
      trueTravelTime_obs = PMstructure(pf).trueTravelTime_obs; 
      trueTravelTime = PMstructure(pf).trueTravelTime; 
      simTravelTime = PMstructure(pf).simTravelTime;

      [yminus_C, yminus_T, yminus_OD, yminus_P, objv_minus] = FUNC(simcount, truecount, simcount_forRM, truecount_forRM, sim_minus, theta_0, trueTravelTime, simTravelTime, trueTravelTime_forRM, simTravelTime_forRM, truecount_var, truecount_obs, trueTravelTime_var, trueTravelTime_obs);                  

      od_seed_minus = load('data/TripChain/Truncated_theta_od_Minus.csv'); save(strcat('RESULT/od_seed_sim_minus', num2str(k), '.csv'), 'od_seed_minus', '-ascii');
      
      PMstructure_plusminus = PMstructure;
      
    copyfile(strcat('SimMobility_Plus/DensityMap.csv'), strcat('SimMobility_Plus/DensityMap_plusside.csv'));
    copyfile(strcat('data/compare_counts_Plus.csv'), strcat('data/compare_counts_plusside.csv'));
    copyfile(strcat('SimMobility_Plus/supply.link_travel_time.txt'), strcat('SimMobility_Plus/supply.link_travel_time_plusside.txt'));
    
    copyfile(strcat('SimMobility_Minus/DensityMap.csv'), strcat('SimMobility_Minus/DensityMap_minusside.csv'));
    copyfile(strcat('data/compare_counts_Minus.csv'), strcat('data/compare_counts_minusside.csv'));
    copyfile(strcat('SimMobility_Minus/supply.link_travel_time.txt'), strcat('SimMobility_Minus/supply.link_travel_time_minusside.txt'));
      
%% Original gradient & Inverse gradient
%% Original gradient: Calculate new od vector
    % Objective vector from plus / minus
      ydiff_C = yplus_C - yminus_C;
      ydiff_T = yplus_T - yminus_T;
      ydiff_OD = yplus_OD - yminus_OD;
      ydiff_P = yplus_P - yminus_P;
      ydiff_A = [ydiff_OD; ydiff_P];
      %ydiff = [ydiff_C; ydiff_T; ydiff_OD; ydiff_P];
      
    % W-matrix generation
      w_C_OD = wmatrix; w_C_DB = ones(no_dbparam, N_sensor); w_C_RC = ones(no_rcparams, N_sensor); 
      w_C = vertcat(w_C_OD, w_C_DB, w_C_RC);
      w_T_OD = ones(N_OD, max(size(ydiff_T))); w_T_DB = ones(no_dbparam, max(size(ydiff_T))); w_T_RC = ones(no_rcparams, max(size(ydiff_T))); 
      w_T = vertcat(w_T_OD, w_T_DB, w_T_RC);
      w_A = diag(sparse(ones(1, N_OD+no_rcparams+no_dbparam)));
      %w_total = horzcat(w_C, w_T, w_A);

    % Gradient calculation
      gradient_beforeConfirm_C = w_C*ydiff_C;
      gradient_beforeConfirm_T = w_T*ydiff_T;
      gradient_beforeConfirm_A = w_A*ydiff_A ;
      
      gradient_beforeConfirm = gradient_beforeConfirm_C + gradient_beforeConfirm_T + gradient_beforeConfirm_A;

    % Algorithm parameter
      a = 0.16; A = 100000; a_k = a / (A + k + 1)^alpha;
      c=1.9; gamma = 0.101; c_k = c/(k+1)^gamma;
    
    % Update with gradient calculation
        gradient_beforeConfirm = gradient_beforeConfirm_C + gradient_beforeConfirm_T + gradient_beforeConfirm_A;
        numerator_grad = c_k*(Etha_plus-Etha_minus);
        gradient_final = gradient_beforeConfirm ./ numerator_grad;
        gradient_final(isinf(gradient_final))=0;
        Etha_beforeConfirm = Etha - a_k * gradient_final ;
                      
        Theta_beforeConfirm = Theta_LB + Etha_beforeConfirm.*(Theta_UB - Theta_LB);
        
        ods_beforeConfirm = Theta_beforeConfirm(1:N_OD); dbs_beforeConfirm = Theta_beforeConfirm(1+N_OD:N_OD+no_dbparam); rcs_beforeConfirm = Theta_beforeConfirm(1+N_OD+no_dbparam:end);

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
      gradient_final = - gradient_final;
      
      Etha_beforeConfirm = Etha - a_k * gradient_final;
      
      Theta_beforeConfirm = Theta_LB + Etha_beforeConfirm.*(Theta_UB - Theta_LB);
        
      ods_Inverse = Theta_beforeConfirm(1:N_OD); dbs_Inverse = Theta_beforeConfirm(1+N_OD:N_OD+no_dbparam); rcs_Inverse = Theta_beforeConfirm(1+N_OD+no_dbparam:end);
     
      %Boundary for the new mistim vector
      ods_Inverse(ods_Inverse<0)=0;
      simulation_Inverse = [round(ods_Inverse);dbs_Inverse; rcs_Inverse];
      simulation_Inverse(isnan(simulation_Inverse))=0;     
      simulation_Inverse = min(simulation_Inverse, ub);
      simulation_Inverse = max(simulation_Inverse, lb);

      od_seed_sim_Inverse = simulation_Inverse(1:(end-no_rcparams-no_dbparam));
      dbparams_sim_Inverse =  simulation_Inverse((end-no_rcparams-no_dbparam+1):(end-no_rcparams)); 
      rcparams_sim_Inverse =  simulation_Inverse((end-no_rcparams+1):end);       
  
%% For g0: Gradient for Normal SPSA
    % Update with gradient calculation: g0
        gradient_beforeConfirm = sum(ydiff_C)+sum(ydiff_T)+sum(ydiff_A); % minus in inverse case
        numerator_grad = c_k*(Etha_plus-Etha_minus);
        gradient_final = gradient_beforeConfirm./numerator_grad; 
        gradient_final(isinf(gradient_final))=0;
        Etha_beforeConfirm = Etha - a_k * gradient_final;
        
        Theta_beforeConfirm = Theta_LB + Etha_beforeConfirm.*(Theta_UB - Theta_LB);
        
        ods_beforeConfirm = Theta_beforeConfirm(1:N_OD); dbs_beforeConfirm = Theta_beforeConfirm(1+N_OD:N_OD+no_dbparam); rcs_beforeConfirm = Theta_beforeConfirm(1+N_OD+no_dbparam:end);
        
      % Boundary for the new mistim vector
          ods_beforeConfirm(ods_beforeConfirm<0)=0;
          simulation_0 = [round(ods_beforeConfirm);dbs_beforeConfirm; rcs_beforeConfirm];
          simulation_0(isnan(simulation_0))=0;     
          simulation_0 = min(simulation_0, ub);
          simulation_0 = max(simulation_0, lb);

          od_seed_sim_0 = simulation_0(1:(end-no_rcparams-no_dbparam));
          dbparams_sim_0 =  simulation_0((end-no_rcparams-no_dbparam+1):(end-no_rcparams)); 
          rcparams_sim_0 =  simulation_0((end-no_rcparams+1):end); 
           
 %% OD dash for 2nd SimMobility Implementation (Input for g-function)
      % OD dash par save
      od_seed_plus = simulation(1:(end-no_rcparams-no_dbparam)); 
      save('data/TripChain/theta_OD_dash_Plus.csv', 'od_seed_plus', '-ascii');
      od_seed_minus = simulation_Inverse(1:(end-no_rcparams-no_dbparam));
      save('data/TripChain/theta_OD_dash_Minus.csv', 'od_seed_minus', '-ascii');
      
      od_seed_spsa = simulation_0(1:(end-no_rcparams-no_dbparam)); 
      save('data/TripChain/theta_OD_dash_SPSA.csv', 'od_seed_spsa', '-ascii');
            
 %% Running simultaneously g+ & g-
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
      PMstructure(pf) = CHANGEPARAMETERS_pf(dbparams_sim, rcparams_sim, iterations, pf, 'final');
     end 
     delete(gcp); 
     %pf = 3; % SPSA side
     %dbparams_sim =  simulation_0((end-no_rcparams-no_dbparam+1):(end-no_rcparams)); 
     %rcparams_sim =  simulation_0((end-no_rcparams+1):end);       
     %PMstructure(pf) = CHANGEPARAMETERS_pf(dbparams_sim, rcparams_sim, iterations, pf, 'final');
     
      % for plus
      pf = 1; 
      simcount = PMstructure(pf).simcount; 
      truecount = PMstructure(pf).truecount; 
      simcount_forRM = PMstructure(pf).simcount_forRM; 
      truecount_forRM = PMstructure(pf).truecount_forRM; 
      trueTravelTime_forRM = PMstructure(pf).trueTravelTime_forRM; 
      simTravelTime_forRM = PMstructure(pf).simTravelTime_forRM;
      truecount_var = PMstructure(pf).truecount_var;
      truecount_obs = PMstructure(pf).truecount_obs;
      trueTravelTime_var = PMstructure(pf).trueTravelTime_var; 
      trueTravelTime_obs = PMstructure(pf).trueTravelTime_obs; 
      trueTravelTime = PMstructure(pf).trueTravelTime; 
      simTravelTime = PMstructure(pf).simTravelTime;

      [last_y_C, last_y_T, last_y_OD, last_y_P, objv_last] = FUNC(simcount, truecount, simcount_forRM, truecount_forRM, simulation, theta_0, trueTravelTime, simTravelTime, trueTravelTime_forRM, simTravelTime_forRM, truecount_var, truecount_obs, trueTravelTime_var, trueTravelTime_obs);                  

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
      truecount_var = PMstructure(pf).truecount_var;
      truecount_obs = PMstructure(pf).truecount_obs;
      trueTravelTime_var = PMstructure(pf).trueTravelTime_var; 
      trueTravelTime_obs = PMstructure(pf).trueTravelTime_obs; 
      trueTravelTime = PMstructure(pf).trueTravelTime; 
      simTravelTime = PMstructure(pf).simTravelTime;

      [last_y_C, last_y_T, last_y_OD, last_y_P, objv_last] = FUNC(simcount_Inverse, truecount, simcount_forRM_Inverse, truecount_forRM, simulation_Inverse, theta_0, trueTravelTime, simTravelTime, trueTravelTime_forRM_Inverse, simTravelTime_forRM_Inverse, truecount_var, truecount_obs, trueTravelTime_var, trueTravelTime_obs);
      
      od_seed_minus = load('data/TripChain/Truncated_theta_od_Minus.csv'); save(strcat('RESULT/od_seed_sim_minus', num2str(k), '.csv'), 'od_seed_minus', '-ascii');   
      
      sum_last_y_Inverse = objv_last; %sum_last_y = sum(last_y);

      % for SPSA
%       pf = 3; 
%       simcount_0 = PMstructure(pf).simcount; 
%       truecount = PMstructure(pf).truecount; 
%       simcount_forRM_0 = PMstructure(pf).simcount_forRM; 
%       truecount_forRM_0 = PMstructure(pf).truecount_forRM;
%       trueTravelTime_forRM_0 = PMstructure(pf).trueTravelTime_forRM; 
%       simTravelTime_forRM_0 = PMstructure(pf).simTravelTime_forRM;
%       truecount_var_0 = PMstructure(pf).truecount_var; 
%       truecount_obs_0 = PMstructure(pf).truecount_obs; 
%       trueTravelTime_var_0 = PMstructure(pf).trueTravelTime_var; 
%       trueTravelTime_obs_0 = PMstructure(pf).trueTravelTime_obs; 
%       trueTravelTime_0 = PMstructure(pf).trueTravelTime; 
%       simTravelTime_0 = PMstructure(pf).simTravelTime;
% 
%       [last_y_C, last_y_T, last_y_OD, last_y_P, objv_last] = FUNC(simcount_0, truecount, simcount_forRM_0, truecount_forRM_0, simulation_0, theta_0, trueTravelTime_0, simTravelTime_0, trueTravelTime_forRM_0, simTravelTime_forRM_0, truecount_var_0, truecount_obs_0, trueTravelTime_var_0, trueTravelTime_obs_0);                  
% 
%       od_seed_spsa = load('data/TripChain/Truncated_theta_od_SPSA.csv'); save(strcat('RESULT/od_seed_sim_spsa', num2str(k), '.csv'), 'od_seed_spsa', '-ascii');
%       
%       sum_last_y_0 = objv_last;  
      
      
      %% Decision between those four: g+, g-, g0
        %ParamAll = horzcat(simulation, simulation_Inverse, simulation_0, sim_plus, sim_minus);
        ParamAll = horzcat(simulation, simulation_Inverse, sim_plus, sim_minus);
        %gs = horzcat(sum_last_y, sum_last_y_Inverse, sum_last_y_0, objv_plus, objv_minus);
        gs = horzcat(sum_last_y, sum_last_y_Inverse, objv_plus, objv_minus);
      
        gs_ind = find(min(gs)==gs);
        
        simulation_final = ParamAll(:,gs_ind);
        
        ods = simulation_final(1:(end-no_rcparams-no_dbparam));
        dbs = simulation_final((end-no_rcparams-no_dbparam+1):(end-no_rcparams)); 
        rcs = simulation_final((end-no_rcparams+1):end);       
        prev_y(1+k) = gs(:,gs_ind); 

%         if (gs_ind==1)
%                 gs_name = '_Plus';
%             elseif (gs_ind==2)
%                 gs_name = '_Minus';
%             elseif (gs_ind==3)
%                 gs_name = '_SPSA';
%             elseif (gs_ind==4)
%                 gs_name = '_plusside'; % 
%             elseif (gs_ind==5)
%                 gs_name = '_minusside'; % 
%         end
        
        if (gs_ind==1)
                gs_name = '_Plus';
            elseif (gs_ind==2)
                gs_name = '_Minus';
            %elseif (gs_ind==3)
            %    gs_name = '_SPSA';
            elseif (gs_ind==3)
                gs_name = '_plusside'; % 
            elseif (gs_ind==4)
                gs_name = '_minusside'; % 
        end
               

        if (gs_ind < 3)
            temp = PMstructure(gs_ind).simcount_forRM; save(strcat('RESULT/simcount_for_RM', num2str(k), '.csv'), 'temp', '-ascii');
            temp = PMstructure(gs_ind).truecount_forRM; save(strcat('RESULT/truecount_for_RM', num2str(k), '.csv'), 'temp', '-ascii');
            temp = PMstructure(gs_ind).simTravelTime_forRM; save(strcat('RESULT/simTravelTime_for_RM', num2str(k), '.csv'), 'temp', '-ascii');      
            temp = PMstructure(gs_ind).trueTravelTime_forRM; save(strcat('RESULT/trueTravelTime_for_RM', num2str(k), '.csv'), 'temp', '-ascii');
            temp = PMstructure(gs_ind).simTravelTime; save(strcat('RESULT/simTravelTime', num2str(k), '.csv'), 'temp', '-ascii');      
            temp = PMstructure(gs_ind).trueTravelTime; save(strcat('RESULT/trueTravelTime', num2str(k), '.csv'), 'temp', '-ascii');

            save(strcat('RESULT/od_seed_sim_final', num2str(k), '.csv'), 'ods', '-ascii');
            save(strcat('RESULT/dbparams_sim', num2str(k), '.csv'), 'dbs', '-ascii');
            save(strcat('RESULT/rcparams_sim', num2str(k), '.csv'), 'rcs', '-ascii');

            copyfile(strcat('SimMobility',gs_name,'/DensityMap.csv', strcat('RESULT/DensityMap_',num2str(k) , '.csv')));
            copyfile(strcat('data/compare_counts',gs_name,'.csv', strcat('RESULT/compare_counts_',num2str(k), '_gradient.csv')));
        elseif (gs_ind >= 3)
            temp = PMstructure_plusminus(gs_ind-2).simcount_forRM; save(strcat('RESULT/simcount_for_RM', num2str(k), '.csv'), 'temp', '-ascii');
            temp = PMstructure_plusminus(gs_ind-2).truecount_forRM; save(strcat('RESULT/truecount_for_RM', num2str(k), '.csv'), 'temp', '-ascii');
            temp = PMstructure_plusminus(gs_ind-2).simTravelTime_forRM; save(strcat('RESULT/simTravelTime_for_RM', num2str(k), '.csv'), 'temp', '-ascii');      
            temp = PMstructure_plusminus(gs_ind-2).trueTravelTime_forRM; save(strcat('RESULT/trueTravelTime_for_RM', num2str(k), '.csv'), 'temp', '-ascii');
            temp = PMstructure_plusminus(gs_ind-2).simTravelTime; save(strcat('RESULT/simTravelTime', num2str(k), '.csv'), 'temp', '-ascii');      
            temp = PMstructure_plusminus(gs_ind-2).trueTravelTime; save(strcat('RESULT/trueTravelTime', num2str(k), '.csv'), 'temp', '-ascii');

            save(strcat('RESULT/od_seed_sim_final', num2str(k), '.csv'), 'ods', '-ascii');
            save(strcat('RESULT/dbparams_sim', num2str(k), '.csv'), 'dbs', '-ascii');
            save(strcat('RESULT/rcparams_sim', num2str(k), '.csv'), 'rcs', '-ascii');
            
            if (gs_ind == 3)
            copyfile(strcat('SimMobility_Plus/DensityMap_plusside.csv'), strcat('RESULT/DensityMap_',num2str(k) , '.csv'));
            copyfile(strcat('data/compare_counts_plusside.csv'), strcat('RESULT/compare_counts_',num2str(k), '_gradient.csv'));
            elseif (gs_ind == 4)
            copyfile(strcat('SimMobility_Minus/DensityMap_minusside.csv'), strcat('RESULT/DensityMap_',num2str(k) , '.csv'));
            copyfile(strcat('data/compare_counts_minusside.csv'), strcat('RESULT/compare_counts_',num2str(k), '_gradient.csv'));
            end
        end
        
        % W decision
            WD = gs_ind;
                            
        % Update travel time in data base 
            system(strcat('python UpsertTravelTime',gs_name,'.py'));
                        
        %% Convergence condition
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
          return;
      end

 end %iterations (k=1:n)
       
     
     
     
