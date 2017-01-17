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
mt_calibration = configure.MTCalibration(3)

mutex = Lock()

CWD = os.getcwd()
PLUS_PERTURB_DIR = "PLUS_PERTURB/SimMobility/"
PLUS_PERTURB_INPUT = "qsub jobscript_plus_perturb.sh"

MINUS_PERTURB_DIR = "MINUS_PERTURB/SimMobility/"
MINUS_PERTURB_INPUT = "qsub jobscript_minus_perturb.sh"

GRADIENT_RUN_DIR = "GRADIENT_RUN/SimMobility/"
GRADIENT_RUN_INPUT = "qsub jobscript_gradient_run.sh"

GRADIENT_RUN_DIR2 = "GRADIENT_RUN2/SimMobility/"
GRADIENT_RUN_INPUT2 = "qsub jobscript_gradient_run2.sh"

JOB_NAME = "calibration"

best_obj_value = -1
best_parameter_list = []
obj_func_val_list = []
NORMALIZE_OBJ = True
NORMALIZE_VAR = True


def rmsn(sim_vector, real_vector):
    return math.sqrt(np.sum(np.square(real_vector - sim_vector)) * len(real_vector)) / np.sum(real_vector)


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
    '''mutex.acquire()
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
    print "job completed"'''
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

    '''with open("RESULT/run_history.csv", "a") as history_file:
        history_file.write((job_id, job_name))'''
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


def calculate_objective_function(screen_line_counts_sim, screen_line_counts_real,
                                 travel_time_sim, travel_time_real,
                                 pt_boarding_stat_sim, pt_boarding_stat_real,
                                 pt_alighting_stat_sim, pt_alighting_stat_real):
    rmsn_screenline = rmsn(screen_line_counts_sim, screen_line_counts_real)
    rmsn_traveltime = rmsn(travel_time_sim, travel_time_real)
    rmsn_ptboarding = rmsn(pt_boarding_stat_sim, pt_boarding_stat_real)
    rmsn_ptalighting = rmsn(pt_alighting_stat_sim, pt_alighting_stat_real)
    rmsn_total = mt_calibration.weights['ScreenLine'] * rmsn_screenline + \
                 mt_calibration.weights['TravelTime'] * rmsn_traveltime + \
                 mt_calibration.weights['PT_Boarding'] * rmsn_ptboarding + \
                 mt_calibration.weights['PT_Alighting'] * rmsn_ptalighting
    rmsn_list = list()
    rmsn_list.append(rmsn_screenline)
    rmsn_list.append(rmsn_traveltime)
    rmsn_list.append(rmsn_ptboarding)
    rmsn_list.append(rmsn_ptalighting)
    rmsn_list.append(rmsn_total)
    return rmsn_list


def calculate_z_vec_gls(z):
    return np.multiply((z[0]-z[1])**2,z[2])


def calculate_z(z):
    return np.dot((z[0] - z[1]) ** 2, z[2])


