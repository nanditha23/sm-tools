import csv
import numpy as np
from collections import namedtuple

OD_Interval = namedtuple("OD_Interval", ["origin", "destination", "interval"])

def get_time_window(time_str):
    time_val = time_str.split(":")
    time_window = (int(time_val[0]) * 4) + (int(time_val[1]) / 4)
    return time_window


# Returns a dictionary (to make searching faster) of observed travel time where,
# key = {origin_zone, destination_zone, interval} and, value = {travel_time, variance}
def get_travel_time_obs():
    travel_time_obs_dict = dict()
    travel_time_obs_list = list(csv.reader(open("data/gps_traveltime.csv", "r")))
    for item in travel_time_obs_list:
        time_window = get_time_window(item[5])
        od_interval_key = OD_Interval(origin=int(item[3]), destination=int(item[4]), interval=time_window)

        if len(item[2]) == 0:
            item[2] = "0.0"
        travel_time_obs_dict[od_interval_key] = (float(item[1]), float(item[2]))

    return travel_time_obs_dict

travel_time_obs = get_travel_time_obs()


# Returns the dictionary of simulated travel time from the input subtrip metrics file
def get_travel_time_sim(subtrip_metrics_file):
    travel_time_sim_list = list(csv.reader(open(subtrip_metrics_file, "r")))
    temp_travel_time_sim_dict = dict()

    for item in travel_time_sim_list:
        time_window = get_time_window(item[8])
        od_interval_key = OD_Interval(origin=int(item[4]), destination=int(item[6]), interval=time_window)
        if temp_travel_time_sim_dict.__contains__(od_interval_key):
            temp_travel_time_sim_dict[od_interval_key].append(float(item[10]) * 60)
        else:
            temp_travel_time_sim_dict[od_interval_key] = list()
            temp_travel_time_sim_dict[od_interval_key].append(float(item[10]) * 60)

    travel_time_sim_dict = dict()
    for key, value in temp_travel_time_sim_dict.iteritems():
        travel_time_sim_dict[key] = sum(value) / float(len(value))

    return travel_time_sim_dict


def generate_travel_time_vector(subtrip_metrics_file, start_time, end_time):
    travel_time_sim = get_travel_time_sim(subtrip_metrics_file)

    start_time_interval = start_time * 4
    end_time_interval = end_time * 4

    obs_tt_list = list()
    obs_tt_variance_list = list()
    sim_tt_list = list()

    for sim_key, sim_value in travel_time_sim.iteritems():
        if start_time_interval <= sim_key.interval < end_time_interval:
            if travel_time_obs.__contains__(sim_key):
                obs_value = travel_time_obs[sim_key]
                obs_tt_list.append(obs_value[0])
                obs_tt_variance_list.append(obs_value[1])
                sim_tt_list.append(sim_value)

    return np.array(sim_tt_list), np.array(obs_tt_list), np.array(obs_tt_variance_list)

'''if __name__ == "__main__":
    travel_time_vector = generate_travel_time_vector("GRADIENT_RUN/SimMobility/subtrip_metrics.csv", 7, 10)

    with open("test_tt.csv", "w") as fp:
        writer = csv.writer(fp)
        writer.writerows(travel_time_vector)'''
