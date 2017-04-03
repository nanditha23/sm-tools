import numpy as np
import os
import math
from calibration import configure, ScreenLineCountVector, PTStopStatsVector, TravelTimeVector
from shutil import copyfile
import re
import time
import commands
from threading import Thread, Lock
import Queue
import csv


#Number of iterations should be passed as i/p argument
mt_calibration = configure.MTCalibration(2)

mutex = Lock()

CWD = os.getcwd()
PLUS_PERTURB_DIR = "PLUS_PERTURB/SimMobility/"
PLUS_PERTURB_INPUT = "qsub jobscript_mt.sh"

MINUS_PERTURB_DIR = "MINUS_PERTURB/SimMobility/"
MINUS_PERTURB_INPUT = "qsub jobscript_mt.sh"

GRADIENT_RUN_DIR = "GRADIENT_RUN/SimMobility/"
GRADIENT_RUN_INPUT = "qsub jobscript_mt.sh"

GRADIENT_RUN_DIR2 = "GRADIENT_RUN_2/SimMobility/"
GRADIENT_RUN_INPUT2 = "qsub jobscript_mt.sh"

JOB_NAME = "calibration"

best_obj_value = -1
best_parameter_list = []
obj_func_val_list = []
NORMALIZE_OBJ = True
NORMALIZE_VAR = True
OBJ_FACTOR = [0.5, 0.2, 0.1, 0.1, 0.1] # Factors to account for different number of sensors for each measurement type
factor = OBJ_FACTOR

def rmsn(sim_vector, real_vector):
    #try:
    return math.sqrt(np.sum(np.square(real_vector - sim_vector)) * len(real_vector)) / np.sum(real_vector)
    #except ZeroDivisionError:
    #    return 1


def wait_for_file_creation(filename):
    while not os.path.isfile(filename):
        time.sleep(2)


def wait_till_job_completes(last_line, console_file):
    print console_file
    while True:
        stdin, stdout = os.popen2("tail -n 1 " + console_file)
        lines = stdout.readlines()
        num_lines = len(lines)
        stdin.close()
        if num_lines == 1:
            if lines[0] == last_line + "\n":
                break
        time.sleep(5)


def run_simmobility_medium(queue_thread, job_script, job_dir, output_name):
    mutex.acquire()
    os.chdir(job_dir)
    out1=re.findall(r'\d+', commands.getoutput(job_script))
    os.chdir("../..")
    mutex.release()
    job_id = out1[0]
    console_file = CWD + "/" + job_dir + JOB_NAME + ".o" + job_id

    print console_file

    wait_for_file_creation(console_file)
    print "file created"
    lines_to_be_printed = "Simulation Done."
    wait_till_job_completes(lines_to_be_printed, console_file)
    print "job completed"
    screen_line_file = job_dir + "screenLineCount.txt"
    # screen_line_file_copy = job_dir + output_name + "_screenLineCount.txt"
    # copyfile(screen_line_file, screen_line_file_copy)

    travel_time_file = job_dir + "subtrip_metrics.csv"
    # travel_time_file_copy = job_dir + output_name + "_subtrip_level_travel_metrics.csv"
    # copyfile(travel_time_file, travel_time_file_copy)

    pt_stop_stats_file = job_dir + "ptstopstats.csv"
    # pt_stop_stats_copy = job_dir + output_name + "_ptstopstats.csv"
    # copyfile(pt_stop_stats_file, pt_stop_stats_copy)

    screen_line = ScreenLineCountVector.generate_screen_line_vector(screen_line_file,
                                                                       mt_calibration.start_time,
                                                                       mt_calibration.end_time)

    travel_time = TravelTimeVector.generate_travel_time_vector(travel_time_file,
                                                               mt_calibration.start_time,
                                                               mt_calibration.end_time)

    boarding_info = PTStopStatsVector.generate_boarding_info_vector(pt_stop_stats_file,
                                                                    mt_calibration.start_time,
                                                                    mt_calibration.end_time)

    alighting_info = PTStopStatsVector.generate_alighting_info_vector(pt_stop_stats_file,
                                                                      mt_calibration.start_time,
                                                                      mt_calibration.end_time)


    vector_list = list()
    vector_list.append(screen_line)
    vector_list.append(travel_time)
    vector_list.append(boarding_info)
    vector_list.append(alighting_info)
    print "screenline count: ", len(screen_line[0])
    print "traveltime count: ", len(travel_time[0])
    print "ptstop boarding count: ", len(boarding_info[0])
    print "ptstop alighting count: ", len(alighting_info[0])
    queue_thread.put(vector_list)

    # removing the files after each iteration. Added by Nishant 13 Feb, 2017
    out_files = job_dir + "out*"
    activity_sch = job_dir + "activity_schedule*"
    deleteCommand = 'rm %s %s %s %s %s' % (screen_line_file, travel_time_file, pt_stop_stats_file, out_files, activity_sch)
    backupOlderIterations = 'tar -czvf name-of-archive%s %s %s %s %s %s' % (str(job_dir).replace('/','_'),screen_line_file, travel_time_file, pt_stop_stats_file, out_files, activity_sch)
    os.system(backupOlderIterations)
    os.system(deleteCommand)