def wspsa():
    # ===========================================================================================================
    #  Initial Run
    mt_calibration.calibration_variables.update_variables(0)
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
        mt_calibration.calibration_variables.update_variables(1)
        mt_calibration.calibration_variables.update_variables(2)
        # ===========================================================================================================
		# Run SM for plus/minus perturbation
        plus_job_name = "plus_" + repr(iteration)
        minus_job_name = "minus_" + repr(iteration)
        plus_perturb_queue = Queue.Queue()
        minus_perturb_queue = Queue.Queue()
        plus_perturb_thread = Thread(target=run_simmobility_medium, args=(plus_perturb_queue, PLUS_PERTURB_INPUT, PLUS_PERTURB_DIR, plus_job_name, ))
        print "start +ve perturb thread"
        plus_perturb_thread.start()
        minus_perturb_thread = Thread(target=run_simmobility_medium, args=(minus_perturb_queue, MINUS_PERTURB_INPUT, MINUS_PERTURB_DIR, minus_job_name, ) )
        print "start -ve perturb thread"
        minus_perturb_thread.start()
        plus_perturb_thread.join()
        minus_perturb_thread.join()
        # ===========================================================================================================
        # Get Outputs
        if iteration == 1:
            initial_run_thread.join()
            initial_vector = initial_run_queue.get()
            initial_count_vector = initial_vector[0]
            initial_time_vector = initial_vector[1]
            initial_ptboarding_vector = initial_vector[2]
            initial_ptalighting_vector = initial_vector[3]
            best_obj_value_list = calculate_objective_function(initial_count_vector[0], initial_count_vector[1],
                                                               initial_time_vector[0],initial_time_vector[1],
                                                               initial_ptboarding_vector[0], initial_ptboarding_vector[1],
                                                               initial_ptalighting_vector[0], initial_ptalighting_vector[1])
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
        # ===========================================================================================================
		# PARAMETER UPDATE
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

        # Objective function computation
        plus_apriori = mt_calibration.calibration_variables.get_plus_apriori_veclist()
        minus_apriori = mt_calibration.calibration_variables.get_minus_apriori_veclist()
        '''z_plus = np.append(calculate_z_vec_gls(plus_perturb_count),
                           calculate_z_vec_gls(plus_perturb_time),
                           calculate_z_vec_gls(plus_perturb_ptboarding),
                           calculate_z_vec_gls(plus_perturb_ptalighting),
                           calculate_z_vec_gls(plus_apriori))'''

        z_plus = np.array([])
        z_plus = np.append(z_plus, calculate_z_vec_gls(plus_perturb_count))
        z_plus = np.append(z_plus, calculate_z_vec_gls(plus_perturb_time))
        z_plus = np.append(z_plus, calculate_z_vec_gls(plus_perturb_ptboarding))
        z_plus = np.append(z_plus, calculate_z_vec_gls(plus_perturb_ptalighting))
        z_plus = np.append(z_plus, calculate_z_vec_gls(plus_apriori))

        z_minus = np.array([])
        z_minus = np.append(z_minus, calculate_z_vec_gls(minus_perturb_count))
        z_minus = np.append(z_minus, calculate_z_vec_gls(minus_perturb_time))
        z_minus = np.append(z_minus, calculate_z_vec_gls(minus_perturb_ptboarding))
        z_minus = np.append(z_minus, calculate_z_vec_gls(minus_perturb_ptalighting))
        z_minus = np.append(z_minus, calculate_z_vec_gls(minus_apriori))

        '''z_minus = np.append(calculate_z_vec_gls(minus_perturb_count),
                            calculate_z_vec_gls(minus_perturb_time),
                            calculate_z_vec_gls(minus_perturb_ptboarding),
                            calculate_z_vec_gls(minus_perturb_ptalighting),
                            calculate_z_vec_gls(minus_apriori))'''

        # Gradient Computation
        length_vector = [len(plus_perturb_count[0]),
                         len(plus_perturb_time[0]),
                         len(plus_perturb_ptboarding[0]),
                         len(plus_perturb_ptalighting[0]),
                         len(plus_apriori[0])]
        W = mt_calibration.calibration_variables.generate_weight_matrix(length_vector)
        gradient = np.dot(z_plus-z_minus, W)/diff_params
        gradient_SPSA = float(np.sum(z_plus-z_minus)) / diff_params
        gradient_file = "RESULT/gradient_" + repr(iteration) + ".csv"
        mt_calibration.calibration_variables.save_gradient(gradient, gradient_file)

        # Compute new vectors based on gradient descent
        params = params - (a_k * gradient)
        params_SPSA = params - (a_k * gradient_SPSA)

        if NORMALIZE_VAR:
            mt_calibration.calibration_variables.update_normalized_gradient_values(params)
            mt_calibration.calibration_variables.update_normalized_gradient_values_SPSA(params_SPSA)
            mt_calibration.calibration_variables.rescale_variables(0)
        else:
            mt_calibration.calibration_variables.update_gradient_values(params)
            mt_calibration.calibration_variables.update_gradient_values_SPSA(params_SPSA)

        mt_calibration.calibration_variables.update_variables(0)
        mt_calibration.calibration_variables.update_variables(3)
        # ===========================================================================================================
        # Run SM with updated parameters
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
        plus_obj = calculate_z(plus_perturb_count) + \
                   calculate_z(plus_perturb_time) + \
                   calculate_z(plus_perturb_ptboarding) + \
                   calculate_z(plus_perturb_ptalighting) + \
                   calculate_z(plus_apriori)

        minus_obj = calculate_z(minus_perturb_count) + \
                    calculate_z(minus_perturb_time) + \
                    calculate_z(minus_perturb_ptboarding) + \
                    calculate_z(minus_perturb_ptalighting) + \
                    calculate_z(minus_apriori)

        final_obj = calculate_z(final_count) + \
                    calculate_z(final_time) + \
                    calculate_z(final_ptboarding) + \
                    calculate_z(final_ptalighting) + \
                    calculate_z(final_apriori)


        final2_obj = calculate_z(final_2_count) + \
                    calculate_z(final_2_time) + \
                    calculate_z(final_2_ptboarding) + \
                    calculate_z(final_2_ptalighting) + \
                    calculate_z(final_2_apriori)

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
                                                      plus_perturb_ptalighting[0], plus_perturb_ptalighting[1])
        plus_rmsn = plus_rmsn_list[3]

        minus_rmsn_list = calculate_objective_function(minus_perturb_count[0], minus_perturb_count[1],
                                                       minus_perturb_time[0], minus_perturb_time[1],
                                                       minus_perturb_ptboarding[0], minus_perturb_ptboarding[1],
                                                       minus_perturb_ptalighting[0], minus_perturb_ptalighting[1])
        minus_rmsn = minus_rmsn_list[3]

        final_rmsn_list = calculate_objective_function(final_count[0], final_count[1],
                                                       final_time[0], final_time[1],
                                                       final_ptboarding[0], final_ptboarding[1],
                                                       final_ptalighting[0], final_ptalighting[1])
        final_rmsn = final_rmsn_list[3]

        final_2_rmsn_list = calculate_objective_function(final_2_count[0], final_2_count[1],
                                                         final_2_time[0], final_2_time[1],
                                                         final_2_ptboarding[0], final_2_ptboarding[1],
                                                         final_2_ptalighting[0], final_2_ptalighting[1])
        final_2_rmsn = final_2_rmsn_list[3]

        params_file = 'RESULT/Params_Iter_' + repr(iteration) + '.csv'
        mt_calibration.calibration_variables.save_current_param_values(best_obj_value_list, final_rmsn_list, plus_rmsn_list, minus_rmsn_list, params_file)

        print "Iteration" + repr(iteration) +  " Results, Final RMSN 1: " + repr(final_rmsn) + "Final RMSN 2: " + repr(final_2_rmsn) + " Plus RMSN: " + repr(plus_rmsn) + " Minus RMSN: " + repr(minus_rmsn)

        # Write all RMSN values of the iteration
        with open("RESULT/rmsn.csv", "a") as fp:
            rmsn_writer = csv.writer(fp)
            rmsn_writer.writerow([iteration,

                                  plus_rmsn_list[0], calculate_z(plus_perturb_count), plus_rmsn_list[1], calculate_z(plus_perturb_time),
                                  plus_rmsn_list[2], calculate_z(plus_perturb_ptboarding), plus_rmsn_list[3], calculate_z(plus_perturb_ptalighting),
                                  calculate_z(plus_apriori), plus_rmsn_list[4],

                                  minus_rmsn_list[0], calculate_z(minus_perturb_count), minus_rmsn_list[1], calculate_z(minus_perturb_time),
                                  minus_rmsn_list[2], calculate_z(minus_perturb_ptboarding), minus_rmsn_list[3], calculate_z(minus_perturb_ptalighting),
                                  calculate_z(minus_apriori), minus_rmsn_list[4],

                                  final_rmsn_list[0], calculate_z(final_count), final_rmsn_list[1], calculate_z(final_time),
                                  final_rmsn_list[2], calculate_z(final_ptboarding), final_rmsn_list[3], calculate_z(final_ptalighting),
                                  calculate_z(final_apriori), final_rmsn_list[4],

                                  final_2_rmsn_list[0], calculate_z(final_2_count), final_2_rmsn_list[1], calculate_z(final_2_time),
                                  final_2_rmsn_list[2], calculate_z(final_2_ptboarding), final_2_rmsn_list[3], calculate_z(final_2_ptalighting),
                                  calculate_z(final_2_apriori), final_2_rmsn_list[4]])

        if final_rmsn < best_obj_value:
            best_params_file = 'RESULT/Params_best.csv'
            mt_calibration.calibration_variables.save_current_param_values(best_obj_value_list, final_rmsn_list, plus_rmsn_list, minus_rmsn_list, best_params_file)
            best_obj_value = final_rmsn

        #obj_func_val_list.append(final_obj_val)

	#print obj_func_val_list

