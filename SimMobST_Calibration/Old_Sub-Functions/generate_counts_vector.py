import csv
import sys

start_time = int(float(sys.argv[1]) * 60)
end_time = int(float(sys.argv[2]) * 60)
interval = int(sys.argv[3])

warm_up_intervals = int(sys.argv[4])

start_interval_slot = (start_time / interval) + warm_up_intervals
end_interval_slot = end_time / interval

last_sim_interval = ((end_time-start_time) * 60 * 1000) - 1000


def get_interval_sim(curr_time):
	if curr_time == last_sim_interval:
		curr_time += 1000
	mins = (curr_time / (1000 * 60))
	return start_interval_slot + (mins / interval) - 1


def get_interval_real(curr_time):
	mins = curr_time / 60
	return mins / interval

sim_vehicle_counts = list(csv.reader(open("SimMobility/avgVehicleCounts.csv", "rb"), delimiter=","))
real_vehicle_counts = list(csv.reader(open("data/SensorMapping/RealData_sec.csv", "rb"), delimiter=" "))
ref_sensors = list(csv.reader(open("data/ref_segments.csv", "rb"), delimiter=" "))

sim_vehicle_counts_dict = dict()
real_vehicle_counts_dict = dict()

seg_lane_count = dict()

for item in sim_vehicle_counts:
	slot = get_interval_sim(int(item[0]))
	if start_interval_slot <= slot < end_interval_slot:
		if sim_vehicle_counts_dict.__contains__((slot, int(item[2]))):
			sim_vehicle_counts_dict[(slot, int(item[2]))] += int(item[4])
			seg_lane_count[int(item[2])] += 1
		else:
			sim_vehicle_counts_dict[(slot, int(item[2]))] = int(item[4])
			seg_lane_count[int(item[2])] = 1

for item in real_vehicle_counts:
	slot = get_interval_real(int(item[0]))
	if start_interval_slot <= slot < end_interval_slot:
		if real_vehicle_counts_dict.__contains__((slot, int(item[2]))):
			real_vehicle_counts_dict[(slot, int(item[2]))] += int(item[4])
		else:
			real_vehicle_counts_dict[(slot, int(item[2]))] = int(item[4])

real_count = []
sim_count = []
real_count_rm = []
sim_count_rm = []

count_seg_id_real_sim = []

for key, value in sim_vehicle_counts_dict.items():
	if real_vehicle_counts_dict.__contains__(key):
		real_count.append([real_vehicle_counts_dict[key]])
		sim_count.append([value])
		real_count_rm.append([real_vehicle_counts_dict[key]])
		sim_count_rm.append([value])
		count_seg_id_real_sim.append([key[0], key[1], real_vehicle_counts_dict[key], value, seg_lane_count[key[1]]])
	else:
		real_count.append([0])
		sim_count.append([0])

with open('data/truecount.csv', 'w') as fp:
		writer = csv.writer(fp, delimiter=',')
		writer.writerows(real_count)

with open('data/simcount.csv', 'w') as fp:
		writer = csv.writer(fp, delimiter=',')
		writer.writerows(sim_count)

with open('data/trueCountsRM.csv', 'w') as fp:
		writer = csv.writer(fp, delimiter=',')
		writer.writerows(real_count_rm)

with open('data/simCountsRM.csv', 'w') as fp:
		writer = csv.writer(fp, delimiter=',')
		writer.writerows(sim_count_rm)

with open('data/compare_counts.csv', 'w') as fp:
		writer = csv.writer(fp, delimiter=",")
		writer.writerows(count_seg_id_real_sim)