def calculate_objective_function(screen_line_counts_sim, screen_line_counts_real,
                                 travel_time_sim, travel_time_real,
                                 pt_boarding_stat_sim, pt_boarding_stat_real,
                                 pt_alighting_stat_sim, pt_alighting_stat_real,current_params,apriori_params):

    with open('/home/bala/MT_Calibration/calibration/RESULT/timeProfiling.csv', 'a') as profiling:
        csvwriter = csv.writer(profiling)
        csvwriter.writerow(['Entered the calculate objective function'])
    rmsn_screenline = rmsn(screen_line_counts_sim, screen_line_counts_real)
    print '******** calculate obj func Sum of ttsim and tt real **********'
    print np.sum(travel_time_sim), np.sum(travel_time_real)
    rmsn_traveltime = rmsn(travel_time_sim, travel_time_real)


    rmsn_ptboarding = rmsn(pt_boarding_stat_sim, pt_boarding_stat_real)
    rmsn_ptalighting = rmsn(pt_alighting_stat_sim, pt_alighting_stat_real)
    #rmsn_total = mt_calibration.weights['ScreenLine'] * rmsn_screenline + \
     #            mt_calibration.weights['TravelTime'] * rmsn_traveltime + \
      #           mt_calibration.weights['PT_Boarding'] * rmsn_ptboarding + \
       #          mt_calibration.weights['PT_Alighting'] * rmsn_ptalighting
    rmsn_apriori = rmsn(current_params,apriori_params)
    rmsn_list = list()
    rmsn_list.append(rmsn_screenline)
    rmsn_list.append(rmsn_traveltime)
    rmsn_list.append(rmsn_ptboarding)
    rmsn_list.append(rmsn_ptalighting)
    rmsn_list.append(rmsn_apriori)
    return rmsn_list


def calculate_z_vec_gls(z,flag,factor):
    if flag==0:
    	return np.multiply((z[0]-z[1])**2,factor/z[2])
    else:
    	return np.multiply((z[0]-z[1])**2,factor/z[2])


def calculate_z(z,flag,factor):
    if flag==0:
    	return np.dot((z[0] - z[1]) ** 2, factor/z[2])
    else:
    	return np.dot((z[0] - z[1]) ** 2, factor/z[2])

