function loopData = readLoopData(fileName)
    fileData = importdata(fileName);

    lastSensorID = 0;
    lastInterval = 0;
    loopDataCount = 0;
    for i = 1:length(fileData)
        if lastSensorID == 0 || lastSensorID ~= fileData(i, 2) || lastInterval ~= fileData(i, 1)
            loopDataCount = loopDataCount + 1;
            lastSensorID = fileData(i, 2);
            lastInterval = fileData(i, 1);
            loopData(loopDataCount, 1) = fileData(i, 1);
            loopData(loopDataCount, 2) = fileData(i, 2);
            loopData(loopDataCount, 3) = fileData(i, 5);
        else
            loopData(loopDataCount, 3) = loopData(loopDataCount, 3) + fileData(i, 5);
        end
    end    