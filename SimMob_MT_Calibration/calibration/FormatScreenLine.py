import csv
import collections

vehicleName = {'Car': 'Car', 'M/Cycle': 'Motorcycle', 'Public Bus': 'Bus', 'Taxi': 'Taxi', 'Private Bus': 'Private Bus',
				'LGV': 'LGV', 'HGV': 'HGV', 'Others': 'Others'}

toBeSkipped = {'Bus Total', 'Total'}

screenLineCounts = list(csv.reader(open("data/Screen_Line_Calibration.csv", "rb"), delimiter=","))
screenLineToSiteIDMap = list(csv.reader(open("data/segmentMapping.csv", "rb"), delimiter=";"))

screenLineDict = collections.defaultdict()

for item in screenLineToSiteIDMap:
	screenLineDict[item[1]] = item[0]


def get_interval_string(interval):
		time = str(interval)
		return (int(time[0:2])*60+int(time[2:4]))/30


screenLineOutput = list()
for screenLineCount in screenLineCounts:
	if screenLineCount[0] in screenLineDict and screenLineCount[1] not in toBeSkipped:
		screenLineSegment = screenLineDict.__getitem__(screenLineCount[0])
		vehName = vehicleName.__getitem__(screenLineCount[1])
		interval=screenLineCount[3]
		intervalSlot=get_interval_string(interval)
		screenLineItem = list()
		screenLineItem.append(screenLineSegment)
		screenLineItem.append(intervalSlot)
		screenLineItem.append(vehName)
		screenLineItem.append(screenLineCount[2])
		screenLineOutput.append(screenLineItem)

with open('data/screen_line_count_real.csv', 'w') as fp:
		writer = csv.writer(fp, delimiter=',', lineterminator='\n')
		writer.writerows(screenLineOutput)

