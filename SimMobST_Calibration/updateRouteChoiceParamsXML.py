import sys
import xml.etree.ElementTree as ET

update_params = []

def splitValues(attribute, delimiter):
    valList = attribute.split(delimiter);
    return valList;

def formValueString(values):
    valueStr = ''
    length = len(values)
    for i in range(0, length):
    	if i < length-1:
        	valueStr = valueStr + values[i] + ' ' 
        else:
        	valueStr = valueStr + values[i]
    return valueStr
        
def updateRouteChoiceXML():
    xmlTree = ET.parse(sys.argv[1])
    routeChoice = xmlTree.getroot()

    scale_factor = float(update_params[0])

    for child in routeChoice.findall('private_pathset/utility_parameters/bTTVOT'):
        bTTVOT = scale_factor * float(update_params[1])
        child.set('value',repr(bTTVOT))

    for child in routeChoice.findall('private_pathset/utility_parameters/bCommonFactor'):
       bCommonFactor = scale_factor * float(update_params[2])
       child.set('value', repr(bCommonFactor))

    for child in routeChoice.findall('private_pathset/utility_parameters/bLength'):
        bLength = scale_factor * float(update_params[3])
        child.set('value', repr(bLength))

    for child in routeChoice.findall('private_pathset/utility_parameters/bHighway'):
        bHighway = scale_factor * float(update_params[4])
        child.set('value', repr(bHighway))

    for child in routeChoice.findall('private_pathset/utility_parameters/bSigInter'):
        bSigInter = scale_factor * float(update_params[5])
        child.set('value', repr(bSigInter))

    for child in routeChoice.findall('private_pathset/utility_parameters/highwayBias'):
        highwayBias = scale_factor * float(update_params[6])
        child.set('value', repr(highwayBias))

    for child in routeChoice.findall('private_pathset/utility_parameters/minTravelTimeParam'):
        minTravelTimeParam = scale_factor * float(update_params[7])
        child.set('value', repr(minTravelTimeParam))

    for child in routeChoice.findall('private_pathset/utility_parameters/minDistanceParam'):
        minDistanceParam = scale_factor * float(update_params[8])
        child.set('value', repr(minDistanceParam))

    for child in routeChoice.findall('private_pathset/utility_parameters/minSignalParam'):
        minSignalParam = scale_factor * float(update_params[9])
        child.set('value', repr(minSignalParam))

    for child in routeChoice.findall('private_pathset/utility_parameters/maxHighwayParam'):
        maxHighwayParam = scale_factor * float(update_params[10])
        child.set('value', repr(maxHighwayParam))

    xmlTree.write(sys.argv[1], "UTF-8")
        
if __name__ == "__main__":
    update_params = splitValues(sys.argv[2], ",")
    updateRouteChoiceXML()
