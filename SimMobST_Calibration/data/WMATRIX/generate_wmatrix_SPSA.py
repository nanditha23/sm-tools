import sys
import datetime
import numpy
import csv
from scipy import sparse, io

start_time = int(6 * 60 * 60)
end_time = int(7 * 60 * 60)
od_interval = int(15 * 60)
sensor_interval = int(5 * 60)

num_interval_od = int((end_time - start_time) / od_interval)
num_interval_sensor = int((end_time - start_time) / sensor_interval)

assignment_matrix = numpy.genfromtxt('SimMobility_SPSA/assignment_matrix.csv', delimiter=',')
od_pair = numpy.genfromtxt('data/TripChain/ODpair.csv', delimiter=" ").astype(int)
ref_sensor = list(csv.reader(open("data/ref_segments_LaneLv5min.csv", "rb"), delimiter=" "))
ref_od = list(csv.reader(open("data/Ref_od_Wmat.csv", "rb"), delimiter=" "))

ref_sensor_dict = dict()
ref_od_dict = dict()

count = 0
for item in ref_sensor:
	ref_sensor_dict[int(item[0])] = count
	count += 1

count = 0
for item in ref_od:
	ref_od_dict[(int(item[0]), int(item[1]))] = count
	count += 1


od_pair = od_pair[:, [1, 2]]

no_od = len(ref_od)
num_sensors = len(ref_sensor)

for item in assignment_matrix:
	item[3] = int(int(item[3])/1000) + start_time
	item[7] = int(int(item[7])/1000) + start_time

wmatrix = sparse.lil_matrix((num_interval_sensor * num_sensors, num_interval_od * no_od))

start_interval_sensor = int(start_time/sensor_interval)
start_interval_od = int(start_time/od_interval)
for item in assignment_matrix:
	if ref_sensor_dict.__contains__(int(item[2])):
		sensor_index = ref_sensor_dict[int(item[2])]
		od_index = ref_od_dict[(int(item[5]), int(item[6]))]
		time_index_sensor = (int((item[3])/sensor_interval)) - start_interval_sensor
		time_index_od = (int((item[7])/od_interval)) - start_interval_od
		row = int(sensor_index) + (int(num_sensors) * int(time_index_sensor))
		col = int(od_index) + (int(no_od) * int(time_index_od))
		print row, col
		wmatrix[row, col] += 1


#io.mmwrite('wmatrix_befTranspose', wmatrix, comment='')

wmatrix = wmatrix.transpose()

#io.mmwrite('wmatrix_AftTranspose', wmatrix, comment='')

row_sums = wmatrix.sum(axis=1)

cx = sparse.coo_matrix(wmatrix)

data_list = list()

for row, col, data in zip(cx.row, cx.col, cx.data):
	val = float(float(data) / float(row_sums[row][0]))
	data_list.append([row, col, val])

with open('data/WMATRIX/wmatrix_SPSA.csv', 'w') as fp:
		writer = csv.writer(fp, delimiter=' ')
		writer.writerows(data_list)


#io.mmwrite('wmatrix', wmatrix, comment='')
