function [rep_equ] = get_rep_equ_res_n4(norm, resident, mu_e, mu_G, mu_B)
% Get reputation equilibrium of the resident strategy
% Public assessment covering JTB 2004
% Input:
%   norm:      social norm
%   resident:  resident behavioral strategy
%   mu_e:      execution error rate
%   mu_G:      assignment error rate for mistakenly assigning a good reputation
%   mu_B:      assignment error rate for mistakenly assigning a bad reputation

% Initialize storage
rep_equ = [];

% Get reputation dynamics
reputation_dynamics = get_rep_dym_res_n4(norm, resident, mu_e, mu_G, mu_B);

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

% Used to determine local stability of equilibria
d_dhdt = diff(dhdt, h);

for i = 1:length(possible_equ_vals)
    candidate = possible_equ_vals(i);
    if ~isreal(candidate)
        continue;
    end

    % Restrict to the physically meaningful range [0, 1]
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

    % Retain only strictly stable equilibria
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

rep_equ = sort(rep_equ, 'descend');
end