import csv
import os
import psycopg2
import re
import collections
import numpy as np
from numpy import random
import time

# ======================================================================================================================
# constants
# Note: Specify database and credentials
CONNECTION_STRING = "dbname='simmobility' user='postgres' host='172.25.184.156' " \
                    "port='5432' password='d84dmiN'"
LUA_FILES_PATH = "SimMobility/scripts/lua/mid/behavior-models/"
PLUS_LUA_FILES_PATH = "PLUS_PERTURB/" + LUA_FILES_PATH
MINUS_LUA_FILES_PATH = "MINUS_PERTURB/" + LUA_FILES_PATH
GRADIENT_LUA_FILES_PATH = "GRADIENT_RUN/" + LUA_FILES_PATH
GRADIENT2_LUA_FILES_PATH = "GRADIENT_RUN_2/" + LUA_FILES_PATH
CONFIG_FILES_PATH = "SimMobility/data/"
PLUS_CONFIG_FILES_PATH = "PLUS_PERTURB/" + CONFIG_FILES_PATH
MINUS_CONFIG_FILES_PATH = "MINUS_PERTURB/" + CONFIG_FILES_PATH
GRADIENT_CONFIG_FILES_PATH = "GRADIENT_RUN/" + CONFIG_FILES_PATH
GRADIENT2_CONFIG_FILES_PATH = "GRADIENT_RUN_2/" + CONFIG_FILES_PATH
# ======================================================================================================================
# Database table names for parameters that are read directly from the database during a simulation run
SEGMENT_TABLE = "supply.segment_calib1_gradient"
SEGMENT_TABLE2 = "supply.segment_calib1_gradient2"
PLUS_PERTURB_SEG_TABLE = "supply.segment_calib1_plus"
MINUS_PERTURN_SEG_TABLE = "supply.segment_calib1_minus"
# ======================================================================================================================
PERTURBATION = [0.1, 0.1, 0.1, 0.1]     # Percentage perturbation for different parameters types (pre-day/traffic/segment_cap/intersection_cap)
GAMMA_SPSA = 0.10                       # See Spall
PERTURBATION_TYPE = 0                   # 0 - percentage perturbation; 1 - fixed perturbation
# ======================================================================================================================
# Function that forces parameters to their bounds if outside the specified range
def clamp(value, lower_bound, upper_bound):
    return max(lower_bound, min(value, upper_bound))
