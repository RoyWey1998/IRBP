function [rep_equ] = get_rep_equ_mut_n4(norm, mutant, mu_e, mu_G, mu_B, h_res)
% Get reputation equilibrium of the mutant strategy
% Public assessment covering JTB 2004
% Input:
%   norm:      social norm
%   mutant:    mutant behavioral strategy
%   mu_e:      execution error rate
%   mu_G:      assignment error rate for mistakenly assigning a good reputation
%   mu_B:      assignment error rate for mistakenly assigning a bad reputation

% Initialize storage
rep_equ = [];

% Get reputation dynamics
reputation_dynamics = get_rep_dym_mut_n4(norm, mutant, mu_e, mu_G, mu_B, h_res);

% Initialize symbolic variable
syms h

% Evaluate the dynamics at t = 0, since time does not affect the equilibrium equation
dhdt = reputation_dynamics(0, h);

% Solve dh/dt = 0 to find possible equilibrium points
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

rep_equ = sort(rep_equ, 'descend');
end