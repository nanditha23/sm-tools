function realData = readAllCountsIntersection(date, startTime, endTime, fileName)
    fileData = importdata(fileName);
    
    [dates, ~] = strsplit(char(date), '/');

    aux = fileData.data(1:end, 2:end);
    vehCounts = nansum(aux.*(aux<2046 | aux>2047), 2);
    
    endtime = convertToMS(startTime, endTime);
        
    count = 1;
    for i = 1:length(fileData.data)
        [currTime,~] = strsplit(char(fileData.textdata(i,4)), ':');
        if length(currTime) < 2
            continue;
        end
        currTime = convertToMS(startTime, fileData.textdata(i,4));
        if str2num(fileData.textdata{i,1}) == str2num(dates{1,1}) && ...
            str2num(fileData.textdata{i,2}) == str2num(dates{1,2}) && ...
            str2num(fileData.textdata{i,3}) == str2num(dates{1,3}) && ...
            currTime >= 0 && currTime <= endtime
            realData(count, 1) = currTime+300000;
            realData(count, 2) = fileData.data(i, 1);
            realData(count, 3) = vehCounts(i, 1);
            count = count + 1;
        end
    end  
    