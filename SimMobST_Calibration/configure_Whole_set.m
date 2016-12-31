   
    % Revised DB Params after initial extended CBD calibration
  
   initial_db = [5.0788936 ... % min_response_distance [0]
                  0.03615767 0.6335278 0.2255 0.759022 0.474564 ... % ... % CF_parameters_1 [1-5]
                  -0.0548 0.000 0.000082138 0.08655550 0.7118259 ... % CF_parameters_2 [6-10]
                  0.075259 ... % FF_Acc_Params_b2 [11]
                  1.43 ... % speed_factor [12]
                  0.62948 0.532949 0.4252931 0.03016 0.1206687 0.4618029 -0.6065211 -0.43655782 0.0576622 0.153 0.94424077 0.0574317 0.15 ... % target_gap_acc_parm [13-25]
                  6.0 5.50 5.0 4.50 4.00 ... % max_acc_car1 [26-30] **
                  -2.5 -2.25 -2.00 -1.75 -1.50 ... % normal_deceleration_car1 [31-35]
                  -9.00 -8.50 -8.00 -7.50 -7.00 ... % max_deceleration_car1 [36-40]
                  1.0 ... % hbuffer_lower [41]
                  1.850875 2.109445 2.263295 2.386205 2.496535 2.60338 2.71371 2.83662 2.99047 3.24904 ... % hbuffer_upper [42-51]
                  1.0 ... % yellow_stop_headway [52]
                  2.2352 ... % min_speed_yellow [53]
                  150.0 ... % driver_signal_perception_distance [54]
                  0.4 ... % dec_update_step_size or stopped_vehicle_update_step_size [55]
                  0.5 ... % acc_update_step_size or uniform_speed_update_step_size [56]
                  750.0 1000.0 2.0 ... % MLC_PARAMETERS [57-59]
                  4.2656 0.3213 -1.1683 0.0 0.08 -1.0 0.009 -0.2664 -0.012 -3.3754 ... % lane_utility_model [60-69]
                  10 19 -2.3400 -4.5084 -2.8257 -1.2597 -0.7239 -0.3269 ... % lane_utility_model [70-77]
                  0.2 -0.231 -2.700 1.112 0.5 0.000 0.2 0.742 0.6 ... % critical_gaps_param [78 - 86]
                  -0.837 0.913 0.816 -1.218 -2.393 -1.662 ... % Target_Gap_Model [87-92]
                  1.0 0.5 0.6 0.1 0.5 1.0 30.0 100.0 600.0 40.0 ... % nosing_param [93-102]
                  0.5 ... % CF_CRITICAL_TIMER_RATIO [103]
                  0.3 ... % intersection_attentiveness_factor_min [104]
                  0.6 ... % intersection_attentiveness_factor_max [105]
                  1.25 ... % minimum_gap [106]
                  1.0 0.5 ... % critical gap addon [107-108]
                  0.2 ... %  minimum_gap [109]
                  7 ... % LC Discretionary_Lane_Change_Model_Same [110]
                  15]; % LC Discretionary_Lane_Change_Model_Diff [111]
    
% Initial DB Params (from literature/previous MITSIM calibration)
              
