function r = RMSE(Yo, Ys)
    % 
    % Mean Error Normalized 
    Yo=Yo(:); 
    Ys=Ys(:);
    N = length(Yo);
    r = sqrt(sum((Ys-Yo).^2)/ N);
end



