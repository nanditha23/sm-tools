import csv
import sys

start_time = int(float(sys.argv[1]) * 60 * 60)
end_time = int(float(sys.argv[2]) * 60 * 60)
interval = int(sys.argv[3]) * 60

interval_count = int((end_time - start_time) / interval)

sim_vehicle_counts = list(csv.reader(open("SimMobility/avgVehicleCounts.csv", "rb"), delimiter=","))
real_vehicle_counts = list(csv.reader(open("data/SensorMapping/RealData_sec.csv", "rb"), delimiter=" "))
ref_sensors = list(csv.reader(open("data/Ref_count_Wmat.csv", "rb"), delimiter=" "))

sim_vehicle_counts_dict = dict()
real_vehicle_counts_dict = dict()

for item in sim_vehicle_counts:
	sim_vehicle_counts_dict[(int(item[0]), int(item[3]))] = item[4]

for item in real_vehicle_counts:
	if '#' in item[3]:
		continue
	curr_interval = ((int(item[0]) - start_time)/interval) + 1
	count_interval = curr_interval * interval * 1000

	if curr_interval == interval_count:
		count_interval -= 1000

	real_vehicle_counts_dict[(count_interval, int(item[3]))] = item[4]

real_count = list()
sim_count = list()

real_count_matching = list()
sim_count_matching = list()

for i in range(1, interval_count+1):
	interval_val = i * interval * 1000

	if i == interval_count:
		interval_val -= 1000

	match_count = 0
	for item in ref_sensors:
		if real_vehicle_counts_dict.__contains__((interval_val, int(item[0]))) and \
				sim_vehicle_counts_dict.__contains__((interval_val, int(item[0]))):
			real_count.append([real_vehicle_counts_dict.__getitem__((interval_val, int(item[0])))])
			sim_count.append([sim_vehicle_counts_dict.__getitem__((interval_val, int(item[0])))])
			real_count_matching.append([real_vehicle_counts_dict.__getitem__((interval_val, int(item[0])))])
			sim_count_matching.append([sim_vehicle_counts_dict.__getitem__((interval_val, int(item[0])))])
			match_count += 1
		else:
			real_count.append([0])
			sim_count.append([0])
	print "Interval: ", i, match_count, " matches"

with open('data/truecount.csv', 'w') as fp:
		writer = csv.writer(fp, delimiter=',')
		writer.writerows(real_count)

with open('data/simcount.csv', 'w') as fp:
		writer = csv.writer(fp, delimiter=',')
		writer.writerows(sim_count)

with open('data/trueCountsRM.csv', 'w') as fp:
		writer = csv.writer(fp, delimiter=',')
		writer.writerows(real_count_matching)

with open('data/simCountsRM.csv', 'w') as fp:
		writer = csv.writer(fp, delimiter=',')
		writer.writerows(sim_count_matching)




