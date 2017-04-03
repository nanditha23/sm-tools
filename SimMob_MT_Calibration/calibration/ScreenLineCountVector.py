import csv
import numpy as np

toBeSkipped = {'Taxi', 'LGV', 'HGV', 'Others', 'Bus'}


def get_interval(time_val):
	time_split_list = time_val.split(':')
	return (int(time_split_list[0]) * 2) + (int(time_split_list[1])/30)


def generate_screen_line_vector(sim_screen_line_file, start_time, end_time):
	screen_line_count_real = list(csv.reader(open("data/screen_line_count_real.csv", "rb"), delimiter=","))
	screen_line_count_sim = list(csv.reader(open(sim_screen_line_file, "rb"), delimiter="\t"))

	start_interval = start_time * 2
	end_interval = end_time * 2

	screen_line_count_real_dict = dict()
	screen_line_count_sim_dict = dict()

	for item in screen_line_count_sim:
		interval = get_interval(item[1])
		value = int(item[4])

		if interval < start_interval or interval > end_interval:
			continue

		if screen_line_count_sim_dict.__contains__(item[0]):
			if screen_line_count_sim_dict.__getitem__(item[0]).__contains__(interval):
				if screen_line_count_sim_dict.__getitem__(item[0]).__getitem__(interval).__contains__(item[3]):
					screen_line_count_sim_dict[item[0]][interval][item[3]] += value
				else:
					screen_line_count_sim_dict[item[0]][interval][item[3]] = value
			else:
				screen_line_count_sim_dict[item[0]][interval] = dict()
				screen_line_count_sim_dict[item[0]][interval][item[3]] = value
		else:
			screen_line_count_sim_dict[item[0]] = dict()
			screen_line_count_sim_dict[item[0]][interval] = dict()
			screen_line_count_sim_dict[item[0]][interval][item[3]] = value

	for item in screen_line_count_real:
		interval = int(item[1])
		value_mean = int(item[3])
		if int(float(item[4])) == 0:
			value_variance = 1.0
		else: 
			value_variance = float(item[4])
		
		if interval < start_interval or interval > end_interval:
			continue

		if screen_line_count_real_dict.__contains__(item[0]):
			if screen_line_count_real_dict.__getitem__(item[0]).__contains__(interval):
				screen_line_count_real_dict[item[0]][interval][item[2]] = dict()
				screen_line_count_real_dict[item[0]][interval][item[2]]['mean'] = value_mean
				screen_line_count_real_dict[item[0]][interval][item[2]]['variance'] = value_variance

			else:
				screen_line_count_real_dict[item[0]][interval] = dict()
				screen_line_count_real_dict[item[0]][interval][item[2]] = dict()
				screen_line_count_real_dict[item[0]][interval][item[2]]['mean'] = value_mean
				screen_line_count_real_dict[item[0]][interval][item[2]]['variance'] = value_variance
				
		else:
			screen_line_count_real_dict[item[0]] = dict()
			screen_line_count_real_dict[item[0]][interval] = dict()
			screen_line_count_real_dict[item[0]][interval][item[2]] = dict()
			screen_line_count_real_dict[item[0]][interval][item[2]]['mean'] = value_mean
			screen_line_count_real_dict[item[0]][interval][item[2]]['variance'] = value_variance

	sim_list = []
	real_list = []
	real_list_var = []

	for segment, interval_dict in screen_line_count_real_dict.items():
		if screen_line_count_sim_dict.__contains__(segment):
			for interval, mode_dict in interval_dict.items():
				if screen_line_count_sim_dict.__getitem__(segment).__contains__(interval):
					for mode, value in mode_dict.items():
						if mode not in toBeSkipped:
							if screen_line_count_sim_dict.__getitem__(segment).__getitem__(interval).__contains__(mode):
								sim_list.append(screen_line_count_sim_dict.__getitem__(segment).__getitem__(interval).__getitem__(mode))
								real_list.append(value['mean'])
								real_list_var.append(value['variance'])
							else:
								sim_list.append(0)
								real_list.append(value['mean'])
								real_list_var.append(value['variance'])					
				else:
					for mode, value in mode_dict.items():
						if mode not in toBeSkipped:
							sim_list.append(0)
							real_list.append(value['mean'])
							real_list_var.append(value['variance'])
		else:
			for interval, mode_dict in interval_dict.items():
				for mode, value in mode_dict.items():
					if mode not in toBeSkipped:
						sim_list.append(0)
						real_list.append(value['mean'])
						real_list_var.append(value['variance'])

	'''for segment, interval_dict in screen_line_count_sim_dict.items():
		if screen_line_count_real_dict.__contains__(segment):
			for interval, mode_dict in interval_dict.items():
				if screen_line_count_real_dict.__getitem__(segment).__contains__(interval):
					for mode, value in mode_dict.items():
						if mode not in toBeSkipped:
							if screen_line_count_real_dict.__getitem__(segment).__getitem__(interval).__contains__(mode):
								sim_list.append(value)
								real_list.append(screen_line_count_real_dict.__getitem__(segment).__getitem__(interval).__getitem__(mode))
	'''
	return np.array(sim_list), np.array(real_list), np.array(real_list_var) 


