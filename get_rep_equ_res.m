% Get reputation equilibrium of resident
% public assessment covering JTB 2004
function [rep_equ] = get_rep_equ_res(norm,resident,mu_e,mu_G,mu_B)
% Input:
    %   norm:         social norm
    %   resident:     resident behavioral strategy
    %   mu_e:         execution error rate
    %   mu_G:         assignment error rate for mistakenly assign a good reputation
    %   mu_B:         assignment error rate for mistakenly assign a bad reputation

% initiate storage
rep_equ = [];
    
% get reputation dynamics
reputation_dynamics = get_rep_dym_res(norm,resident,mu_e,mu_G,mu_B);
 
% init symbolic variable
syms h

% Assuming t = 0 as it's not needed for finding equilibrium
dhdt = reputation_dynamics(0, h);

% Solve dhdt = 0 to find possible equilibrium points
possible_equ = solve(dhdt == 0, h);

try
    possible_equ_vals = double(possible_equ);
catch
    possible_equ_vals = [];
end

% Used to determine local stability of equilibria
d_dhdt = diff(dhdt, h);

for i = 1:length(possible_equ_vals)
    candidate = possible_equ_vals(i);
    if ~isreal(candidate)
        continue;
    end
    % Restrict to physically meaningful range [0,1]
    if candidate < 0 || candidate > 1
        continue;
    end

    % Evaluate the slope of dh/dt at the candidate equilibrium
    % A negative slope indicates local asymptotic stability
    try
        slope = double(subs(d_dhdt, h, candidate));
    catch
        continue;
    end

    % Retain only strictly stable equilibria (exclude unstable and semi-stable)
    if slope >= 0
        continue;
    end

    % Remove numerically duplicated equilibria
    if isempty(rep_equ)
        rep_equ = [rep_equ; candidate];
    else
        if all(abs(rep_equ - candidate) > 1e-6)
            rep_equ = [rep_equ; candidate];
        end
    end
end

rep_equ = sort(rep_equ,'descend');
end