%     initial_db = [2.5 ... % min_response_distance [0]
%                   0.045 0.740 0.205 0.750 0.494 ... % ... % CF_parameters_1 [1-5]
%                   -0.40 0.000 0.650 0.850 0.605 ... % CF_parameters_2 [6-10]
%                   0.3091 ... % FF_Acc_Params_b2 [11]
%                   1.3 ... % speed_factor [12]
%                   0.604 0.385 0.323 0.0678 0.217 0.583 -0.596 -0.219 0.0832 0.170 1.478 0.131 0.300 ... % target_gap_acc_parm [13-25]
%                   6.0 5.50 5.0 4.50 4.00 ... % max_acc_car1 [26-30]
%                   -2.5 -2.25 -2.00 -1.75 -1.50 ... % normal_deceleration_car1 [31-35]
%                   -9.00 -8.50 -8.00 -7.50 -7.00 ... % max_deceleration_car1 [36-40]
%                   1.0 ... % hbuffer_lower [41]
%                   1.850875 2.109445 2.263295 2.386205 2.496535 2.60338 2.71371 2.83662 2.99047 3.24904 ... % hbuffer_upper [42-51]
%                   1.0 ... % yellow_stop_headway [52]
%                   2.2352 ... % min_speed_yellow [53]
%                   150.0 ... % driver_signal_perception_distance [54]
%                   0.4 ... % dec_update_step_size or stopped_vehicle_update_step_size [55]
%                   0.5 ... % acc_update_step_size or uniform_speed_update_step_size [56]
%                   750.0 1000.0 2.0 ... % MLC_PARAMETERS [57-59]
%                   4.2656 0.3213 -1.1683 0.0 0.08 -1.0 0.009 -0.2664 -0.012 -3.3754 ... % lane_utility_model [60-69]
%                   10 19 -2.3400 -4.5084 -2.8257 -1.2597 -0.7239 -0.3269 ... % lane_utility_model [70-77]
%                   0.2 -0.231 -2.700 1.112 0.5 0.000 0.2 0.742 0.6 ... % critical_gaps_param [78 - 86]
%                   -0.837 0.913 0.816 -1.218 -2.393 -1.662 ... % Target_Gap_Model [87-92]
%                   1.0 0.5 0.6 0.1 0.5 1.0 30.0 100.0 600.0 40.0 ... % nosing_param [93-102]
%                   0.5 ... % CF_CRITICAL_TIMER_RATIO [103]
%                   0.3 ... % intersection_attentiveness_factor_min [104]
%                   0.6 ... % intersection_attentiveness_factor_max [105]
%                   1.25 ... % minimum_gap [106]
%                   1.0 0.5 ... % critical gap addon [107-108]
%                   0.2 ... %  minimum_gap [109]
%                   7 ... % LC Discretionary_Lane_Change_Model_Same [110]
%                   15]; % LC Discretionary_Lane_Change_Model_Diff [111]
                                
    step_db = initial_db*0.001; % 
    %up_db = initial_db+abs(initial_db)*0.05;
    %lb_db = initial_db-abs(initial_db)*0.05;
        
    boundary = 0.1;
    up_db = [6.0 ... % min_response_distance [0]
        0.045+0.045*boundary 0.9 0.205+0.205*boundary 0.8 0.65 ... % CF_parameters_1 [1-5]: alpha beta gama lambda rho	: 0.045 0.9 -0.125 0.8 0.65 
        -0.02 0.000 0.650+0.650*boundary 1.00 0.95 ... % CF_parameters_2 [6-10] -0.02 0.000 -0.05 1.00 0.95 
        0.45 ... % FF_Acc_Params_b2 [11]
        1.3+1.3*boundary ... % speed_factor [12]
        0.75  0.6   0.6   0.10   0.35  0.75  -0.40  -0.2   0.10   0.170+0.170*boundary 2.0   0.20  0.45 ... % target_gap_acc_parm [13-25]
        6.0+6.0*boundary 5.50+5.50*boundary 5.0+5.0*boundary 4.50+4.50*boundary 4.00+4.00*boundary ... % max_acc_car1 [26-30]
        -2.5+2.5*boundary -2.25+2.25*boundary -2.00+2.00*boundary -1.75+1.75*boundary -1.50+1.50*boundary ... % normal_deceleration_car1 [31-35]
        -9.00+9.00*boundary -8.50+8.50*boundary -8.00+8.00*boundary -7.50+7.50*boundary -7.00+7.00*boundary ... % max_deceleration_car1 [36-40]
        1.0+1.0*boundary ... % hbuffer_lower [41]
        1.850875+1.850875*boundary 2.109445+2.109445*boundary 2.263295+2.263295*boundary 2.386205+2.386205*boundary 2.496535+2.496535*boundary 2.60338+2.60338*boundary 2.71371+2.71371*boundary 2.83662+2.83662*boundary 2.99047+2.99047*boundary 3.24904+3.24904*boundary ... % hbuffer_upper [42-51]
        1.0+1.0*boundary ... % yellow_stop_headway [52]
        2.2352+2.2352*boundary ... % min_speed_yellow [53]
        150.0+150.0*boundary ... % driver_signal_perception_distance [54]
        0.4+0.4*boundary ... % dec_update_step_size or stopped_vehicle_update_step_size [55]     
        0.5+0.5*boundary ... % acc_update_step_size or uniform_speed_update_step_size [56]
        1000 1200.0 2.0 ... % MLC_PARAMETERS [57-59]
        6.0    0.3213+0.3213*boundary    -0.75   0.0    0.1  -0.5 0.01  -0.15    -0.002  -1.75    15.0 23.0 -1.0  -2.5    -1.25   -0.75   -0.5    -0.15 ... % lane_utility_model [60-69] % lane_utility_model [70-77]
        2.0 -0.1   -1.5   1.75  2.5 0.00  0.7 1.0   6.0 ... % critical_gaps_param [78 - 86]
        -0.837+0.837*boundary 0.913+0.913*boundary 0.816+0.816*boundary -1.218+1.218*boundary -2.393+2.393*boundary -1.662+1.662*boundary ... % Target_Gap_Model [87-92]
        1.0+1.0*boundary 0.5+0.5*boundary 0.6+0.6*boundary 0.1+0.1*boundary 0.5+0.5*boundary 1.0+1.0*boundary 30.0+30.0*boundary 100.0+100.0*boundary 600.0+600.0*boundary 40.0+40.0*boundary ... % nosing_param [93-102]        
        0.5+0.5*boundary ... % CF_CRITICAL_TIMER_RATIO [103]
        0.3+0.3*boundary ... % intersection_attentiveness_factor_min [104]
        0.6+0.6*boundary ... % intersection_attentiveness_factor_max [105]
        1.25+1.25*boundary ... % minimum_gap [106]
        1.0+1.0*boundary 0.5+0.5*boundary ... % critical gap addon [107-108]
        0.2+0.2*boundary ... %  minimum_gap [109]
        7+7*boundary ... % LC Discretionary_Lane_Change_Model_Same [110]
        15+15*boundary]; % LC Discretionary_Lane_Change_Model_Diff [111]
              