# OBSOLETE code


		#weights = np.array(mt_calibration.calibration_variables.get_gradient_weights()).astype(float)
		#denom = weights + (mt_calibration.A + iteration)
		#denom = denom ** mt_calibration.alpha
		#a_k = weights / denom

		# The gradient computation is added by Vishnu

		#New function with weights to compute the gradient
		#numer_SC = ((plus_perturb_count[0] - plus_perturb_count[1]) ** 2) - ((minus_perturb_count[0] - minus_perturb_count[1]) ** 2)
		#numer_SC_sum = sum(numer_SC)
		#numer_SC_weg = np.array(mt_calibration.calibration_variables.get_weights_sc_vector()).astype(float)*numer_SC_sum

		#numer_TT = ((plus_perturb_time[0] - plus_perturb_time[1]) ** 2) - ((minus_perturb_time[0] - minus_perturb_time[1]) ** 2)
		#numer_TT_sum = sum(numer_TT)
		#numer_TT_weg = np.array(mt_calibration.calibration_variables.get_weights_tt_vector()).astype(float)*numer_TT_sum

		#params_sum = numer_SC_weg + numer_TT_weg



# 		numer_SC_p = ((plus_perturb_count[0] - plus_perturb_count[1]) ** 2)
# 		numer_SC_m = ((minus_perturb_count[0] - minus_perturb_count[1]) ** 2)
# 		numer_SC_sum_p = sum(numer_SC_p)
# 		numer_SC_sum_m = sum(numer_SC_m)
# 		numer_SC_weg_p = np.array(mt_calibration.calibration_variables.get_weights_sc_vector()).astype(float)*numer_SC_sum_p
# 		numer_SC_weg_m = np.array(mt_calibration.calibration_variables.get_weights_sc_vector()).astype(float)*numer_SC_sum_m
#
# 		numer_TT_p = ((plus_perturb_time[0] - plus_perturb_time[1]) ** 2)
# 		numer_TT_m = ((minus_perturb_time[0] - minus_perturb_time[1]) ** 2)
# 		numer_TT_sum_p = sum(numer_TT_p)*3600
# 		numer_TT_sum_m = sum(numer_TT_m)*3600
# 		numer_TT_weg_p = np.array(mt_calibration.calibration_variables.get_weights_tt_vector()).astype(float)*numer_TT_sum_p
# 		numer_TT_weg_m = np.array(mt_calibration.calibration_variables.get_weights_tt_vector()).astype(float)*numer_TT_sum_m
#
#         numer_PTS_p = ((plus_perturb_ptstops[0] - plus_perturb_ptstops[1]) ** 2)
#         numer_PTS_m = ((minus_perturb_ptstops[0] - minus_perturb_ptstops[1]) ** 2)
#         numer_PTS_sum_p = sum(numer_PTS_p)
#         numer_PTS_sum_m = sum(numer_PTS_m)
#         numer_PTS_weg_p = np.array(mt_calibration.calibration_variables.get_weights_pts_vector()).astype(float)*numer_PTS_p
#         numer_PTS_weg_m = np.array(mt_calibration.calibration_variables.get_weights_pts_vector()).astype(float)*numer_PTS_m
#
#         params_sum = (0.6*numer_SC_weg_p + 0.2*numer_TT_weg_p + 0.2*numer_PTS_weg_p) - (0.6*numer_SC_weg_m + 0.2*numer_TT_weg_m + 0.2*numer_PTS_weg_m)

# print plus_perturb_count[0]
# 		print plus_perturb_count[1]
# 		print minus_perturb_count[0]
# 		print minus_perturb_count[1]
#
# 		print plus_perturb_time[0]
# 		print plus_perturb_time[1]
# 		print minus_perturb_time[0]
# 		print minus_perturb_time[1]
#
#         print plus_perturb_ptstops[0]
#         print plus_perturb_ptstops[1]
#         print minus_perturb_ptstops[0]
#         print minus_perturb_ptstops[1]
#
# 		print numer_SC_p
# 		print numer_SC_m
# 		print numer_SC_sum_p
# 		print numer_SC_sum_m
# 		print numer_SC_weg_p
# 		print numer_SC_weg_m
#
# 		print numer_TT_p
# 		print numer_TT_m
# 		print numer_TT_sum_p
# 		print numer_TT_sum_m
# 		print numer_TT_weg_p
# 		print numer_TT_weg_m
#
#         print numer_PTS_p
#         print numer_PTS_m
#         print numer_PTS_sum_p
#         print numer_PTS_sum_m
#         print numer_PTS_weg_p
#         print numer_PTS_weg_m
#
# 		print params_sum
# 		print gradient
