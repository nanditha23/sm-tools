function r = RMSNW(wmatrix, j, N_sensor, y_true, y_hat)
    %j=1
    %y_true =truecount
    %y_hat =simcountminus
    n = length(y_true);
    ydiff=y_true(:)-y_hat(:);
    ydiff_wsum=wmatrix(j,1:(N_sensor))*(ydiff.^2);
    r = sqrt(ydiff_wsum*n)/sum(y_true);
    
end