lb_db = [2.0 ... % min_response_distance [0]
        0.015 0.1 0.205-0.205*0.1 0.4 0.45 ... % CF_parameters_1 [1-5]: 0.015 0.1 -0.300 0.4 0.45 
        -0.95 0.000 -0.75 0.05 0.5 ... % CF_parameters_2 [6-10]
        0.05 ... % FF_Acc_Params_b2 [11]
        1.3-1.3*0.1   ... % speed_factor [12]
        0.50  0.2   0.1   0.03   0.10  0.25  -0.75  -0.5   0.05   0.170-0.170*0.1 0.8 0.05 0.15... % target_gap_acc_parm [13-25]
        6.0-6.0*boundary 5.50-5.50*boundary 5.0-5.0*boundary 4.50-4.50*boundary 4.00-4.00*boundary ... % max_acc_car1 [26-30]
        -2.5-2.5*boundary -2.25-2.25*boundary -2.00-2.00*boundary -1.75-1.75*boundary -1.50-1.50*boundary ... % normal_deceleration_car1 [31-35]
        -9.00-9.00*boundary -8.50-8.50*boundary -8.00-8.00*boundary -7.50-7.50*boundary -7.00-7.00*boundary ... % max_deceleration_car1 [36-40]
        1.0-1.0*boundary ... % hbuffer_lower [41]
        1.850875-1.850875*boundary 2.109445-2.109445*boundary 2.263295-2.263295*boundary 2.386205-2.386205*boundary 2.496535-2.496535*boundary 2.60338-2.60338*boundary 2.71371-2.71371*boundary 2.83662-2.83662*boundary 2.99047-2.99047*boundary 3.24904-3.24904*boundary ... % hbuffer_upper [42-51]
        1.0-1.0*boundary ... % yellow_stop_headway [52]
        2.2352-2.2352*boundary ... % min_speed_yellow [53]
        150.0-150.0*boundary ... % driver_signal_perception_distance [54]
        0.4-0.4*boundary ... % dec_update_step_size or stopped_vehicle_update_step_size [55]     
        0.5-0.5*boundary ... % acc_update_step_size or uniform_speed_update_step_size [56]
        75.0 500.0 2.0 ... % MLC_PARAMETERS [57-59]
        2.0    0.3213-0.3213*boundary   -1.50  0.0   0.03 -1.5 0.002 -0.35    -0.015  -5.50    5.0 15.0 -3.5   -6.5    -3.75   -2.00   -1.0    -0.5 ... % lane_utility_model [60-69] % lane_utility_model [70-77]
        0.1 -0.35  -4.0   0.75  0.2 -0.15 0.15 0.5   0.0 ... % critical_gaps_param [78 - 86]
        -0.837-0.837*boundary 0.913-0.913*boundary 0.816-0.816*boundary -1.218-1.218*boundary -2.393-2.393*boundary -1.662-1.662*boundary ... % Target_Gap_Model [87-92]
        1.0-1.0*boundary 0.5-0.5*boundary 0.6-0.6*boundary 0.1-0.1*boundary 0.5-0.5*boundary 1.0-1.0*boundary 30.0-30.0*boundary 100.0-100.0*boundary 600.0-600.0*boundary 40.0-40.0*boundary ... % nosing_param [93-102]
        0.5-0.5*boundary ... % CF_CRITICAL_TIMER_RATIO [103]
        0.3-0.3*boundary ... % intersection_attentiveness_factor_min [104]
        0.6-0.6*boundary ... % intersection_attentiveness_factor_max [105]
        1.25-1.25*boundary ... % minimum_gap [106]
        1.0-1.0*boundary 0.5-0.5*boundary ... % critical gap addon [107-108]
        0.2-0.2*boundary ... %  minimum_gap [109]
        7-7*boundary ... % LC Discretionary_Lane_Change_Model_Same [110]
        15-15*boundary]; % LC Discretionary_Lane_Change_Model_Diff [111]
    
    % RC
    initial_rc = [5.0 -0.01373 1 -0.001025 0.000052 0 0.5 0.879 0.325 0.256 0.422];
    step_rc = initial_rc*0.001; % 
    up_rc = initial_rc+initial_rc*boundary;
    lb_rc = initial_rc-initial_rc*boundary;

