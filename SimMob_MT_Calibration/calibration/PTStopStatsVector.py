import csv
import numpy as np
from collections import namedtuple

PT_Stat_Interval = namedtuple("PT_Stat_Interval", ["stop_id", "line_id", "interval"])


def get_boarding_info_obs():
    pt_stat_obs = list(csv.reader(open("data/ez_link_data.csv", "r")))
    boarding_info_dict = dict()
    for item in pt_stat_obs:
        boarding_info_key = PT_Stat_Interval(stop_id=item[0], line_id=item[1], interval=int(item[2]))
        boarding_info_dict[boarding_info_key] = (float(item[3]), float(item[5]))

    return boarding_info_dict


def get_alighting_info_obs():
    pt_stat_obs = list(csv.reader(open("data/ez_link_data.csv", "r")))
    alighting_info_dict = dict()

    for item in pt_stat_obs:
        alighting_info_key = PT_Stat_Interval(stop_id=item[0], line_id=item[1], interval=int(item[2]))
        alighting_info_dict[alighting_info_key] = (float(item[4]), float(item[6]))

    return alighting_info_dict

boarding_info_obs = get_boarding_info_obs()
alighting_info_obs = get_alighting_info_obs()


def get_boarding_info_sim(pt_stop_stats_file):
    pt_stat_sim = list(csv.reader(open(pt_stop_stats_file, "r")))
    boarding_info_dict = dict()

    for item in pt_stat_sim:
        pt_line = item[2].split("_")
        interval_15min = int(int(item[0]) / 3)
        boarding_info_key = PT_Stat_Interval(stop_id=item[1], line_id=pt_line[0], interval=interval_15min)

        if boarding_info_dict.__contains__(boarding_info_key):
            boarding_info_dict[boarding_info_key] += float(item[6])
        else:
            boarding_info_dict[boarding_info_key] = float(item[6])

    return boarding_info_dict


def get_alighting_info_sim(pt_stop_stats_file):
    pt_stat_sim = list(csv.reader(open(pt_stop_stats_file, "r")))
    alighting_info_dict = dict()

    for item in pt_stat_sim:
        pt_line = item[2].split("_")
        interval_15min = int(item[0]) / 3
        alighting_info_key = PT_Stat_Interval(stop_id=item[1], line_id=pt_line[0], interval=interval_15min)

        if alighting_info_dict.__contains__(alighting_info_key):
            alighting_info_dict[alighting_info_key] += float(item[5])
        else:
            alighting_info_dict[alighting_info_key] = float(item[5])

    return alighting_info_dict


def generate_boarding_info_vector(pt_stop_stats_file, start_time, end_time):
    start_interval = start_time * 4
    end_interval = end_time * 4

    boarding_info_sim = get_boarding_info_sim(pt_stop_stats_file)

    boarding_vec_obs = list()
    boarding_vec_sim = list()
    boarding_var_vec = list()

    for obs_key, obs_value in boarding_info_obs.iteritems():
        if start_interval <= obs_key.interval <= end_interval:
            boarding_vec_obs.append(obs_value[0])
            boarding_var_vec.append(obs_value[1])
            if boarding_info_sim.__contains__(obs_key):
                boarding_vec_sim.append(boarding_info_sim[obs_key])
            else:
                boarding_vec_sim.append(0)

    return np.array(boarding_vec_sim), np.array(boarding_vec_obs), np.array(boarding_var_vec)


def generate_alighting_info_vector(pt_stop_stats_file, start_time, end_time):
    start_interval = start_time * 4
    end_interval = end_time * 4

    alighting_info_sim = get_alighting_info_sim(pt_stop_stats_file)

    alighting_vec_obs = list()
    alighting_vec_sim = list()
    alighting_var_vec = list()

    for obs_key, obs_value in alighting_info_obs.iteritems():
        if start_interval <= obs_key.interval <= end_interval:
            alighting_vec_obs.append(obs_value[0])
            alighting_var_vec.append(obs_value[1])
            if alighting_info_sim.__contains__(obs_key):
                alighting_vec_sim.append(alighting_info_sim[obs_key])
            else:
                alighting_vec_sim.append(0)

    return np.array(alighting_vec_sim), np.array(alighting_vec_obs), np.array(alighting_var_vec)

