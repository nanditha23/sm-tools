import csv
import collections
import sys

all_loop_data = collections.defaultdict()

n_iter = int(sys.argv[1])

for i in range(1, n_iter+1):
	all_loop_data[i] = list(csv.reader(open("SimMobility_Minus/VehicleCounts_" + str(i) +".csv", "rb"), delimiter=","))

consolidated_loop_data = collections.OrderedDict()

for i in range(1, n_iter+1):
	for loop_data in all_loop_data[i]:
		if consolidated_loop_data.__contains__((loop_data[0], loop_data[1], loop_data[2], loop_data[3])):
			consolidated_loop_data[(loop_data[0], loop_data[1], loop_data[2], loop_data[3])] += int(loop_data[4])
		else:
			consolidated_loop_data[(loop_data[0], loop_data[1], loop_data[2], loop_data[3])] = int(loop_data[4])

writer = csv.writer(open('SimMobility_Minus/avgVehicleCounts.csv', 'wb'))
for key, value in consolidated_loop_data.iteritems():
	value /= n_iter
	writer.writerow([int(key[0]), int(key[1]),int(key[2]), int(key[3]), value])




