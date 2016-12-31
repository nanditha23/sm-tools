function [driverParams, routechoiceParams] = readDriverParam()
    root = xmlread('SimMobility/data/driver_behavior_model/driver_param.xml');
    allDriverParams = root.getElementsByTagName('param');
    
    driverParams = zeros(10,1);
    
    for i = 0:allDriverParams.getLength-1
        param = allDriverParams.item(i);
        name = param.getAttribute('name');
        if strcmp(char(name), 'dec_update_step_size')
            [values, ~] = strsplit(char(param.getAttribute('value')));
            driverParams(1) = str2double(values{1,1});
        end
        if strcmp(char(name), 'CF_parameters_1')
            [values, ~] = strsplit(char(param.getAttribute('value')));
            driverParams(2) = str2double(values{1, 1});
            driverParams(3) = str2double(values{1, 2});
        end
        if strcmp(char(name), 'CF_parameters_2')
            [values, ~] = strsplit(char(param.getAttribute('value')));
            driverParams(4) = str2double(values{1,1});
            driverParams(5) = str2double(values{1,3});
            driverParams(6) = str2double(values{1,5});
        end
        %if strcmp(char(name), 'hbuffer_Upper')
        %    [values, ~] = strsplit(char(param.getAttribute('value')));
        %    driverParams(7) = str2double(values{1,1});
        %end
        if strcmp(char(name), 'speed_factor')
            [values, ~] = strsplit(char(param.getAttribute('value')));
            driverParams(7) = str2double(values{1,1});
        end
        if strcmp(char(name), 'lane_utility_model')
            [values, ~] = strsplit(char(param.getAttribute('value')));
            driverParams(8) = str2double(values{1,1});
            driverParams(9) = str2double(values{1,13});
            driverParams(10) = str2double(values{1,18});
        end
    end
    
    routechoiceParams = zeros(10, 1);

    root = xmlread('SimMobility/data/pathset_config.xml');
    
    bTTVOTParam = root.getElementsByTagName('bTTVOT');
    for i = 0:bTTVOTParam.getLength-1
        param = bTTVOTParam.item(i);
        routechoiceParams(1) = str2double(param.getAttribute('value'));
    end

    bCommonFactorParam = root.getElementsByTagName('bCommonFactor');
    for i = 0:bCommonFactorParam.getLength-1
        param = bCommonFactorParam.item(i);
        routechoiceParams(2) = str2double(param.getAttribute('value'));
    end

    bLengthParam = root.getElementsByTagName('bLength');
    for i = 0:bLengthParam.getLength-1
        param = bLengthParam.item(i);
        routechoiceParams(3) = str2double(param.getAttribute('value'));
    end

    bHighwayParam = root.getElementsByTagName('bHighway');
    for i = 0:bHighwayParam.getLength-1
        param = bHighwayParam.item(i);
        routechoiceParams(4) = str2double(param.getAttribute('value'));
    end

    bSigInterParam = root.getElementsByTagName('bSigInter');
    for i = 0:bSigInterParam.getLength-1
        param = bSigInterParam.item(i);
        routechoiceParams(5) = str2double(param.getAttribute('value'));
    end

    highwayBiasParam = root.getElementsByTagName('highwayBias');
    for i = 0:highwayBiasParam.getLength-1
        param = highwayBiasParam.item(i);
        routechoiceParams(6) = str2double(param.getAttribute('value'));
    end

    minTravelTimeParam = root.getElementsByTagName('minTravelTimeParam');
    for i = 0:minTravelTimeParam.getLength-1
        param = minTravelTimeParam.item(i);
        routechoiceParams(7) = str2double(param.getAttribute('value'));
    end

    minDistanceParam = root.getElementsByTagName('minDistanceParam');
    for i = 0:minDistanceParam.getLength-1
        param = minDistanceParam.item(i);
        routechoiceParams(8) = str2double(param.getAttribute('value'));
    end

    minSignalParam = root.getElementsByTagName('minSignalParam');
    for i = 0:minSignalParam.getLength-1
        param = minSignalParam.item(i);
        routechoiceParams(9) = str2double(param.getAttribute('value'));
    end

    maxHighwayParam = root.getElementsByTagName('maxHighwayParam');
    for i = 0:maxHighwayParam.getLength-1
        param = maxHighwayParam.item(i);
        routechoiceParams(10) = str2double(param.getAttribute('value'));
    end
    
    
    