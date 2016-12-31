%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% W-SPSA program - FUNC function evaluates the accuracy

% the Matlab code for WSPSA calibration algorithm 
% Lu Lu, Sep 2012 - Edit by CLA Jul, 2013; 
% Edit by Shi Wang for NTE network, April, 2015

% Edit to sync with SimMobility ShortTerm, Feb, 2016
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [y_C, y_T, y_OD, y_P, y_hybrid] = FUNC(simcount, truecount, simcount_forRM, truecount_forRM, actualparam, seedparams, trueTravelTime, simTravelTime, trueTravelTime_forRM, simTravelTime_forRM, truecount_var, truecount_obs, trueTravelTime_var, trueTravelTime_obs)
    %global mainoutput
    global counter_glob; 
    global no_rcparams; global no_dbparam
    
    % Testing
    %seedparams = theta_0;
    %actualparam = theta_0;
    
    format long;
    
    %% 1. Least square 
    % 1.1) Count
    devcount = (truecount-simcount).^2;
    bigsumC = sum(devcount);
        
    % 1.2) Travel-time
    devtraveltime = (trueTravelTime-simTravelTime).^2;
    bigsumT = sum(devtraveltime);
    
    % 1.3) Time dependent OD
    actualOD = actualparam(1:(end-no_rcparams-no_dbparam)); % actualparam = actualparam
    seedOD = seedparams(1:(end-no_rcparams-no_dbparam));    
    devOD = (actualOD-seedOD).^2;
    bigsumOD = sum(devOD);

    % 1.4) Driving behaviour / Route choice
    actualPar = actualparam((end-no_rcparams-no_dbparam+1):end); % actualparam = actualparam
    seedpPar = seedparams((end-no_rcparams-no_dbparam+1):end); % seedparams = seedparams
    devparam = (actualPar-seedpPar).^2;
    bigsumP = sum(devparam);
    
    %% 2. Least square / Var
    % 2.1) Count
    LSvar_devcount = devcount./truecount_var;
    
    % 2.2) Travel-time
    LSvar_devtraveltime = devtraveltime./trueTravelTime_var;
    
    % 2.3) Time dependent OD
    devOD_var = 1; % Assumption
    LSvar_devOD = devOD./devOD_var;
    
    % 2.4) Driving behaviour / Route choice
    devparam_var = 1; % Assumption
    LSvar_devparam = devparam./devparam_var;
    
    %% 3. sum(Least square) / Var (Output of FUNC.m)
    y_C = LSvar_devcount; y_C(isinf(y_C))=0; y_C(isnan(y_C))=0; 
    y_T = LSvar_devtraveltime; y_T(isinf(y_T))=0; y_T(isnan(y_T))=0; 
    y_OD = LSvar_devOD; y_OD(isinf(y_OD))=0; y_OD(isnan(y_OD))=0; 
    y_P = LSvar_devparam; y_P(isinf(y_P))=0; y_P(isnan(y_P))=0; 
        
    sumLSvar = sum(y_C)+sum(y_T)+sum(y_OD)+sum(y_P);
    y_hybrid = sumLSvar; 
    
    %% 4. RMSN
    % 4.1) Count
    RMSE_counts = RMSE(truecount_forRM, simcount_forRM);
    RMSN_counts = RMSN(truecount_forRM, simcount_forRM);
    
    % 4.2) Travel-time
    RMSE_TravelTime = RMSE(trueTravelTime_forRM, simTravelTime_forRM);
    RMSN_TravelTime = RMSN(trueTravelTime_forRM, simTravelTime_forRM);
    
    % 4.3) Time dependent OD
    RMSE_OD = RMSE(seedOD,actualOD);
    RMSN_OD = RMSN(seedOD,actualOD);
   
    % 4.4) Driving behaviour / Route choice
    RMSE_param = RMSE(seedOD,actualOD);
    RMSN_param = RMSN(seedOD,actualOD);
            
    if (counter_glob == 0)
        % Count
        fn_RMSEC = []; fn_RMSNC = []; 
        fn_RMSEC = [1 (RMSE_counts)]; fn_RMSNC = [1 (RMSN_counts)];
        save('RESULT/fn_RMSEC.dat','fn_RMSEC','-ascii');
        save('RESULT/fn_RMSNC.dat','fn_RMSNC','-ascii');

        % Travel-time
        fn_RMSET = []; fn_RMSNT = []; 
        fn_RMSET = [1 RMSN_TravelTime]; fn_RMSNT = [1 RMSN_TravelTime];
        save('RESULT/fn_RMSET.dat','fn_RMSET','-ascii');
        save('RESULT/fn_RMSNT.dat','fn_RMSNT','-ascii');
        
        % Time dependent OD
        fn_RMSEOD = []; fn_RMSNOD = []; 
        fn_RMSEOD = [1 (RMSE_OD)]; fn_RMSNOD = [1 (RMSN_OD)];
        save('RESULT/fn_RMSEOD.dat','fn_RMSEOD','-ascii');
        save('RESULT/fn_RMSNOD.dat','fn_RMSNOD','-ascii');    
        
        % Driving behaviour / Route choice
        fn_RMSEP = []; fn_RMSNP = []; 
        fn_RMSEP = [1 RMSE_param]; fn_RMSNP = [1 RMSN_param];        
        save('RESULT/fn_RMSEP.dat','fn_RMSEP','-ascii');
        save('RESULT/fn_RMSNP.dat','fn_RMSNP','-ascii');
    else 
        % Count
        load(['RESULT/fn_RMSEC.dat']);
            fn_RMSEC = [fn_RMSEC; counter_glob RMSE_counts];
            save('RESULT/fn_RMSEC.dat','fn_RMSEC','-ascii');
        load(['RESULT/fn_RMSNC.dat']);
            fn_RMSNC = [fn_RMSNC; counter_glob RMSN_counts];
            save('RESULT/fn_RMSNC.dat','fn_RMSNC','-ascii');
        
        % Travel-time
        load(['RESULT/fn_RMSET.dat']);
            fn_RMSET = [fn_RMSET; counter_glob RMSE_TravelTime];
            save('RESULT/fn_RMSET.dat','fn_RMSET','-ascii');        
        load(['RESULT/fn_RMSNT.dat']);
            fn_RMSNT = [fn_RMSNT; counter_glob RMSN_TravelTime];
            save('RESULT/fn_RMSNT.dat','fn_RMSNT','-ascii');
       
        % Time dependent OD
        load(['RESULT/fn_RMSEOD.dat']);
            fn_RMSEOD = [fn_RMSEOD; counter_glob RMSE_OD];
            save('RESULT/fn_RMSEOD.dat','fn_RMSEOD','-ascii');        
        load(['RESULT/fn_RMSNOD.dat']);
            fn_RMSNOD = [fn_RMSNOD; counter_glob RMSN_OD];
            save('RESULT/fn_RMSNOD.dat','fn_RMSNOD','-ascii');
        
        % Driving behaviour / Route choice
        load(['RESULT/fn_RMSEP.dat']);
            fn_RMSEP = [fn_RMSEP; counter_glob RMSE_param];
            save('RESULT/fn_RMSEP.dat','fn_RMSEP','-ascii');        
        load(['RESULT/fn_RMSNP.dat']);
            fn_RMSNP = [fn_RMSNP; counter_glob RMSN_param];
            save('RESULT/fn_RMSNP.dat','fn_RMSNP','-ascii');
    end
    
end
