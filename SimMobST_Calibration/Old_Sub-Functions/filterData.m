function [realVal, loopVal, diffArray] = filterData(realData,loopData)
    realVal = [];
    loopVal = [];
    diffArray = [];
    count = 1;
    for i = 1:length(loopData)
        for j = 1:length(realData)
            if str2num(realData{j,1}) == loopData(i,1) && ...
                    str2num(realData{j,2}) == loopData(i,2)
                realDataVal = str2num(realData{j,3});
                realVal = [realVal realDataVal];
                loopVal = [loopVal loopData(i,3)];
                diffArray(count, 1) = loopData(i,1);
                diffArray(count, 2) = loopData(i,2);
                diffArray(count, 3) = abs(realDataVal - loopData(i,3));
                count = count + 1;
                break;
            end
        end
    end