# ======================================================================================================================
# This class manages all the simulation parameters to be calibrated
# In case of the Mid-Term there are four sets of parameters and accordingly, the MidTermVariablesManager
# contains four dictionaries that store various values relating to the calibration process for each parameter
# 1) lua_variables: key - tuple consisting of lua filename and variable name; value: list of 20 items defined below
#    These are selected pre-day parameters
# 2) supply_variables: key - link category (integer from 1 to 7) ; value: list of 33 items defined below
#    These are the alpha, beta values of the speed-density relationship for each link category
# 3) db_variables: key - ID with values from C1 to C168; value - list of 21 items defined below
#    These are capacities for mid-block segments which are divided into 168 categories depending on free flow speed,
#    link category and number of lanes;
# 4) segcap_variables: key - segment ID ; value - list of 19 items defined below
#    These are capcacities of segments at intersections
#-----------------------------------------------------------------------------------------------------------------------
class MidTermVariablesManager:
    lua_variables = collections.OrderedDict()
    #pvtrc_variables = collections.OrderedDict()
    supply_variables = collections.OrderedDict()
    db_variables = collections.OrderedDict()
    segcap_variables = collections.OrderedDict()
    perturbation_rate = []
    db_table_name = ""
    connection_string = ""
    lua_path = ""
    config_files_path = ""
    def __init__(self):
        self.db_table_name = SEGMENT_TABLE
        self.connection_string = CONNECTION_STRING
        self.lua_path = LUA_FILES_PATH
        self.config_files_path = CONFIG_FILES_PATH
        self.perturbation_rate = PERTURBATION
        self.gamma_spsa = GAMMA_SPSA
        self.perturbation_type = PERTURBATION_TYPE
    # ======================================================================================================================
    # reads variables to be calibrated from input files
    def read_variables(self):
        with open('data/lua_variables.csv', 'r') as luaVarsFile:
            # The lua_variables.csv file should contain the following columns:
            # -------------------------------------------------------------------------------------------------------------------------
            # 0: Lua file name | 1: Variable name | 2: Seed value of parameter | 3:Min value of parameter | 4: Max value of parameter |
            # 5: perturbation_step [UNUSED] | 6: Weight for gradient [UNUSED] | 7: W-spsa Weight for screenline counts | 8: W-spsa Weight for TTs |
            # 9: W-spsa Weight for PT boardings/alightings | 10: Apriori Parameter estimate | 11: Variance of apriori estimate
            # -------------------------------------------------------------------------------------------------------------------------
            lua_reader = csv.reader(luaVarsFile)
            lua_param_list = list(lua_reader)
            # Each item in the lua_variables dictionary contains the following list of values:
            # lua_variables[filename,varname] = [filename [0] , varname [1] , initialval [2], minval [3], maxval [4], perturb_step [5],
            # currentval [6], +ve_perturb [7], -ve_perturb [8], weight_for_gradient [9], weight_for_sc [10], weight_for_TT [11],
            # weight for EZ_link [12],  apriori_value [13], normalized_current_val [14], normalized_+ve_perturb [15], normalized_-ve_perturb [16]
            # , apriori_weight [17], normalized_apriori_value[18], currentval2 [19], normalized_current_val2 [20] ]
            for item in lua_param_list:

                norm_val = (float(item[2])-float(item[3]))/(float(item[4])-float(item[3]))
                norm_apriori = (float(item[10])-float(item[3]))/(float(item[4])-float(item[3]))
                # Define the dictionary item for the current lua (pre-day) parameter
                self.lua_variables[(item[0], item[1])] = list([item[0], item[1], float(item[2]), float(item[3]), float(item[4]),
                                                        float(item[5]), float(item[2]), float(item[2]), float(item[2]),
                                                         float(item[6]), float(item[7]), float(item[8]), float(item[9]),
                                                         float(item[10]), norm_val, norm_val, norm_val, float(item[11]), norm_apriori, float(item[2]),norm_val])
        with open('data/supply_variables.csv', 'r') as supplyVarsFile:
            # The supply_variables.csv file should contain the following columns:
            # -------------------------------------------------------------------------------------------------------------------------
            # 0: Midterm congifuration file name | 1: Link Category | 2:String 'Beta'  | 3: Seed value of Beta parameter | 4: Min value of parameter |
            # 5: Max value of parameter | 6: perturbation_step [UNUSED] | 7: Weight for gradient [UNUSED] | 8: W-spsa Weight for screenline counts |
            # 9: W-spsa Weight for TTs | 10: W-spsa Weight for PT boardings/alightings | 11: Apriori Beta Parameter estimate | 12: Apriori Alpha Parameter estimate |
            # 13: Variance of apriori estimate
            # -------------------------------------------------------------------------------------------------------------------------
            supply_reader = csv.reader(supplyVarsFile)
            param_list = list(supply_reader)
            # Each item in the supply_variables dictionary contains the following list of values:
            # supply_variables[id] = [filename [0], linkcat [1], beta_initialval [2], beta_minval [3], beta_maxval [4], beta_currentval [5],
            # +ve_perturb_beta [6], -ve_perturb_beta [7], alpha_initialval [8], alpha_minval [9], alpha_maxval [10],
            # alpha_currentval [11], +ve_perturb_alpha [12], -ve_perturb_alpha [13], perturb_step [14], weight_for_gradient [15],
            # weight_for_sc [16], weight_for_TT weight [17], for EZ_link [18], apriori_value_beta [19], apriori_value_alpha [20],
            # norm_beta_cur [21], norm_beta_+ [22], norm_beta_-[23], norm_alpha_cur[24], norm_alpha_+ [25], norm_alpha_- [26]
            # , apriori_weight [27], normalized_apriori_value_beta[28], normalized_apriori_value_alpha[29]
            # , beta_currentval2 [30], norm_beta_cur2 [31], alpha_currentval2 [32], norm_alpha_cur2 [33]]
            for item in param_list:
                norm_val_alpha = (float(item[7])-float(item[8]))/(float(item[9])-float(item[8]))
                norm_val_beta =  (float(item[3])-float(item[4]))/(float(item[5])-float(item[4]))
                norm_apriori_alpha = (float(item[13])-float(item[8]))/(float(item[9])-float(item[8]))
                norm_apriori_beta =(float(item[12])-float(item[4]))/(float(item[5])-float(item[4]))
                self.supply_variables[item[1]] = list([item[0], item[1], float(item[3]), float(item[4]), float(item[5]), float(item[3]),
                                                  float(item[3]), float(item[3]), float(item[7]), float(item[8]), float(item[9]),
                                                  float(item[7]), float(item[7]), float(item[7]), float(item[10]), float(item[11]), float(item[12]), float(item[13]), float(item[14]), float(item[15]), float(item[16]),
                                                  norm_val_beta, norm_val_beta, norm_val_beta, norm_val_alpha, norm_val_alpha, norm_val_alpha,
                                                  float(item[17]), norm_apriori_beta, norm_apriori_alpha, float(item[3]),norm_val_beta, float(item[7]), norm_val_alpha ])

        with open('data/db_variables.csv', 'r') as dbVarsFile:
            # The db_variables.csv file should contain the following columns:
            # -------------------------------------------------------------------------------------------------------------------------
            # 0: String 'Capacity' | 1: Link Category | 2: Number of lanes | 3:Free Flow Speed | 4: Segment Category (C1-C168) |
            # 5: Seed value of capacity (per lane) | 6: Min value of capacity (per lane) | 7: Max value of capacity (per lane)
            # 8: perturbation_step [UNUSED] | 9: Weight for gradient [UNUSED] | 10: W-spsa Weight for screenline counts | 11: W-spsa Weight for TTs |
            # 12: W-spsa Weight for PT boardings/alightings | 13: Apriori Parameter estimate | 14: Variance of apriori estimate
            # -------------------------------------------------------------------------------------------------------------------------
            dbvar_reader = csv.reader(dbVarsFile)
            db_param_list = list(dbvar_reader)
            # db_variables[capacityid] = [linkcat [0], numlanes [1], speed [2], initialval [3], minval [4], maxval [5],
            #  perturb_step [6], currentval [7], +ve_perturb [8], -ve_perturb [9], weight_for_gradient [10], weight_for_sc [11],
            # weight_for_TT [12], weight for EZ_link [13], apriori_value [14], norm_cur [15], norm_+ [16], norm_-[17],
            # apriori_weight [18], normalized_apriori_value [19], currentval2 [20], norm_cur2 [21]]
            for item in db_param_list:

                norm_cap = (float(item[5])-float(item[6]))/(float(item[7])-float(item[6]))
                norm_apriori = (float(item[13])-float(item[6]))/(float(item[7])-float(item[6]))
                self.db_variables[item[4]] = list([item[1], item[2], item[3], float(item[5]), float(item[6]), float(item[7]), float(item[8]),
                                  float(item[5]), float(item[5]), float(item[5]), float(item[9]), float(item[10]), float(item[11]),
                                  float(item[12]), float(item[13]), norm_cap, norm_cap, norm_cap, float(item[14]), norm_apriori,float(item[5]),norm_cap])

        with open('data/intersection_seg_capacities.csv', 'r') as segCapFile:
            # The intersection_seg_capacities.csv file should contain the following columns:
            # -------------------------------------------------------------------------------------------------------------------------
            # 0: Segment ID | 1: Seed value of capacity (per lane) | 2: Min value of capacity (per lane) | 3: Max value of capacity (per lane)
            # 4: perturbation_step [UNUSED] | 5: Weight for gradient [UNUSED] | 6: W-spsa Weight for screenline counts | 7: W-spsa Weight for TTs |
            # 8: W-spsa Weight for PT boardings/alightings | 9: Apriori Parameter estimate | 10: Variance of apriori estimate
            # -------------------------------------------------------------------------------------------------------------------------
            segcap_reader = csv.reader(segCapFile)
            segcap_param_list = list(segcap_reader) #list of seg_id,capacity,lower bound,upper bound,c,a,w1,w2
            for item in segcap_param_list:
                # segcap_variables[segment_id] = [segment_id [0], initialval [1], minval [2], maxval [3], perturb_step [4],
                #    currentval [5], +ve_perturb [6], -ve_perturb [7], weight_for_gradient [8], weight_for_sc [9], weight_for_TT [10],
                #    weight for EZ_link [11], apriori_value [12], norm_cur [13], norm_+ [14], norm_- [15],
                #    apriori_weight [16], normalized_apriori_value [17], currentval2 [18], norm_cur2 [19] ]
                norm_seg_cap = (float(item[1])-float(item[2]))/(float(item[3])-float(item[2]))
                norm_apriori = (float(item[9])-float(item[2]))/(float(item[3])-float(item[2]))
                self.segcap_variables[item[0]] = list([item[0], float(item[1]), float(item[2]), float(item[3]), float(item[4]),
                                                float(item[1]), float(item[1]), float(item[1]), float(item[5]), float(item[6]), float(item[7]),
                                                float(item[8]), float(item[9]), norm_seg_cap, norm_seg_cap, norm_seg_cap, float(item[10]), norm_apriori,
                                                       float(item[1]), norm_seg_cap])

    # ======================================================================================================================
    # Rescale normalized variables
    # This function rescales all the normalized parameters to their original range in order to run the Simulation
    # If the argument 'type' is set to 0, the normalized parameters for the plus and minus perturbation are rescaled
    # If the argument 'type' is set to 1, the normalized parameters for the SPSA-gradient and WSPSA-gradient based parameters are rescaled
    def rescale_variables(self, type):
        for key, value in self.lua_variables.items():
            if type == 0:
                value[6] = value[3] + value[14]*(value[4]-value[3])     # Rescale current value
                value[19] = value[3] + value[20]*(value[4]-value[3])    # Rescale current value 2
            elif type == 1:
                value[7] = value[3] + value[15]*(value[4]-value[3])     # Rescale +ve perturb
                value[8] = value[3] + value[16]*(value[4]-value[3])     # Rescale -ve perturb
        for key, value in self.supply_variables.items():
            if type == 0:
                value[5] = value[3] + value[21]*(value[4]-value[3])     # Rescale current value (beta)
                value[11] = value[9] + value[24]*(value[10]-value[9])     # Rescale current value (alpha)
                value[27] = value[3] + value[28]*(value[4]-value[3])     # Rescale current value (beta) 2
                value[29] = value[9] + value[30]*(value[10]-value[9])     # Rescale current value (alpha) 2
            elif type == 1:
                value[6] = value[3] + value[22]*(value[4]-value[3])     # Rescale +ve perturb (beta)
                value[12] = value[9] + value[23]*(value[10]-value[9])     # Rescale +ve perturb (alpha)
                value[7] = value[3] + value[25]*(value[4]-value[3])     # Rescale -ve perturb (beta)
                value[13] = value[9] + value[26]*(value[10]-value[9])     # Rescale -ve perturb (beta)
        for key, value in self.db_variables.items():
            if type == 0:
                value[7] = value[4] + value[15]*(value[5]-value[4])     # Rescale current value
                value[20] = value[4] + value[21]*(value[5]-value[4])     # Rescale current value 2
            elif type == 1:
                value[8] = value[4] + value[16]*(value[5]-value[4])     # Rescale +ve perturb
                value[9] = value[4] + value[17]*(value[5]-value[4])     # Rescale -ve perturb
        for key, value in self.segcap_variables.items():
            if type == 0:
                value[5] = value[2] + value[13]*(value[3]-value[2])     # Rescale current value
                value[18] = value[2] + value[19]*(value[3]-value[2])     # Rescale current value 2
            elif type == 1:
                value[6] = value[2] + value[14]*(value[3]-value[2])     # Rescale +ve perturb
                value[7] = value[2] + value[15]*(value[3]-value[2])     # Rescale -ve perturb

    # ======================================================================================================================
    # This function performs the plus and minus perturbation of the normalized parameters
    # The perturbation amount is a function of the perturbation rate, iteration number and gamma parameter as per Spall
    def perturb_normalized_variables(self, iteration):
        np.random.seed()
        c = np.array(self.perturbation_rate)/(iteration+1)**self.gamma_spsa
        epsilon = 0.01
        # --------------------- Perturbation of pre day parameters ---------------------------------
        for key, value in self.lua_variables.items():
            #Added Vishnu
            rand_1 = np.random.binomial(1, 0.5, 1)
            if rand_1 == 1:
                  rand_num = 1
            else:
                  rand_num = -1
            if self.perturbation_type == 0:
                if abs(value[14]) > epsilon:
                    value[15] = clamp(value[14] + rand_num*c[0]*value[14], 0, 1)
                    value[16] = clamp(value[14] - rand_num*c[0]*value[14], 0, 1)
                else:
                    value[15] = clamp(value[14] + rand_num*c[0], 0, 1)
                    value[16] = clamp(value[14] - rand_num*c[0], 0, 1)
            else:
                value[15] = clamp(value[14] + rand_num*c[0], 0, 1)
                value[16] = clamp(value[14] - rand_num*c[0], 0, 1)
        # ------------------- Perturbation of supply variables (alpha,beta parameters) -------------
        for key, value in self.supply_variables.items():
            rand_1 = np.random.binomial(1,0.5,1)
            if rand_1 == 1:
                  rand_num = 1
            else:
                  rand_num = -1
            if self.perturbation_type == 0:
                if abs(value[21])>epsilon:
                    value[22] = clamp(value[21] + rand_num*c[1]*value[21], 0, 1)
                    value[23] = clamp(value[21] - rand_num*c[1]*value[21], 0, 1)
                else:
                    value[22] = clamp(value[21] + rand_num*c[1], 0, 1)
                    value[23] = clamp(value[21] - rand_num*c[1], 0, 1)
            else:
                value[22] = clamp(value[21] + rand_num*c[1], 0, 1)
                value[23] = clamp(value[21] - rand_num*c[1], 0, 1)

            if self.perturbation_type == 0:
                if abs(value[24])>epsilon:
                    value[25] = clamp(value[24] + rand_num*c[1]*value[24], 0, 1)
                    value[26] = clamp(value[24] - rand_num*c[1]*value[24], 0, 1)
                else:
                    value[25] = clamp(value[24] + rand_num*c[1], 0, 1)
                    value[26] = clamp(value[24] - rand_num*c[1], 0, 1)
            else:
                value[25] = clamp(value[24] + rand_num*c[1], 0, 1)
                value[26] = clamp(value[24] - rand_num*c[1], 0, 1)
        # -------------------- Perturbation of db variables (mid-block capacities) -----------------------
        for key, value in self.db_variables.items():
            rand_1 = np.random.binomial(1,0.5,1)
            if rand_1 == 1:
                  rand_num = 1
            else:
                  rand_num = -1
            if self.perturbation_type == 0:
                if abs(value[15])>epsilon:
                    value[16] = clamp(value[15] + rand_num*c[2]*value[15], 0, 1)
                    value[17] = clamp(value[15] - rand_num*c[2]*value[15], 0, 1)
                else:
                    value[16] = clamp(value[15] + rand_num*c[2], 0, 1)
                    value[17] = clamp(value[15] - rand_num*c[2], 0, 1)
            else:
                value[16] = clamp(value[15] + rand_num*c[2], 0, 1)
                value[17] = clamp(value[15] - rand_num*c[2], 0, 1)
        # -------------------- Perturbation of segcap variables (intersection capacities) -----------------
        for key, value in self.segcap_variables.items():
            rand_1 = np.random.binomial(1,0.5,1)
            if rand_1 == 1:
                    rand_num = 1
            else:
                    rand_num = -1
            if self.perturbation_type == 0:
                if abs(value[13])>epsilon:
                    value[14] = clamp(value[13] + rand_num*c[3]*value[13], 0, 1)
                    value[15] = clamp(value[13] - rand_num*c[3]*value[13], 0, 1)
                else:
                    value[14] = clamp(value[13] + rand_num*c[3], 0, 1)
                    value[15] = clamp(value[13] - rand_num*c[3], 0, 1)
            else:
                value[14] = clamp(value[13] + rand_num*c[3], 0, 1)
                value[15] = clamp(value[13] - rand_num*c[3], 0, 1)

    # ======================================================================================================================
    # Updates the lua/configuration files with respective pre-day/supply parameter values
    # If argument 'type' is 0, the parameters based on WSPSA gradient are updated
    # If argument 'type' is 1, the parameters of the plus perturbation are updated
    # If argument 'type' is 2, the parameters of the minus perturbation are updated
    # If argument 'type' is 3, the parameters based on SPSA gradient are updated
    def update_lua_variables(self, type):
        # ------------------------- LUA Variables Update --------------------------
        for key, value in self.lua_variables.items():
            filename = GRADIENT_LUA_FILES_PATH+value[0]
            if type == 1:
                filename = PLUS_LUA_FILES_PATH+value[0]
            elif type == 2:
                filename = MINUS_LUA_FILES_PATH+value[0]
            elif type == 3:
                filename = GRADIENT2_LUA_FILES_PATH + value[0] # Added: Gradient 2 (Ravi)
            var_name = value[1]
            current_val = value[6]
            if type == 1:
                current_val = value[7]
            elif type == 2:
                current_val = value[8]
            elif type == 3:
                current_val = value[19] # ADDED Gradient 2 (Ravi)
            # Update lua files with relevant parameter values
            sed_command = "sed -i -e 's/local " + var_name + "[ ]*=.*[0-9]/local " + var_name + " = " + repr(current_val) + "/g' " + filename
            os.system(sed_command)
        # ------------------------- Supply Variables Update (alpha, beta) --------------------------
        for key, value in self.supply_variables.items():
            filename = GRADIENT_CONFIG_FILES_PATH+value[0]
            if type == 1:
                filename = PLUS_CONFIG_FILES_PATH + value[0]
            elif type == 2:
                filename = MINUS_CONFIG_FILES_PATH + value[0]
            elif type == 3:
                filename = GRADIENT2_CONFIG_FILES_PATH + value[0] # ADDED Gradient 2 (Ravi)
            beta_current_val = value[5]
            alpha_current_val = value[11]
            if type == 1:
                beta_current_val = value[6]
                alpha_current_val = value[12]
            elif type == 2:
                beta_current_val = value[7]
                alpha_current_val = value[13]
            elif type == 3:                             # ADDED Gradient 2 (Ravi)
                beta_current_val = value[27]
                alpha_current_val = value[29]
            link_cat = value[1]
            # Update configuration file with alpha/beta values
            sed_command = "sed -i -e 's/<param category=\"" + link_cat + "\" alpha=.* beta=.*\"/<param category=\"" + link_cat + "\" alpha=\"" + repr(alpha_current_val) + "\" beta=\"" + repr(beta_current_val) + "\"" + "  kmin=\"0.04\" kjam=\"0.2\"" + "/g' " + filename
            os.system(sed_command)
    # ======================================================================================================================
    # Updates the database with respective mid-block segment capacity values
    # If argument 'type' is 0, the parameters based on WSPSA gradient are updated
    # If argument 'type' is 1, the parameters of the plus perturbation are updated
    # If argument 'type' is 2, the parameters of the minus perturbation are updated
    # If argument 'type' is 3, the parameters based on SPSA gradient are updated
    def update_db_variables(self, type):
        conn = psycopg2.connect(self.connection_string)
        cur = conn.cursor()
        for key, value in self.db_variables.items():
            link_cat = value[0]
            num_lanes = str(value[1])
            speed = value[2]
            lane_capacity = value[7]
            if type == 1:
                lane_capacity = value[8]
            elif type == 2:
                lane_capacity = value[9]
            elif type == 3:
                lane_capacity = value[20]
            table_name = SEGMENT_TABLE
            if type == 1:
                table_name = PLUS_PERTURB_SEG_TABLE
            elif type == 2:
                table_name = MINUS_PERTURN_SEG_TABLE
            elif type == 3:
                table_name = SEGMENT_TABLE2
            # Update database with midblock segment parameter values
            update_stmt = ""
            if '>' in num_lanes:
                update_stmt = "update " + table_name + " set capacity = (num_lanes * " + repr(lane_capacity) + ") where link_category=" + link_cat + " and num_lanes " + num_lanes + " and max_speed=" + speed + ";"
            else:
                update_stmt = "update " + table_name + " set capacity = (num_lanes * " + repr(lane_capacity) + ") where link_category=" + link_cat + " and num_lanes=" + num_lanes + " and max_speed=" + speed + ";"
            cur.execute(update_stmt)
        conn.commit()
        conn.close()
    # ======================================================================================================================
    # Updates the database with respective intersection segment capacity values
    # If argument 'type' is 0, the parameters based on WSPSA gradient are updated
    # If argument 'type' is 1, the parameters of the plus perturbation are updated
    # If argument 'type' is 2, the parameters of the minus perturbation are updated
    # If argument 'type' is 3, the parameters based on SPSA gradient are updated
    def update_segcap_variables(self, runtype):
                conn = psycopg2.connect(self.connection_string)
                cur = conn.cursor()
                table_name = SEGMENT_TABLE
                if runtype == 1:
                        table_name = PLUS_PERTURB_SEG_TABLE
                elif runtype == 2:
                        table_name = MINUS_PERTURN_SEG_TABLE
                elif type == 3:
                        table_name = SEGMENT_TABLE2

                # segcap_variables[segment_id] = [segment_id, initialval, minval, maxval, perturb_step,
                #                                       currentval, +ve_perturb, -ve_perturb, weight_for_gradient, weight_for_sc, weight_for_TT]
                for key, value in self.segcap_variables.items():
                        seg_id = str(value[0])
                        lane_capacity = str(value[5])
                        if runtype == 1:
                                lane_capacity = value[6]
                        elif runtype == 2:
                                lane_capacity = value[7]
                        elif runtype == 3:
                                lane_capacity = value[18]

                        update_stmt = "update " + table_name + " set capacity = (num_lanes * " + str(lane_capacity) + ") where id = " + str(seg_id) + ";"
                        cur.execute(update_stmt)
                conn.commit()
                conn.close()

    # ======================================================================================================================
    # Main function to update the simmobility configuration/lua files and database with respective parameter values
    # If argument 'type' is 0, the parameters based on WSPSA gradient are updated
    # If argument 'type' is 1, the parameters of the plus perturbation are updated
    # If argument 'type' is 2, the parameters of the minus perturbation are updated
    # If argument 'type' is 3, the parameters based on SPSA gradient are updated
    def update_variables(self, runtype):
        self.update_lua_variables(runtype)
        self.update_db_variables(runtype)
        self.update_segcap_variables(runtype)

    # ======================================================================================================================
    # Function to Perturb non-normalized parameters
    def perturb_variables(self):
        np.random.seed()
        for key, value in self.lua_variables.items():
            #Added Vishnu
            rand_1 = np.random.binomial(1,0.5,1)
            if rand_1 == 1:
                rand_num = 1
            else:
                rand_num = -1
            value[7] = clamp(value[6] + rand_num*value[5], value[3], value[4])
            value[8] = clamp(value[6] - rand_num*value[5], value[3], value[4])
        for key, value in self.supply_variables.items():
            rand_1 = np.random.binomial(1,0.5,1)
            if rand_1 == 1:
                rand_num = 1
            else:
                rand_num = -1
            '''value[6] = clamp(value[5] + value[14], value[3], value[4])
            value[7] = clamp(value[5] - value[14], value[3], value[4])
            value[12] = clamp(value[11] + value[14], value[6], value[10])
            value[13] = clamp(value[11] - value[14], value[7], value[10])'''
            value[6] = clamp(value[5] + rand_num*value[14], value[3], value[4])
            value[7] = clamp(value[5] - rand_num*value[14], value[3], value[4])
            value[12] = clamp(value[11] + rand_num*value[14], value[9], value[10])
            value[13] = clamp(value[11] - rand_num*value[14], value[9], value[10])
        for key, value in self.db_variables.items():
            rand_1 = np.random.binomial(1,0.5,1)
            if rand_1 == 1:
                rand_num = 1
            else:
                rand_num = -1
            '''lower_limit = 0.0
            if re.search('[a-zA-Z]', value[4]) is None:
                lower_limit = float(value[4])
            else:
                reference_capacity = self.db_variables[value[4]]
                lower_limit = float(reference_capacity[7])'''
            lower_limit = value[4]
            value[8] = clamp(value[7] + rand_num*value[6], lower_limit, value[5]) # Changed Vishnu
            value[9] = clamp(value[7] - rand_num*value[6], lower_limit, value[5]) # Changed Vishnu
        for key, value in self.segcap_variables.items():
            rand_1 = np.random.binomial(1,0.5,1)
            if rand_1 == 1:
                rand_num = 1
            else:
                rand_num = -1
            value[6] = clamp(value[5] + rand_num*value[4], value[2], value[3])
            value[7] = clamp(value[5] - rand_num*value[4], value[2], value[3])

    # ======================================================================================================================
    def get_plus_variable_vector(self):
        plus_params = []
        for key, value in self.lua_variables.items():
            plus_params.append(value[7])
        for key, value in self.supply_variables.items():
            plus_params.append(value[6])
            plus_params.append(value[12])
        for key, value in self.db_variables.items():
            plus_params.append(value[8])
        for key, value in self.segcap_variables.items():
            plus_params.append(value[6])
        return plus_params

    # ======================================================================================================================
    def get_minus_variable_vector(self):
        minus_params = []
        for key, value in self.lua_variables.items():
            minus_params.append(value[8])
        for key, value in self.supply_variables.items():
            minus_params.append(value[7])
            minus_params.append(value[13])
        for key, value in self.db_variables.items():
            minus_params.append(value[9])
        for key, value in self.segcap_variables.items():
            minus_params.append(value[7])
        return minus_params

    # ======================================================================================================================
    def get_actual_variable_vector(self):
        params = []
        for key, value in self.lua_variables.items():
            params.append(value[6])
        for key, value in self.supply_variables.items():
            params.append(value[5])
            params.append(value[11])
        for key, value in self.db_variables.items():
            params.append(value[7])
        for key, value in self.segcap_variables.items():
            params.append(value[5])
        return params

    # ======================================================================================================================
    # Returns a list of three numpy arrays containing the plus perturbed parameters, apriori values, variances of apriori estimates
    def get_plus_apriori_veclist(self):
        plus_params = []
        apriori_params = []
        apriori_weights = []
        for key, value in self.lua_variables.items():
            plus_params.append(value[7])
            apriori_params.append(value[13])
            apriori_weights.append(value[17])

        for key, value in self.supply_variables.items():
            plus_params.append(value[6])
            apriori_params.append(value[19])
            apriori_weights.append(value[27])
            plus_params.append(value[12])
            apriori_params.append(value[20])
            apriori_weights.append(value[27])

        for key, value in self.db_variables.items():
            plus_params.append(value[8])
            apriori_params.append(value[14])
            apriori_weights.append(value[18])

        for key, value in self.segcap_variables.items():
            plus_params.append(value[6])
            apriori_params.append(value[12])
            apriori_weights.append(value[16])

        return np.array(apriori_params).astype(float),np.array(plus_params).astype(float),np.array(apriori_weights).astype(float)

    # ======================================================================================================================
    # Returns a list of three numpy arrays containing the normalized plus perturbed parameters, normalized apriori values, variances of apriori estimates
    def get_normalized_plus_apriori_veclist(self):
        plus_params = []
        apriori_params = []
        apriori_weights = []
        for key, value in self.lua_variables.items():
            plus_params.append(value[15])
            apriori_params.append(value[18])
            apriori_weights.append(value[17])

        for key, value in self.supply_variables.items():
            plus_params.append(value[22])
            apriori_params.append(value[28])
            apriori_weights.append(value[27])
            plus_params.append(value[25])
            apriori_params.append(value[29])
            apriori_weights.append(value[27])


        for key, value in self.db_variables.items():
            plus_params.append(value[16])
            apriori_params.append(value[19])
            apriori_weights.append(value[18])

        for key, value in self.segcap_variables.items():
            plus_params.append(value[14])
            apriori_params.append(value[17])
            apriori_weights.append(value[16])

        return np.array(apriori_params).astype(float),np.array(plus_params).astype(float),np.array(apriori_weights).astype(float)

    # ======================================================================================================================
    # Returns a list of three numpy arrays containing the plus perturbed parameters, apriori values, variances of apriori estimates
    def get_minus_apriori_veclist(self):
        minus_params = []
        apriori_params = []
        apriori_weights = []
        for key, value in self.lua_variables.items():
            minus_params.append(value[8])
            apriori_params.append(value[13])
            apriori_weights.append(value[17])

        for key, value in self.supply_variables.items():
            minus_params.append(value[7])
            apriori_params.append(value[19])
            apriori_weights.append(value[27])
            minus_params.append(value[13])
            apriori_params.append(value[20])
            apriori_weights.append(value[27])

        for key, value in self.db_variables.items():
            minus_params.append(value[9])
            apriori_params.append(value[14])
            apriori_weights.append(value[18])

        for key, value in self.segcap_variables.items():
            minus_params.append(value[7])
            apriori_params.append(value[12])
            apriori_weights.append(value[16])

        return np.array(apriori_params).astype(float),np.array(minus_params).astype(float),np.array(apriori_weights).astype(float)

    # ======================================================================================================================
    # Returns a list of three numpy arrays containing the normalized minus perturbed parameters, normalized apriori values, variances of apriori estimates
    def get_normalized_minus_apriori_veclist(self):
        minus_params = []
        apriori_params = []
        apriori_weights = []
        for key, value in self.lua_variables.items():
            minus_params.append(value[16])
            apriori_params.append(value[18])
            apriori_weights.append(value[17])


        for key, value in self.supply_variables.items():
            minus_params.append(value[23])
            apriori_params.append(value[28])
            apriori_weights.append(value[27])
            minus_params.append(value[26])
            apriori_params.append(value[29])
            apriori_weights.append(value[27])


        for key, value in self.db_variables.items():
            minus_params.append(value[17])
            apriori_params.append(value[19])
            apriori_weights.append(value[18])

        for key, value in self.segcap_variables.items():
            minus_params.append(value[15])
            apriori_params.append(value[17])
            apriori_weights.append(value[16])

        return np.array(apriori_params).astype(float),np.array(minus_params).astype(float),np.array(apriori_weights).astype(float)

    # ======================================================================================================================
    def get_gradient_apriori_veclist(self):
        gradient_params = []
        apriori_params = []
        apriori_weights = []
        for key, value in self.lua_variables.items():
            gradient_params.append(value[6])
            apriori_params.append(value[13])
            apriori_weights.append(value[17])

        for key, value in self.supply_variables.items():
            gradient_params.append(value[5])
            apriori_params.append(value[19])
            apriori_weights.append(value[27])
            gradient_params.append(value[11])
            apriori_params.append(value[20])
            apriori_weights.append(value[27])

        for key, value in self.db_variables.items():
            gradient_params.append(value[7])
            apriori_params.append(value[14])
            apriori_weights.append(value[18])

        for key, value in self.segcap_variables.items():
            gradient_params.append(value[5])
            apriori_params.append(value[12])
            apriori_weights.append(value[16])

        return np.array(apriori_params).astype(float),np.array(gradient_params).astype(float),np.array(apriori_weights).astype(float)

    # ======================================================================================================================
    def get_gradient2_apriori_veclist(self):
        gradient2_params = []
        apriori_params = []
        apriori_weights = []
        for key, value in self.lua_variables.items():
            gradient2_params.append(value[19])
            apriori_params.append(value[13])
            apriori_weights.append(value[17])
        for key, value in self.supply_variables.items():
            gradient2_params.append(value[30])
            apriori_params.append(value[19])
            apriori_weights.append(value[27])
            gradient2_params.append(value[32])
            apriori_params.append(value[20])
            apriori_weights.append(value[27])
        for key, value in self.db_variables.items():
            gradient2_params.append(value[20])
            apriori_params.append(value[14])
            apriori_weights.append(value[18])
        for key, value in self.segcap_variables.items():
            gradient2_params.append(value[18])
            apriori_params.append(value[12])
            apriori_weights.append(value[16])

        return np.array(apriori_params).astype(float),np.array(gradient2_params).astype(float),np.array(apriori_weights).astype(float)

    # ======================================================================================================================
    def get_normalized_plus_variable_vector(self):
        plus_params = []
        for key, value in self.lua_variables.items():
            plus_params.append(value[15])


        for key, value in self.supply_variables.items():
            plus_params.append(value[22])
            plus_params.append(value[25])

        for key, value in self.db_variables.items():
            plus_params.append(value[16])

        for key, value in self.segcap_variables.items():
            plus_params.append(value[14])

        return plus_params

    # ======================================================================================================================
    def get_normalized_minus_variable_vector(self):
        minus_params = []
        for key, value in self.lua_variables.items():
            minus_params.append(value[16])


        for key, value in self.supply_variables.items():
            minus_params.append(value[23])
            minus_params.append(value[26])

        for key, value in self.db_variables.items():
            minus_params.append(value[17])

        for key, value in self.segcap_variables.items():
                minus_params.append(value[15])

        return minus_params

    # ======================================================================================================================
    def get_normalized_actual_variable_vector(self):
        params = []
        for key, value in self.lua_variables.items():
            params.append(value[14])


        for key, value in self.supply_variables.items():
            params.append(value[21])
            params.append(value[24])

        for key, value in self.db_variables.items():
            params.append(value[15])

        for key, value in self.segcap_variables.items():
                params.append(value[13])

        return params

    # ======================================================================================================================
    def get_gradient_weights(self):
        weights = []
        for value in self.lua_variables.values():
            weights.append(value[9])
        for value in self.supply_variables.values():
            weights.append(value[15])
            weights.append(value[15])
        for value in self.db_variables.values():
            weights.append(value[10])
        for value in self.segcap_variables.values():
            weights.append(value[8])

        return weights

    # ======================================================================================================================
    # Computes gradient vector
    def compute_gradient(self, z_plus, z_minus, length, diff_params, functionCallTime):
        index = 0
        N_meas = length[0] + length[1] + length[2] + length[3]
        gradient = []
        startTime = time.time()
        zdiff_counts = (sum(z_plus[0:length[0]]) - sum(z_minus[0:length[0]]))
        zdiff_TT = (sum(z_plus[length[0]:(length[0]+length[1])])-sum(z_minus[length[0]:(length[0]+length[1])]))
        zdiff_boarding_alighting = (sum(z_plus[(length[0]+length[1]):(length[0]+length[1]+length[2]+length[3])]) - sum(z_minus[(length[0]+length[1]):(length[0]+length[1]+length[2]+length[3])]))

        for value in self.lua_variables.values():
            temp_gradient = 0
            gradient_numerator = 0
            gradient_numerator += zdiff_counts*value[10]
            gradient_numerator += zdiff_TT*value[11]
            gradient_numerator += zdiff_boarding_alighting*value[12]
            gradient_numerator += z_plus[N_meas+index] - z_minus[N_meas+index]
            temp_gradient = gradient_numerator/diff_params[index]
            gradient.append(temp_gradient)
            index += 1

        for value in self.supply_variables.values():
            temp_gradient = 0
            gradient_numerator = 0
            gradient_numerator += zdiff_counts*value[16]
            gradient_numerator += zdiff_TT*value[17]
            gradient_numerator += zdiff_boarding_alighting*value[18]
            gradient_numerator += z_plus[N_meas+index] - z_minus[N_meas+index]
            temp_gradient = gradient_numerator/diff_params[index]
            gradient.append(temp_gradient)
            index += 1
            temp_gradient = 0
            gradient_numerator = 0
            gradient_numerator += zdiff_counts*value[16]
            gradient_numerator += zdiff_TT*value[17]
            gradient_numerator += zdiff_boarding_alighting*value[18]
            gradient_numerator += z_plus[N_meas+index] - z_minus[N_meas+index]
            temp_gradient = gradient_numerator/diff_params[index]
            gradient.append(temp_gradient)
            index += 1

        for value in self.db_variables.values():
            temp_gradient = 0
            gradient_numerator = 0
            gradient_numerator += zdiff_counts*value[11]
            gradient_numerator += zdiff_TT*value[12]
            gradient_numerator += zdiff_boarding_alighting*value[13]
            gradient_numerator += z_plus[N_meas+index] - z_minus[N_meas+index]
            temp_gradient = gradient_numerator/diff_params[index]
            gradient.append(temp_gradient)
            index += 1

        for value in self.segcap_variables.values():
            temp_gradient = 0
            gradient_numerator = 0
            gradient_numerator += zdiff_counts*value[9]
            gradient_numerator += zdiff_TT*value[10]
            gradient_numerator += zdiff_boarding_alighting*value[11]
            gradient_numerator += z_plus[N_meas+index] - z_minus[N_meas+index]
            temp_gradient = gradient_numerator/diff_params[index]
            gradient.append(temp_gradient)
            index += 1
        return np.array(gradient)

    # ======================================================================================================================
    # Constructs the weight matrix (this function is no longer used because of memory issues, replaced by the function above)
    def generate_weight_matrix(self, length_vector):
        index = 0
        N_meas = length_vector[0] + length_vector[1] + length_vector[2] + length_vector[3]

        for value in self.lua_variables.values():
            weight_array = np.array([])
            weight_array = np.append(weight_array, np.repeat(value[10], length_vector[0]))
            weight_array = np.append(weight_array, np.repeat(value[11], length_vector[1]))
            weight_array = np.append(weight_array, np.repeat(value[12], length_vector[2]))
            weight_array = np.append(weight_array, np.repeat(value[12], length_vector[3]))
            weight_array = np.append(weight_array, np.repeat(0, length_vector[4]))
            weight_array[N_meas+index] = 1
            if index == 0:
                weight_matrix = weight_array
            else:
                weight_matrix = np.vstack([weight_matrix, weight_array])
            index += 1

        for value in self.supply_variables.values():
            weight_array = np.array([])
            weight_array = np.append(weight_array, np.repeat(value[16], length_vector[0]))
            weight_array = np.append(weight_array, np.repeat(value[17], length_vector[1]))
            weight_array = np.append(weight_array, np.repeat(value[18], length_vector[2]))
            weight_array = np.append(weight_array, np.repeat(value[18], length_vector[3]))
            weight_array = np.append(weight_array, np.repeat(0, length_vector[4]))
            weight_array[N_meas+index] = 1
            weight_matrix = np.vstack([weight_matrix, weight_array])
            index += 1

            weight_array = np.array([])
            weight_array = np.append(weight_array, np.repeat(value[16], length_vector[0]))
            weight_array = np.append(weight_array, np.repeat(value[17], length_vector[1]))
            weight_array = np.append(weight_array, np.repeat(value[18], length_vector[2]))
            weight_array = np.append(weight_array, np.repeat(value[18], length_vector[3]))
            weight_array = np.append(weight_array, np.repeat(0, length_vector[4]))
            weight_array[N_meas+index] = 1
            weight_matrix = np.vstack([weight_matrix, weight_array])
            index += 1

        for value in self.db_variables.values():
            weight_array = np.array([])
            weight_array = np.append(weight_array, np.repeat(value[11], length_vector[0]))
            weight_array = np.append(weight_array, np.repeat(value[12], length_vector[1]))
            weight_array = np.append(weight_array, np.repeat(value[13], length_vector[2]))
            weight_array = np.append(weight_array, np.repeat(value[13], length_vector[3]))
            weight_array = np.append(weight_array, np.repeat(0, length_vector[4]))
            weight_array[N_meas+index] = 1
            weight_matrix = np.vstack([weight_matrix, weight_array])
            index += 1

        for value in self.segcap_variables.values():
            weight_array = np.array([])
            weight_array = np.append(weight_array, np.repeat(value[9], length_vector[0]))
            weight_array = np.append(weight_array, np.repeat(value[10], length_vector[1]))
            weight_array = np.append(weight_array, np.repeat(value[11], length_vector[2]))
            weight_array = np.append(weight_array, np.repeat(value[11], length_vector[3]))
            weight_array = np.append(weight_array, np.repeat(0, length_vector[4]))
            weight_array[N_meas+index] = 1
            weight_matrix = np.vstack([weight_matrix, weight_array])
            index += 1

        return np.transpose(weight_matrix)

    # ======================================================================================================================
    def update_gradient_values(self, params):
        index = 0
        for value in self.lua_variables.values():
            value[6] = clamp(float(params[index]), value[3], value[4])
            index += 1

        #for value in self.pvtrc_variables.values():
        #	value[6] = clamp(float(params[index]), value[3], value[4])
        #	index += 1

        for value in self.supply_variables.values():
            value[5] = clamp(float(params[index]), value[3], value[4])
            index += 1
            value[11] = clamp(float(params[index]), value[9], value[10])
            index += 1

        for value in self.db_variables.values():
            '''lower_limit = 0.0
            if re.search('[a-zA-Z]', value[4]) is None:
                lower_limit = float(value[4])
            else:
                reference_capacity = self.db_variables[value[4]]
                lower_limit = float(reference_capacity[7])'''

            lower_limit = value[4]
            value[7] = clamp(float(params[index]), lower_limit, value[5])
            index += 1

        for value in self.segcap_variables.values():
                value[5] = clamp(float(params[index]), value[2], value[3])
                index += 1

    # ======================================================================================================================
    def update_gradient_values_SPSA(self, params):
        index = 0
        for value in self.lua_variables.values():
            value[19] = clamp(float(params[index]), value[3], value[4])
            index += 1

        #for value in self.pvtrc_variables.values():
        #    value[6] = clamp(float(params[index]), value[3], value[4])
        #    index += 1

        for value in self.supply_variables.values():
            value[27] = clamp(float(params[index]), value[3], value[4])
            index += 1
            value[29] = clamp(float(params[index]), value[9], value[10])
            index += 1

        for value in self.db_variables.values():
            '''lower_limit = 0.0
            if re.search('[a-zA-Z]', value[4]) is None:
                lower_limit = float(value[4])
            else:
                reference_capacity = self.db_variables[value[4]]
                lower_limit = float(reference_capacity[7])'''

            lower_limit = value[4]
            value[20] = clamp(float(params[index]), lower_limit, value[5])
            index += 1

        for value in self.segcap_variables.values():
            value[18] = clamp(float(params[index]), value[2], value[3])
            index += 1

    # ======================================================================================================================
    def update_normalized_gradient_values(self,params):
        index = 0
        for value in self.lua_variables.values():
            value[14] = clamp(float(params[index]), 0, 1)
            index += 1

        #for value in self.pvtrc_variables.values():
        #    value[6] = clamp(float(params[index]), value[3], value[4])
        #    index += 1

        for value in self.supply_variables.values():
            value[21] = clamp(float(params[index]), 0, 1)
            index += 1
            value[24] = clamp(float(params[index]), 0, 1)
            index += 1

        for value in self.db_variables.values():
            '''lower_limit = 0.0
            if re.search('[a-zA-Z]', value[4]) is None:
                lower_limit = float(value[4])
            else:
                reference_capacity = self.db_variables[value[4]]
                lower_limit = float(reference_capacity[7])'''

            value[15] = clamp(float(params[index]), 0, 1)
            index += 1

        for value in self.segcap_variables.values():
            value[13] = clamp(float(params[index]), 0, 1)
            index += 1

    # ======================================================================================================================
    def update_normalized_gradient_values_SPSA(self,params):
        index = 0
        for value in self.lua_variables.values():
            value[20] = clamp(float(params[index]), 0, 1)
            index += 1

        #for value in self.pvtrc_variables.values():
        #    value[6] = clamp(float(params[index]), value[3], value[4])
        #    index += 1

        for value in self.supply_variables.values():
            value[28] = clamp(float(params[index]), 0, 1)
            index += 1
            value[30] = clamp(float(params[index]), 0, 1)
            index += 1

        for value in self.db_variables.values():
            '''lower_limit = 0.0
            if re.search('[a-zA-Z]', value[4]) is None:
                lower_limit = float(value[4])
            else:
                reference_capacity = self.db_variables[value[4]]
                lower_limit = float(reference_capacity[7])'''

            value[21] = clamp(float(params[index]), 0, 1)
            index += 1

        for value in self.segcap_variables.values():
            value[19] = clamp(float(params[index]), 0, 1)
            index += 1

    # ======================================================================================================================
    def save_current_param_values(self, rmsn_val, final_obj_val, plus_obj_val, minus_obj_val, filename):
        current_val = []
        current_val.append([rmsn_val[2], final_obj_val[2], plus_obj_val[2], minus_obj_val[2]])
        current_val.append([rmsn_val[0], final_obj_val[0], plus_obj_val[0], minus_obj_val[0]])
        current_val.append([rmsn_val[1], final_obj_val[1], plus_obj_val[1], minus_obj_val[1]])
        for key, value in self.lua_variables.items():
            current_val.append([value[0], value[1], value[6]])

        #for key, value in self.pvtrc_variables.items():
        #	current_val.append([value[0], value[1], value[6]])

        for key, value in self.supply_variables.items():
            current_val.append([value[0], value[1], "beta", value[5], "alpha", value[11]])

        for key, value in self.db_variables.items():
            current_val.append(["Capacity", key, value[0], value[1], value[2], value[7]])

        for key, value in self.segcap_variables.items():
            current_val.append(["int_capacity", key, value[5]])

        with open(filename, 'w') as fp:
            writer = csv.writer(fp)
            writer.writerows(current_val)

    # ======================================================================================================================
    def save_gradient(self, gradients, filename):
        index = 0
        value_list = []
        for value in self.lua_variables.values():
            value_list.append([value, gradients[index]])
            index += 1

        #for value in self.pvtrc_variables.values():
        #	value_list.append([value, gradients[index]])
        #	index += 1

        for value in self.supply_variables.values():
            value_list.append([value, gradients[index], gradients[index+1]])
            index += 2

        for value in self.db_variables.values():
            value_list.append([value, gradients[index]])
            index += 1

        for value in self.segcap_variables.values():
            value_list.append([value, gradients[index]])
            index += 1

        with open(filename, 'w') as fp:
            writer = csv.writer(fp)
            writer.writerows(value_list)

    # ======================================================================================================================
    def get_weights_sc_vector(self):
        sc_weights = []
        for key, value in self.lua_variables.items():
            sc_weights.append(value[10])

        #for key, value in self.pvtrc_variables.items():
        #	sc_weights.append(value[10])

        for key, value in self.supply_variables.items():
            sc_weights.append(value[16])
            sc_weights.append(value[16])

        for key, value in self.db_variables.items():
            sc_weights.append(value[11])

        for key, value in self.segcap_variables.items():
            sc_weights.append(value[9])

        return sc_weights

    # ======================================================================================================================
    def get_weights_pts_vector(self):
        pts_weights = []
        for key, value in self.lua_variables.items():
            pts_weights.append(value[12])

        for key, value in self.supply_variables.items():
            pts_weights.append(value[18])
            pts_weights.append(value[18])

        for key, value in self.db_variables.items():
            pts_weights.append(value[13])

        for key, value in self.segcap_variables.items():
            pts_weights.append(value[11])

        return pts_weights

    # ======================================================================================================================
    def get_weights_tt_vector(self):
        tt_weights = []
        for key, value in self.lua_variables.items():
            tt_weights.append(value[11])

        #for key, value in self.pvtrc_variables.items():
        #	tt_weights.append(value[11])

        for key, value in self.supply_variables.items():
            tt_weights.append(value[17])
            tt_weights.append(value[17])

        for key, value in self.db_variables.items():
            tt_weights.append(value[12])

        for key, value in self.segcap_variables.items():
            tt_weights.append(value[10])

        return tt_weights
# ======================================================================================================================
# Main Calibration Class
class MTCalibration:
    obj_fn_type = 0
    no_of_iterations = 0
    interval = 0
    start_time = 0
    end_time = 0
    weights = dict()
    num_sensor_locations = 0

    def __init__(self, iterations):
        self.obj_fn_type = 1
        self.no_of_iterations = iterations
        self.interval = 15
        self.start_time = 7
        self.end_time = 21
        self.weights['ScreenLine'] = 0.6
        self.weights['TravelTime'] = 0.2
        self.weights['PT_Boarding'] = 0.1
        self.weights['PT_Alighting'] = 0.1
        self.num_sensor_locations = 410
        self.calibration_variables = MidTermVariablesManager()
        self.calibration_variables.read_variables()

        # SPSA Parameters
        self.alpha = 0.602
        self.a = 1
        self.A = 100000
# ======================================================================================================================

