% Get reputation equilibrium of mutant
% public assessment covering JTB 2004
function [rep_equ] = get_rep_equ_mut(norm,mutant,mu_e,mu_G,mu_B,h_res)
% Input:
    %   norm:         social norm
    %   mutant:     mutant behavioral strategy
    %   mu_e:         execution error rate
    %   mu_G:         assignment error rate for mistakenly assign a good reputation
    %   mu_B:         assignment error rate for mistakenly assign a bad reputation
    % initiate storage
rep_equ = [];
    
% get reputation dynamics
reputation_dynamics = get_rep_dym_mut(norm,mutant,mu_e,mu_G,mu_B,h_res);
 
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

for i = 1:length(possible_equ_vals)
    candidate = possible_equ_vals(i);
    if ~isreal(candidate)
        continue;
    end
    if candidate >= 0 && candidate <= 1
        if isempty(rep_equ)
            rep_equ = [rep_equ; candidate];
        else
            if all(abs(rep_equ - candidate) > 1e-5)
                rep_equ = [rep_equ; candidate];
            end
        end
    end
end

rep_equ = sort(rep_equ,'descend');
end