% Integrating with OD, RC, DB
    perturb_style = [0; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1]; 
    ratio_nonratio = [0; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1]; 

    perturb_step_init = [3, step_db, step_rc]';
    upperb = [100, up_db, up_rc]';
    lowerb = [0, lb_db, lb_rc]';    

    num_det = 0;

    start_time = 6; % Including warm up time
    end_time = 7; % Including warm up time

    od_interval= 15;
    sensor_interval = 5;
           
% Additions: For gradient based update
    Update_Type = 1; % 0 - Shifted | 1 - gradient 
    alpha				= 0.602;
    %a = 20 ; % Vaze 2009: 15 or 20
    %a					= 0.16*5; % Originally 0.16; %Simon: Larger a may enhance performance in the later iterations by producing a larger step size when the effect of A is small;
    %A					= 80; %Simon: Stability constant is effective in allowing for a more aggressive; Much less than the max number of iterations 
    %c=1.9; gamma = 0.101;
    %sf_k = 1;
    % a_k = a / (A + k^(sf_k) + 1)^alpha ; %a_k = a / (A + k + 1)^alpha ;      

    wind = 100; % How many comparison before and after? 20? 
    wind_buffer = 100; % Activation of comparison. After 2*wind+10?
    termi_buffer = 10; % How many iteration after convert to SPSA? 20?
    ITERATION_SWITCH_ORIGINAL = 1000; 
    ITERATION_SWITCH = 1000; %10*A; % Simon: After 20, we search with normal SPSA. 
    n = 1000; % round(ITERATION_SWITCH*(1.2)); % Simon: Number of iteration of W-SPSA calibration

    free_flow_interval = 0; 
    warm_up = 0; 
    iterations = 1; %%%%% number of run for simulation with same setting
    
