% SPSA related configuration (At this moment, we calibrate only 10)
    % DB
    initial_db = [0.400 0.045 0.740 -0.400 0.65 0.605 1.3 4.2656 -2.34 -0.3269];
    step_db = initial_db*0.003; % 
    up_db = initial_db+initial_db*0.03;
    lb_db = initial_db-initial_db*0.03;

    % RC
    initial_rc = [1.0 -0.01373 1 -0.001025 0.000052 0 0.5 0.879 0.325 0.256 0.422];
    step_rc = initial_rc*0.003; % 
    up_rc = initial_rc+initial_rc*0.03;
    lb_rc = initial_rc-initial_rc*0.03;

% Integrating with OD, RC, DB
    perturb_style = [0; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1]; 
    ratio_nonratio = [0; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1]; 

    perturb_step_init = [3, step_db, step_rc]';
    upperb = [1000, up_db, up_rc]';
    lowerb = [0, lb_db, lb_rc]';    

    %EvaluationPerturb = 'Option1'; %Simon: Option 1 - Plus and Minus perturbation to New gradient  
    EvaluationPerturb = 'Option2'; %Simon: Option 2 - Opposite direction of original gradient

    num_det = 0;

    start_time = 6; % Including warm up time
    end_time = 7; % Including warm up time

    od_interval= 15;
    sensor_interval = 15;
           
% Additions: For gradient based update
    Update_Type = 1; % 0 - Shifted | 1 - gradient 
    alpha				= 0.602;
    %a = 20 ; % Vaze 2009: 15 or 20
    a					= 0.16; %Simon: Larger a may enhance performance in the later iterations by producing a larger step size when the effect of A is small;
    A					= 80; %Simon: Stability constant is effective in allowing for a more aggressive; Much less than the max number of iterations 
    %c=1.9; gamma = 0.101;
    sf_k = 1;
    % a_k = a / (A + k^(sf_k) + 1)^alpha ; %a_k = a / (A + k + 1)^alpha ;      

    ITERATION_SWITCH = 100; %10*A; % Simon: After 20, we search with normal SPSA. 
    n = 120; %round(ITERATION_SWITCH*(1.2)); % Simon: Number of iteration of W-SPSA calibration

    free_flow_interval = 0; 
    warm_up = 0; 
    iterations = 1; %%%%% number of run for simulation with same setting
    %mop=4; % 1: Only count, 4: Count & Travel time
    %weights = [1.0 0.0];
    
