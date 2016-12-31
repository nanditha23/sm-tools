function []=runSimMobility() 
    fprintf('\nRunning SimMobility From MATLAB\n');
    %driverParams = readDriverParam();
    
    realData = readAllCountsIntersection('01/08/2010', '06:00', '06:30', 'intersection_01_08_10.txt');
    
    cd ('SimMobility')
    system('./runApplication.sh ./Release/SimMobility_Short data/simulation.xml data/simrun_ShortTerm.xml');
    
    loopData = readLoopData('VehicleCounts.csv');

    [realVal, loopVal, diffArray] = filterData(realData, loopData);
    
    csvwrite('Sensor_Diff.csv', diffArray);
    
    rmsn = RMSN(realVal, loopVal);
    
    disp(rmsn);
    
%     updateParams = '';    
%     for i = 1:size(driverParams)
%         driverParams(i) = driverParams(i) + 0.05;
%         updateParams = strcat(updateParams, num2str(driverParams(i)));
%         updateParams = strcat(updateParams, ',');
%     end
%     
%     command = 'python scripts/updateDriverParamXML.py';
%     command = sprintf('%s %s %s %s', './runApplication.sh', command, 'scripts/data/driver_param.xml', updateParams);
%     system(command);
%     
%     command = 'python scripts/updatePathsetConfig.py';
%     command = sprintf('%s %s %s %s', './runApplication.sh', command, 'scripts/data/pathset_config.xml', '1.0');
%     system(command);
%     
%     system('./runApplication.sh ./Release/SimMobility_Short data/simulation.xml data/simrun_ShortTerm.xml');