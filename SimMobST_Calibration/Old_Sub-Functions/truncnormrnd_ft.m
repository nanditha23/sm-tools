truncnormrnd(N,mu,sig,xlo,xhi)

h=[2.1775	2.4817	2.6627	2.8073	2.9371	3.0628	3.1926	3.3372	3.5182	3.8224]

% Input
    avg_h=mean(h)
    std_h=std(h)    
    h_ub = max(h)+(max(h) * 0.05) oo%= avg_h+z*(std_h/10)
    h_lb = min(h)-(min(h) * 0.05) %=avg_h-z*(std_h/10)

% Setting for h update
    n=length(h)
    z=2.58 % z-value
    
% Setting for h update
    temp=truncnormrnd([100,1], mean(h), std(h),  h_lb,  h_ub)
    hh_update = [prctile(temp, 5), prctile(temp, 15), prctile(temp, 25), prctile(temp, 35), prctile(temp, 45) prctile(temp, 55), prctile(temp, 65), prctile(temp, 75), prctile(temp, 85), prctile(temp, 95)]

    


