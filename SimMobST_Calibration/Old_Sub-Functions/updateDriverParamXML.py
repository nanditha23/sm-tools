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
        
def updateDriverParamsXML():
    xmlTree = ET.parse(sys.argv[1])
    driverParams = xmlTree.getroot()  
    for child in driverParams.findall('param'):
        name = child.get('name')
        if(name == 'dec_update_step_size' or name == 'stopped_vehicle_update_step_size'):
            values = splitValues(child.get('value'), " ")
            values[0] = update_params[0]
            child.set('value', formValueString(values))
        elif(name == 'acc_update_step_size' or name == 'uniform_speed_update_step_size'):
            values = splitValues(child.get('value'), " ")
            values[0] = update_params[0]
            values[0] = repr(float(values[0])*1.5)
            child.set('value', formValueString(values))
        elif(name == 'CF_parameters_1'):
            values = splitValues(child.get('value'), " ")
            values[0] = update_params[1]
            values[1] = update_params[2]
            child.set('value', formValueString(values))
        elif(name == 'CF_parameters_2'):
            values = splitValues(child.get('value'), " ")
            values[0] = update_params[3]
            values[2] = update_params[4]
            values[4] = update_params[5]
            child.set('value', formValueString(values))
        elif(name == 'hbuffer_Upper'):
            values = splitValues(child.get('value'), " ")
            
        elif(name == 'speed_factor'):
            values = splitValues(child.get('value'), " ")
            values[0] = update_params[6]
            child.set('value', formValueString(values))
        elif(name == 'lane_utility_model'):
            values = splitValues(child.get('value'), " ")
            values[0] = update_params[7]
            values[12] = update_params[8]
            values[17] = update_params[9]
            child.set('value', formValueString(values))      
    xmlTree.write(sys.argv[1], "UTF-8")
        
if __name__ == "__main__":
    update_params = splitValues(sys.argv[2], ",")
    updateDriverParamsXML()