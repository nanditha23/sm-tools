%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% W-SPSA program - FUNC function evaluates the accuracy

% the Matlab code for WSPSA calibration algorithm 
% Lu Lu, Sep 2012 - Edit by CLA Jul, 2013; 
% Edit by Shi Wang for NTE network, April, 2015

% Edit to sync with SimMobility ShortTerm, Feb, 2016
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [y, y_hybrid] = FUNC(simcount, truecount, simcount_forRM, truecount_forRM, actualparam, seedparams, trueTravelTime_forRM, simTravelTime_forRM)

    %global mainoutput
    global counter_glob; 
    global mop;
    global weights;
    global no_rcparams; global no_dbparam
    
    %configure;
    format long;

    bigsumC = 0; bigsumS = 0; bigsumP = 0;
    z = 0;
   
    totaldevC=[];RMSE_counts=[];RMSN_counts=[]; RMSN_traveltime=[];
    totaldevP=[];RMSE_param =[];RMSN_param=[];

    sim_count=simcount;

    devcounts = (truecount - sim_count);
    devtraveltime = (trueTravelTime_forRM - simTravelTime_forRM);

    diff_counts = devcounts'*devcounts;

    totaldevC=[totaldevC devcounts];

    RMSE_counts = [RMSE_counts RMSE(truecount_forRM, simcount_forRM)];
    RMSN_counts = [RMSN_counts RMSN(truecount_forRM, simcount_forRM)];
    RMSN_traveltime = [RMSN_traveltime RMSN(trueTravelTime_forRM, simTravelTime_forRM)];
    
    % Add to total
    bigsumC = bigsumC + diff_counts;

    % Except OD       
        %actualparam = sim_plus; 
        %seedparams = theta_0;
    actualPar = actualparam((end-no_rcparams-no_dbparam+1):end); % actualparam = actualparam
    seedpPar = seedparams((end-no_rcparams-no_dbparam+1):end); % seedparams = seedparams
    
    % OD
    actualOD = actualparam(1:(end-no_rcparams-no_dbparam)); % actualparam = actualparam
    seedOD = seedparams(1:(end-no_rcparams-no_dbparam));
    
    % params
    RMSE_param = RMSE(seedpPar,actualPar);
    RMSN_param = RMSN(seedpPar,actualPar);
    devparam = actualPar-seedpPar;
    bigsumP = devparam'*devparam;
    bigsumP = sum(abs(devparam));

    RMSE_OD = RMSE(seedOD,actualOD);
    RMSN_OD = RMSN(seedOD,actualOD);
    devOD = actualOD-seedOD;
    bigsumOD = devOD'*devOD;
    bigsumOD = sum(abs(devOD));
        
    if (counter_glob == 0)
       fn_Counts = [];
       fn_Counts = [1 bigsumC];
       fn_Params=[];
       fn_Params=[1 bigsumP];
       fn_RMSEC = []; fn_RMSES = [];
       fn_RMSNC = []; fn_RMSNS = [];
       fn_RMSEP = [];
       fn_RMSNP = [];
       fn_RMSEC = [1 (RMSE_counts)];
       fn_RMSNC = [1 (RMSN_counts)];
       fn_RMSEP = [1 RMSE_param];
       fn_RMSNP = [1 RMSN_param];
       fn_RMSNT = [];
       fn_RMSNT = [1 RMSN_traveltime];
       fn_RMSEO = [1 RMSE_OD];
       fn_RMSNO = [1 RMSN_OD];
       
        %save
        aux='RESULT/fn_Counts.dat';
        save(aux,'fn_Counts','-ascii');
        save('RESULT/fn_RMSEC.dat','fn_RMSEC','-ascii');
        save('RESULT/fn_RMSNC.dat','fn_RMSNC','-ascii');
        save('RESULT/fn_RMSES.dat','fn_RMSES','-ascii');
        save('RESULT/fn_RMSNS.dat','fn_RMSNS','-ascii');
        save('RESULT/fn_Params.dat','fn_Params','-ascii');
        save('RESULT/fn_RMSEP.dat','fn_RMSEP','-ascii');
        save('RESULT/fn_RMSNP.dat','fn_RMSNP','-ascii');
        save('RESULT/fn_RMSNO.dat','fn_RMSNP','-ascii');
        save('RESULT/fn_RMSNT.dat','fn_RMSNT','-ascii');

    else %if (mod(counter_glob,3) == 1)
        load('RESULT/fn_Counts.dat');
        fn_Counts = [fn_Counts ;counter_glob bigsumC];%diff_counts];
        save('RESULT/fn_Counts.dat','fn_Counts','-ascii');
        
        load('RESULT/fn_Params.dat');
        fn_Params = [fn_Params ;counter_glob bigsumP];
        save('RESULT/fn_Params.dat','fn_Params','-ascii');

        load(['RESULT/fn_RMSEC.dat']);
        fn_RMSEC = [fn_RMSEC ; counter_glob (RMSE_counts)];
        save('RESULT/fn_RMSEC.dat','fn_RMSEC','-ascii');
        
        load('RESULT/fn_RMSEP.dat');
        fn_RMSEP = [fn_RMSEP ; counter_glob RMSE_param];
        save('RESULT/fn_RMSEP.dat','fn_RMSEP','-ascii');

        load('RESULT/fn_RMSNC.dat');
        fn_RMSNC = [fn_RMSNC ; counter_glob (RMSN_counts)];
        save('RESULT/fn_RMSNC.dat','fn_RMSNC','-ascii');
        
        load('RESULT/fn_RMSNP.dat');
        fn_RMSNP = [fn_RMSNP ; counter_glob RMSN_param];
        save('RESULT/fn_RMSNP.dat','fn_RMSNP','-ascii');
        
        load('RESULT/fn_RMSNT.dat');
        fn_RMSNT = [fn_RMSNT ; counter_glob RMSN_traveltime];
        save('RESULT/fn_RMSNT.dat','fn_RMSNT','-ascii');
        
        load('RESULT/fn_RMSNO.dat');
        fn_RMSNT = [fn_RMSNO ; counter_glob RMSN_OD];
        save('RESULT/fn_RMSNO.dat','fn_RMSNO','-ascii');
    end

    %bigsumC = bigsumC/n_iterations;
    %bigsumS = bigsumS/n_iterations;
    
    switch mop
        case 1
            y = devcounts .^2; % Return the squred error vector
            weights = [1.0 0.0 0.0 0.0];
            y_hybrid = weights(1)*sum(devcounts.^2);
        case 2
            y = devparam .^2; % Return the squred error vector       
        case 3
            if (sum(devtraveltime.^2)==0)
                weights = [1.0 0.0 0.05 0.05];
            else
                lct=length(devcounts);
                ltt=length(devtraveltime);
                weights = [lct/(lct+ltt) ltt/(lct+ltt) 0.05 0.05];
            end
            y = weights(1)*devcounts.^2 + weights(2)*sum(devtraveltime.^2) + weights(3)*RMSN(seedOD,actualOD) + weights(4)*RMSN(seedpPar,actualPar); 
            y_hybrid = sum(y); 
        case 4
            y = weights(1)*devcounts .^2 + weights(2)*devtraveltime.^2; 
            y_hybrid = weights(1)*sum(devcounts.^2) + weights(2)*sum(devtraveltime.^2);
    end
    y(isinf(y))=0; %%%TEMP, TO BE REVISED    
    y(isnan(y))=0; %%%TEMP, TO BE REVISED    
end
