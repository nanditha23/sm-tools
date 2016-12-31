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
        if(name == 'min_response_distance'): # OK
            values = splitValues(child.get('value'), " ")
            values[0] = update_params[0] # Minimum space headway between the lead and following vehicles: Initial (2.5) MITSIM (4.6) A44 (2.5)
            child.set('value', formValueString(values))
        elif(name == 'CF_parameters_1'): # OK
            values = splitValues(child.get('value'), " ")
            values[0] = update_params[1] # alpha: Initial (0.045)
            values[1] = update_params[2] # beta: Initial (0.740)
            values[2] = update_params[3] # gama: Initial (0.205)
            values[3] = update_params[4] # lambda: Initial (0.750)
            values[4] = update_params[5] # rho: Initial (0.494)
            child.set('value', formValueString(values))
        elif (name == 'CF_parameters_2'):
            values = splitValues(child.get('value'), " ")
            values[0] = update_params[6]  # alpha: Initial (-0.40)
            values[1] = update_params[7]  # beta: Initial (0.000)
            values[2] = update_params[8]  # gama: Initial (0.650)
            values[3] = update_params[9]  # lambda: Initial (0.850)
            values[4] = update_params[10]  # rho: Initial (0.605)
            child.set('value', formValueString(values))
        elif (name == 'FF_Acc_Params_b2'):
            values = splitValues(child.get('value'), " ")
            values[0] = update_params[11] # b2: Initial (0.3091) MITSIM (0.3091) A44 (0.296)
            child.set('value', formValueString(values))
        elif (name == 'speed_factor'):
            values = splitValues(child.get('value'), " ")
            values[0] = update_params[12]
            child.set('value', formValueString(values))
        elif (name == 'target_gap_acc_parm'):
            values = splitValues(child.get('value'), " ")
            values[0] = update_params[13] # [1] Desired position FWD, BCK, ADJ: Initial (0.604)
            values[1] = update_params[14]  # Desired position * [2]: Initial (0.385)
            values[2] = update_params[15]  # Desired position ^ [3]: Initial (0.323)
            values[3] = update_params[16]  # [4]: Initial (0.0678)
            values[4] = update_params[17]  # [5]: Initial (0.217)
            values[5] = update_params[18]  # [6]: Initial (0.583)
            values[6] = update_params[19]  # [7]: Initial (-596)
            values[7] = update_params[20]  # [8]: Initial (-0.219)
            values[8] = update_params[21]  # [9]: Initial (0.0832)
            values[9] = update_params[22]  # [10]: Initial (0.170)
            values[10] = update_params[23]  # [11]: Initial (1.478)
            values[11] = update_params[24]  # [12]: Initial (0.131)
            values[12] = update_params[25]  # [13]: Initial (0.300)
            child.set('value', formValueString(values))
        elif (name == 'max_acc_car1'):
            values = splitValues(child.get('value'), " ")
            values[0] = update_params[26]  # Initial (6.0)
            values[1] = update_params[27]  # Initial (5.50)
            values[2] = update_params[28]  # Initial (5.00)
            values[3] = update_params[29]  # Initial (4.50)
            values[4] = update_params[30]  # Initial (4.00)
            child.set('value', formValueString(values))
        elif (name == 'normal_deceleration_car1'):
            values = splitValues(child.get('value'), " ")
            values[0] = update_params[31]  # Initial (-2.5)
            values[1] = update_params[32]  # Initial (-2.25)
            values[2] = update_params[33]  # Initial (-2.00)
            values[3] = update_params[34]  # Initial (-1.75)
            values[4] = update_params[35]  # Initial (-1.50)
            child.set('value', formValueString(values))
        elif (name == 'max_deceleration_car1'):
            values = splitValues(child.get('value'), " ")
            values[0] = update_params[36]  # Initial (-9.00)
            values[1] = update_params[37]  # Initial (-8.50)
            values[2] = update_params[38]  # Initial (-8.00)
            values[3] = update_params[39]  # Initial (-7.50)
            values[4] = update_params[40]  # Initial (-7.00)
            child.set('value', formValueString(values))
        elif (name == 'hbuffer_lower'):
            values = splitValues(child.get('value'), " ")
            values[0] = update_params[41]  # Initial (1.0)
            child.set('value', formValueString(values))
        elif (name == 'hbuffer_Upper'):
            values = splitValues(child.get('value'), " ")
            temp = update_params[47]  # 0.55: Initial (2.60338)
            values[0] = repr(round((float(temp) * 0.71), 4))
            values[1] = repr(round((float(temp) * 0.81), 4))
            values[2] = repr(round((float(temp) * 0.87), 4))
            values[3] = repr(round((float(temp) * 0.91), 4))
            values[4] = repr(round((float(temp) * 0.96), 4))
            values[5] = repr(round((float(temp) * 1.00), 4))
            values[6] = repr(round((float(temp) * 1.04), 4))
            values[7] = repr(round((float(temp) * 1.09), 4))
            values[8] = repr(round((float(temp) * 1.15), 4))
            values[9] = repr(round((float(temp) * 1.25), 4))
            # values[0] = update_params[42]  # 0.05: Initial (1.850875)
            # values[1] = update_params[43]  # 0.15: Initial (2.109445)
            # values[2] = update_params[44]  # 0.25: Initial (2.263295)
            # values[3] = update_params[45]  # 0.35: Initial (2.386205)
            # values[4] = update_params[46]  # 0.45: Initial (2.496535)
            # values[5] = update_params[47]  # 0.55: Initial (2.60338)
            # values[6] = update_params[48]  # 0.65: Initial (2.71371)
            # values[7] = update_params[49]  # 0.75: Initial (2.83662)
            # values[8] = update_params[50]  # 0.85: Initial (2.99047)
            # values[9] = update_params[51]  # 0.95: Initial (3.24904)
            child.set('value', formValueString(values))
        elif (name == 'yellow_stop_headway'):
            values = splitValues(child.get('value'), " ")
            values[0] = update_params[52]  # Initial (1.0)
            child.set('value', formValueString(values))
        elif (name == 'min_speed_yellow'):
            values = splitValues(child.get('value'), " ")
            values[0] = update_params[53]  # Initial (2.2352)
            child.set('value', formValueString(values))
        elif (name == 'driver_signal_perception_distance'):
            values = splitValues(child.get('value'), " ")
            values[0] = update_params[54]  # Initial (150.0)
            child.set('value', formValueString(values))
        elif (name == 'dec_update_step_size' or name == 'stopped_vehicle_update_step_size'):
            values = splitValues(child.get('value'), " ")
            values[0] = update_params[55] # Initial (0.4)
            child.set('value', formValueString(values))
        elif (name == 'acc_update_step_size' or name == 'uniform_speed_update_step_size'):
            values = splitValues(child.get('value'), " ")
            values[0] = update_params[56] # Initial (0.5)
            #values[0] = repr(float(values[56]) * 1.5)
            child.set('value', formValueString(values))
        elif (name == 'MLC_PARAMETERS'):
            values = splitValues(child.get('value'), " ")
            values[0] = update_params[57]  # Initial (750.0)
            values[1] = update_params[58]  # Initial (1000.0)
            values[2] = update_params[59]  # Initial (2.0)
            child.set('value', formValueString(values))
        elif (name == 'lane_utility_model'):
            values = splitValues(child.get('value'), " ")
            values[0] = update_params[60]  # Current lane constant: Initial (4.2656)
            values[1] = update_params[61]  # Right lane constant: Initial (0.3213)
            values[2] = update_params[62]  # Right most lane dummy: Initial (-1.1683)
            values[3] = update_params[63]  # Currently unused: Initial (0.0)
            values[4] = update_params[64]  # Front vehicle speed (all lanes): Initial (0.08)
            values[5] = update_params[65]  # Bus following dummy: Initial (-1.0)
            values[6] = update_params[66]  # Front vehicle spacing: Initial (0.009)
            values[7] = update_params[67]  # Heavy neighbor in lane: Initial (-0.2664)
            values[8] = update_params[68]  # Density in lane: Initial (-0.012)
            values[9] = update_params[69]  # Tailgate: Initial (-3.3754)
            values[10] = update_params[70]  # Gap behind theshold for tailgate dummy (m): Initial (10)
            values[11] = update_params[71]  # Density theshold for tailgate dummy: Initial (19)
            values[12] = update_params[72]  # One lane change required: Initial (-2.3400)
            values[13] = update_params[73]  # Two lane changes required: Initial (-4.5084)
            values[14] = update_params[74]  # Each additional lane change required: Initial (-2.8257)
            values[15] = update_params[75]  # Next exit, one lane change required: Initial (-1.2597)
            values[16] = update_params[76]  # Next exit, each additional lane changes required: Initial (-0.7239)
            values[17] = update_params[77]  # Distance to exit: Initial (-0.3269)
            child.set('value', formValueString(values))
        elif (name == 'critical_gaps_param'):
            values = splitValues(child.get('value'), " ")
            values[0] = update_params[78]  # Initial (0.2)
            values[1] = update_params[79]  # Initial (-0.231)
            values[2] = update_params[80]  # Initial (-2.700)
            values[3] = update_params[81]  # Initial (1.112)
            values[4] = update_params[82]  # Initial (0.5)
            values[5] = update_params[83]  # Initial (0.000)
            values[6] = update_params[84]  # Initial (0.2)
            values[7] = update_params[85]  # Initial (0.742)
            values[8] = update_params[86]  # Initial (6.0)
            child.set('value', formValueString(values))
        elif (name == 'Target_Gap_Model'):
            values = splitValues(child.get('value'), " ")
            values[0] = update_params[87]  # Initial (-0.837)
            values[1] = update_params[88]  # Initial (0.913)
            values[2] = update_params[89]  # Initial (0.816)
            values[3] = update_params[90]  # Initial (-1.218)
            values[4] = update_params[91]  # Initial (-2.393)
            values[5] = update_params[92]  # Initial (-1.662)
            child.set('value', formValueString(values))
        elif (name == 'nosing_param'):
            values = splitValues(child.get('value'), " ")
            values[0] = update_params[93]  # Initial (1.0)
            values[1] = update_params[94]  # Initial (0.5)
            values[2] = update_params[95]  # Initial (0.6)
            values[3] = update_params[96]  # Initial (0.1)
            values[4] = update_params[97]  # Initial (0.5)
            values[5] = update_params[98]  # Initial (1.0)
            values[6] = update_params[99]  # Initial (30.0)
            values[7] = update_params[100]  # Initial (100.0)
            values[8] = update_params[101]  # Initial (600.0)
            values[9] = update_params[102]  # Initial (40.0)
            child.set('value', formValueString(values))
        elif (name == 'CF_CRITICAL_TIMER_RATIO'):
            values = splitValues(child.get('value'), " ")
            values[0] = update_params[103]  # Initial (0.5)
            child.set('value', formValueString(values))
        elif (name == 'intersection_attentiveness_factor_min'):
            values = splitValues(child.get('value'), " ")
            values[0] = update_params[104]  # Initial (0.3)
            child.set('value', formValueString(values))
        elif (name == 'intersection_attentivneess_factor_max'):
            values = splitValues(child.get('value'), " ")
            values[0] = update_params[105]  # Initial (0.6)
            child.set('value', formValueString(values))
        elif (name == 'minimum_gap'):
            values = splitValues(child.get('value'), " ")
            values[0] = update_params[106]  # Initial (1.25)
            child.set('value', formValueString(values))
        elif (name == 'critical_gap_addon'):
            values = splitValues(child.get('value'), " ")
            values[0] = update_params[107]  # Initial (1.0)
            values[1] = update_params[108]  # Initial (0.5)
            child.set('value', formValueString(values))
        elif (name == 'impatience_factor'):
            values = splitValues(child.get('value'), " ")
            values[0] = update_params[109]  # Initial (0.2)
            child.set('value', formValueString(values))
        elif (name == 'LC_Discretionary_Lane_Change_Model_MinTimeInLaneSameDir'):
            values = splitValues(child.get('value'), " ")
            values[0] = update_params[110]  # Initial (7)
            child.set('value', formValueString(values))
        elif (name == 'LC_Discretionary_Lane_Change_Model_MinTimeInLaneDiffDir'):
            values = splitValues(child.get('value'), " ")
            values[0] = update_params[111]  # Initial (15)
            child.set('value', formValueString(values))
    xmlTree.write(sys.argv[1], "UTF-8")
        
if __name__ == "__main__":
    update_params = splitValues(sys.argv[2], ",")
    updateDriverParamsXML()