function ms = convertToMS(startTime, currTime)
    [startTime,~] = strsplit(char(startTime), ':');
    [currTime,~] = strsplit(char(currTime), ':');
    
    hours = str2num(currTime{1,1}) - str2num(startTime{1,1});
    
    curr_mins = str2num(currTime{1,2});
    start_mins = str2num(startTime{1,2});
    mins = curr_mins - start_mins;
    
    if start_mins > curr_mins
        hours = hours - 1;
        mins = start_mins - curr_mins;
    end
        
    ms = (hours * 60 * 60 * 1000) + (mins * 60 * 1000);
    
    