def wspsa():
    # ===========================================================================================================
    #  Initial Run

    print "Intializing"
    t1 = time.time()
    mt_calibration.calibration_variables.update_variables(0)
    with open('/home/bala/MT_Calibration/calibration/RESULT/timeProfiling.csv', 'a') as profiling:
        csvwriter = csv.writer(profiling)
        csvwriter.writerow(["Initialisation done in ", (time.time() - t1), ' seconds '])

    initial_job_name = "initial"
    initial_run_queue = Queue.Queue()
    initial_run_thread = Thread(target=run_simmobility_medium, args=(initial_run_queue, GRADIENT_RUN_INPUT, GRADIENT_RUN_DIR, initial_job_name, ))
    initial_run_thread.start()

    # ===========================================================================================================
    best_obj_value_list = list()
    best_obj_value = 0
    print mt_calibration.no_of_iterations
    for iteration in range(1, mt_calibration.no_of_iterations):
        print "Iteration: " + repr(iteration)
        # ===========================================================================================================
        # Perturb variables and update SM inputs
        if NORMALIZE_VAR:
            #mt_calibration.calibration_variables.normalize_variables()
            mt_calibration.calibration_variables.perturb_normalized_variables(iteration)	# Perform perturbation on normalized vector
            mt_calibration.calibration_variables.rescale_variables(1)
        else:
            mt_calibration.calibration_variables.perturb_variables()
        #Perturbation
        t1 = time.time()
        mt_calibration.calibration_variables.update_variables(1)

        mt_calibration.calibration_variables.update_variables(2)
        with open('/home/bala/MT_Calibration/calibration/RESULT/timeProfiling.csv', 'a') as profiling:
            csvwriter = csv.writer(profiling)
            csvwriter.writerow(["Minus perturbation done in ", (time.time() - t1), ' seconds '])
        # ===========================================================================================================
        # Run SM for plus/minus perturbation
        plus_job_name = "plus_" + repr(iteration)
        minus_job_name = "minus_" + repr(iteration)
        plus_perturb_queue = Queue.Queue()
        minus_perturb_queue = Queue.Queue()
        plus_perturb_thread = Thread(target=run_simmobility_medium, args=(plus_perturb_queue, PLUS_PERTURB_INPUT, PLUS_PERTURB_DIR, plus_job_name, ))
        t1 = time.time()
        print "start +ve perturb thread"
        plus_perturb_thread.start()
        minus_perturb_thread = Thread(target=run_simmobility_medium, args=(minus_perturb_queue, MINUS_PERTURB_INPUT, MINUS_PERTURB_DIR, minus_job_name, ) )
        print "start -ve perturb thread"
        minus_perturb_thread.start()
        plus_perturb_thread.join()
        with open('/home/bala/MT_Calibration/calibration/RESULT/timeProfiling.csv', 'a') as profiling:
            csvwriter = csv.writer(profiling)
            csvwriter.writerow(["Plus perturbation simulation done in ", (time.time() - t1), ' seconds '])

        minus_perturb_thread.join()
        with open('/home/bala/MT_Calibration/calibration/RESULT/timeProfiling.csv', 'a') as profiling:
            csvwriter = csv.writer(profiling)
            csvwriter.writerow(["Minus perturbation simulation Done in ", (time.time() - t1), ' seconds '])
        # ===========================================================================================================
        # Get Outputs
        t1 = time.time()
        if iteration == 1:

            initial_run_thread.join()

            with open('/home/bala/MT_Calibration/calibration/RESULT/timeProfiling.csv', 'a') as profiling:
                csvwriter = csv.writer(profiling)
                csvwriter.writerow(['initial_run_thread.join() done'])
            initial_vector = initial_run_queue.get()
            with open('/home/bala/MT_Calibration/calibration/RESULT/timeProfiling.csv', 'a') as profiling:
                csvwriter = csv.writer(profiling)
                csvwriter.writerow(['Vector queue.get() done'])
            initial_count_vector = initial_vector[0]
            initial_time_vector = initial_vector[1]
            initial_ptboarding_vector = initial_vector[2]
            initial_ptalighting_vector = initial_vector[3]
            initial_apriori = mt_calibration.calibration_variables.get_gradient_apriori_veclist()
            best_obj_value_list = calculate_objective_function(initial_count_vector[0], initial_count_vector[1],
                                                               initial_time_vector[0],initial_time_vector[1],
                                                               initial_ptboarding_vector[0], initial_ptboarding_vector[1],
                                                               initial_ptalighting_vector[0], initial_ptalighting_vector[1],
                                                               initial_apriori[0],initial_apriori[1])

            best_obj_value = best_obj_value_list[3]

        plus_perturb = plus_perturb_queue.get()
        plus_perturb_count = plus_perturb[0]
        plus_perturb_time = plus_perturb[1]
        plus_perturb_ptboarding = plus_perturb[2]
        plus_perturb_ptalighting = plus_perturb[3]
        minus_perturb = minus_perturb_queue.get()
        minus_perturb_count = minus_perturb[0]
        minus_perturb_time = minus_perturb[1]
        minus_perturb_ptboarding = minus_perturb[2]
        minus_perturb_ptalighting = minus_perturb[3]
        with open('/home/bala/MT_Calibration/calibration/RESULT/timeProfiling.csv', 'a') as profiling:
            csvwriter = csv.writer(profiling)
            csvwriter.writerow(["Get outputs section done in ", (time.time() - t1), ' seconds. This section has the objective function calculation<Confusion>'])
        with open('/home/bala/MT_Calibration/calibration/RESULT/pluscount.csv', 'a') as profiling:
            csvwriter = csv.writer(profiling)
            for item in plus_perturb_count:
                csvwriter.writerow(item)
        with open('/home/bala/MT_Calibration/calibration/RESULT/plusTT.csv', 'a') as profiling:
            csvwriter = csv.writer(profiling)
            for item in plus_perturb_time:
                csvwriter.writerow(item)
        with open('/home/bala/MT_Calibration/calibration/RESULT/plusboarding.csv', 'a') as profiling:
            csvwriter = csv.writer(profiling)
            for item in plus_perturb_ptboarding:
                csvwriter.writerow(item)
        with open('/home/bala/MT_Calibration/calibration/RESULT/plusalighting.csv', 'a') as profiling:
            csvwriter = csv.writer(profiling)
            for item in plus_perturb_ptalighting:
                csvwriter.writerow(item)
        # ===========================================================================================================
        #PARAMETER UPDATE
        t1 = time.time()
        if NORMALIZE_VAR:
            plus_params = np.array(mt_calibration.calibration_variables.get_normalized_plus_variable_vector()).astype(float)
            minus_params = np.array(mt_calibration.calibration_variables.get_normalized_minus_variable_vector()).astype(float)
            params = np.array(mt_calibration.calibration_variables.get_normalized_actual_variable_vector()).astype(float)
        else:
            plus_params = np.array(mt_calibration.calibration_variables.get_plus_variable_vector()).astype(float)
            minus_params = np.array(mt_calibration.calibration_variables.get_minus_variable_vector()).astype(float)
            params = np.array(mt_calibration.calibration_variables.get_actual_variable_vector()).astype(float)

        a_k = mt_calibration.a/(mt_calibration.A + iteration+1)**mt_calibration.alpha
        diff_params = (plus_params - minus_params)


        #Objective function computation
        t1 = time.time()
        plus_apriori = mt_calibration.calibration_variables.get_plus_apriori_veclist()
        minus_apriori = mt_calibration.calibration_variables.get_minus_apriori_veclist()

        z_plus = np.array([])
        z_plus = np.append(z_plus, calculate_z_vec_gls(plus_perturb_count,0,factor[0]))
        z_plus = np.append(z_plus, calculate_z_vec_gls(plus_perturb_time,1,factor[1]))
        z_plus = np.append(z_plus, calculate_z_vec_gls(plus_perturb_ptboarding,0,factor[2]))
        z_plus = np.append(z_plus, calculate_z_vec_gls(plus_perturb_ptalighting,0,factor[3]))
        z_plus = np.append(z_plus, calculate_z_vec_gls(plus_apriori,0,factor[4]))

        z_minus = np.array([])
        z_minus = np.append(z_minus, calculate_z_vec_gls(minus_perturb_count,0,factor[0]))
        z_minus = np.append(z_minus, calculate_z_vec_gls(minus_perturb_time,1,factor[1]))
        z_minus = np.append(z_minus, calculate_z_vec_gls(minus_perturb_ptboarding,0,factor[2]))
        z_minus = np.append(z_minus, calculate_z_vec_gls(minus_perturb_ptalighting,0,factor[3]))
        z_minus = np.append(z_minus, calculate_z_vec_gls(minus_apriori,0,factor[4]))

        # Gradient Computation
        t1 = time.time()
        length_vector = [len(plus_perturb_count[0]),
                         len(plus_perturb_time[0]),
                         len(plus_perturb_ptboarding[0]),
                         len(plus_perturb_ptalighting[0]),
                         len(plus_apriori[0])]
        startTime = time.time()
        gradient = mt_calibration.calibration_variables.compute_gradient(z_plus, z_minus, length_vector, diff_params, startTime)
        gradient_SPSA = float(np.sum(z_plus-z_minus)) / diff_params
        gradient_file = "RESULT/gradient_" + repr(iteration) + ".csv"
        mt_calibration.calibration_variables.save_gradient(gradient, gradient_file)

        # Compute new vectors based on gradient descent
        params = params - (a_k * gradient)
        params_SPSA = params - (a_k * gradient_SPSA)

        t1 = time.time()
        if NORMALIZE_VAR:
            mt_calibration.calibration_variables.update_normalized_gradient_values(params)
            mt_calibration.calibration_variables.update_normalized_gradient_values_SPSA(params_SPSA)
            mt_calibration.calibration_variables.rescale_variables(0)
        else:
            mt_calibration.calibration_variables.update_gradient_values(params)
            mt_calibration.calibration_variables.update_gradient_values_SPSA(params_SPSA)

        mt_calibration.calibration_variables.update_variables(0)
        mt_calibration.calibration_variables.update_variables(3)
        with open('/home/bala/MT_Calibration/calibration/RESULT/timeProfiling.csv', 'a') as profiling:
            csvwriter = csv.writer(profiling)
            csvwriter.writerow(["Normalisation section done in ", (time.time() - t1), ' seconds '])
        # ===========================================================================================================
        # Run SM with updated parameters
        t1 = time.time()
        final_job_name = "gradient_" + repr(iteration)
        final_run_queue = Queue.Queue()
        final_run_thread = Thread(target=run_simmobility_medium, args=(final_run_queue, GRADIENT_RUN_INPUT, GRADIENT_RUN_DIR, final_job_name, ))
        print "Start gradient iteration"
        final_run_thread.start()

        final_job_2_name = "gradient_2_" + repr(iteration)
        final_run_2_queue = Queue.Queue()
        final_run_2_thread = Thread(target=run_simmobility_medium, args=(final_run_2_queue, GRADIENT_RUN_INPUT2, GRADIENT_RUN_DIR2, final_job_2_name, ))
        print "Start gradient 2 iteration"
        final_run_2_thread.start()

        final_run_thread.join()
        final_run_2_thread.join()

        final = final_run_queue.get()
        final_count = final[0]
        final_time = final[1]
        final_ptboarding = final[2]
        final_ptalighting = final[3]

        final_2 = final_run_2_queue.get()
        final_2_count = final_2[0]
        final_2_time = final_2[1]
        final_2_ptboarding = final_2[2]
        final_2_ptalighting = final_2[3]


        final_apriori = mt_calibration.calibration_variables.get_gradient_apriori_veclist()  # W -SPSA computed params
        final_2_apriori = mt_calibration.calibration_variables.get_gradient2_apriori_veclist() # SPSA computed params
        plus_obj = calculate_z(plus_perturb_count,0,factor[0]) + \
                   calculate_z(plus_perturb_time,1,factor[1]) + \
                   calculate_z(plus_perturb_ptboarding,0,factor[2]) + \
                   calculate_z(plus_perturb_ptalighting,0,factor[3]) + \
                   calculate_z(plus_apriori,0,factor[4])

        minus_obj = calculate_z(minus_perturb_count,0,factor[0]) + \
                    calculate_z(minus_perturb_time,1,factor[1]) + \
                    calculate_z(minus_perturb_ptboarding,0,factor[2]) + \
                    calculate_z(minus_perturb_ptalighting,0,factor[3]) + \
                    calculate_z(minus_apriori,0,factor[4])

        final_obj = calculate_z(final_count,0,factor[0]) + \
                    calculate_z(final_time,1,factor[1]) + \
                    calculate_z(final_ptboarding,0,factor[2]) + \
                    calculate_z(final_ptalighting,0,factor[3]) + \
                    calculate_z(final_apriori,0,factor[4])


        final2_obj = calculate_z(final_2_count,0,factor[0]) + \
                    calculate_z(final_2_time,1,factor[1]) + \
                    calculate_z(final_2_ptboarding,0,factor[2]) + \
                    calculate_z(final_2_ptalighting,0,factor[3]) + \
                    calculate_z(final_2_apriori,0,factor[4])

        if plus_obj < minus_obj and plus_obj< final_obj and plus_obj < final2_obj:
            if NORMALIZE_VAR:
                mt_calibration.calibration_variables.update_normalized_gradient_values(plus_params)
                mt_calibration.calibration_variables.rescale_variables(0)
            else:
                mt_calibration.calibration_variables.update_gradient_values(plus_params)
        elif minus_obj < plus_obj and minus_obj< final_obj and minus_obj < final2_obj:
            if NORMALIZE_VAR:
                mt_calibration.calibration_variables.update_normalized_gradient_values(minus_params)
                mt_calibration.calibration_variables.rescale_variables(0)
            else:
                mt_calibration.calibration_variables.update_gradient_values(minus_params)
        elif final2_obj < plus_obj and final2_obj< final_obj and final2_obj < minus_obj:
            if NORMALIZE_VAR:
                mt_calibration.calibration_variables.update_normalized_gradient_values(params_SPSA)
                mt_calibration.calibration_variables.rescale_variables(0)
            else:
                mt_calibration.calibration_variables.update_gradient_values(params_SPSA)


        plus_rmsn_list = calculate_objective_function(plus_perturb_count[0], plus_perturb_count[1],
                                                      plus_perturb_time[0], plus_perturb_time[1],
                                                      plus_perturb_ptboarding[0], plus_perturb_ptboarding[1],
                                                      plus_perturb_ptalighting[0], plus_perturb_ptalighting[1],
                                                      plus_apriori[0],plus_apriori[1])


        minus_rmsn_list = calculate_objective_function(minus_perturb_count[0], minus_perturb_count[1],
                                                       minus_perturb_time[0], minus_perturb_time[1],
                                                       minus_perturb_ptboarding[0], minus_perturb_ptboarding[1],
                                                       minus_perturb_ptalighting[0], minus_perturb_ptalighting[1],
                                                       minus_apriori[0], minus_apriori[1])

        final_rmsn_list = calculate_objective_function(final_count[0], final_count[1],
                                                       final_time[0], final_time[1],
                                                       final_ptboarding[0], final_ptboarding[1],
                                                       final_ptalighting[0], final_ptalighting[1],
                                                       final_apriori[0], final_apriori[1])

        final_2_rmsn_list = calculate_objective_function(final_2_count[0], final_2_count[1],
                                                         final_2_time[0], final_2_time[1],
                                                         final_2_ptboarding[0], final_2_ptboarding[1],
                                                         final_2_ptalighting[0], final_2_ptalighting[1],
                                                         final_2_apriori[0], final_2_apriori[1])

        params_file = 'RESULT/Params_Iter_' + repr(iteration) + '.csv'
        mt_calibration.calibration_variables.save_current_param_values(best_obj_value_list, final_rmsn_list, plus_rmsn_list, minus_rmsn_list, params_file)

        #print "Iteration" + repr(iteration) +  " Results, Final RMSN 1: " + repr(final_rmsn) + "Final RMSN 2: " + repr(final_2_rmsn) + " Plus RMSN: " + repr(plus_rmsn) + " Minus RMSN: " + repr(minus_rmsn)

        # Write all RMSN values of the iteration
        with open("RESULT/rmsn.csv", "a") as fp:
            rmsn_writer = csv.writer(fp)
            rmsn_writer.writerow([iteration,'   Plus   ',

                                  plus_rmsn_list[0], calculate_z(plus_perturb_count,0,factor[0]), plus_rmsn_list[1], calculate_z(plus_perturb_time,1,factor[1]),
                                  plus_rmsn_list[2], calculate_z(plus_perturb_ptboarding,0,factor[2]), plus_rmsn_list[3], calculate_z(plus_perturb_ptalighting,0,factor[3]),
                                  calculate_z(plus_apriori,0,factor[4]), plus_rmsn_list[4],'   Minus    ',

                                  minus_rmsn_list[0], calculate_z(minus_perturb_count,0,factor[0]), minus_rmsn_list[1], calculate_z(minus_perturb_time,1,factor[1]),
                                  minus_rmsn_list[2], calculate_z(minus_perturb_ptboarding,0,factor[2]), minus_rmsn_list[3], calculate_z(minus_perturb_ptalighting,0,factor[3]),
                                  calculate_z(minus_apriori,0,factor[4]), minus_rmsn_list[4],'   Gradient 1     ',

                                  final_rmsn_list[0], calculate_z(final_count,0,factor[0]), final_rmsn_list[1], calculate_z(final_time,1,factor[1]),
                                  final_rmsn_list[2], calculate_z(final_ptboarding,0,factor[2]), final_rmsn_list[3], calculate_z(final_ptalighting,0,factor[3]),
                                  calculate_z(final_apriori,0,factor[4]), final_rmsn_list[4],'   Gradient 2    ',

                                  final_2_rmsn_list[0], calculate_z(final_2_count,0,factor[0]), final_2_rmsn_list[1], calculate_z(final_2_time,1,factor[1]),
                                  final_2_rmsn_list[2], calculate_z(final_2_ptboarding,0,factor[2]), final_2_rmsn_list[3], calculate_z(final_2_ptalighting,0,factor[3]),
                                  calculate_z(final_2_apriori,0,factor[4]), final_2_rmsn_list[4]])

        #if final_rmsn < best_obj_value:
            #best_params_file = 'RESULT/Params_best.csv'
            #mt_calibration.calibration_variables.save_current_param_values(best_obj_value_list, final_rmsn_list, plus_rmsn_list, minus_rmsn_list, best_params_file)
            #best_obj_value = final_rmsn