% Get reputation dynamics with symbolic calculation
% public assessment covering JTB 2004
function [reputation_dym_handle] = get_rep_dym_mut(norm,mutant,mu_e,mu_G,mu_B,h_res)
% Input:
    %   norm:         social norm
    %   mutant:       mutant behavioral strategy
    %   mu_e:         execution error rate
    %   mu_G:         assignment error rate for mistakenly assign a good reputation
    %   mu_B:         assignment error rate for mistakenly assign a bad reputation

% Reputation Dynamics
% define norm_with_error function
    function [D_ijk] = norm_with_error(r0,r1,r2)
        ture_action = mutant(r0 + 1, r1 + r2 + 1);
        D_ijk = (1 - mu_B - mu_G)*((1 - mu_e)*norm(ture_action + 1, 3*r0 + r1 + r2 + 1) + mu_e*norm(1, 3*r0 + r1 + r2 + 1)) + mu_G;
    end

% define reputation_dynamics function
    function[dhdt] = reputation_dynamics(t,h)
        D_G_GG = norm_with_error(1, 1, 1);
        D_G_GB = norm_with_error(1, 1, 0);
        D_G_BB = norm_with_error(1, 0, 0);
        D_B_GG = norm_with_error(0, 1, 1);
        D_B_GB = norm_with_error(0, 1, 0);
        D_B_BB = norm_with_error(0, 0, 0);

        T1 = h_res^2*D_G_GG + 2*h_res*(1 - h_res)*D_G_GB + (1 - h_res)^2*D_G_BB;
        T2 = h_res^2*D_B_GG + 2*h_res*(1 - h_res)*D_B_GB + (1 - h_res)^2*D_B_BB;

        dhdt = h*T1 + (1 - h)*T2 - h;
    end

% return function handle
reputation_dym_handle = @reputation_dynamics;
end