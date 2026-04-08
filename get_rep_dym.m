function [reputation_dym_handle] = get_rep_dym(norm, strategy, mu_e, mu_G, mu_B)
% Get reputation dynamics with symbolic calculation
% Public assessment covering JTB 2004
% Input:
%   norm:      social norm matrix
%   strategy:  behavioral strategy matrix
%   mu_e:      execution error rate
%   mu_G:      assignment error rate for mistakenly assigning a good reputation
%   mu_B:      assignment error rate for mistakenly assigning a bad reputation

% Define norm_with_error function
    function [D_ijk] = norm_with_error(r0, r1, r2)
        true_action = strategy(r0 + 1, r1 + r2 + 1);
        D_ijk = (1 - mu_B - mu_G) * ( ...
            (1 - mu_e) * norm(true_action + 1, 3 * r0 + r1 + r2 + 1) ...
            + mu_e * norm(1, 3 * r0 + r1 + r2 + 1)) + mu_G;
    end

% Define reputation_dynamics function
    function [dhdt] = reputation_dynamics(t, h)
        D_G_GG = norm_with_error(1, 1, 1);
        D_G_GB = norm_with_error(1, 1, 0);
        D_G_BB = norm_with_error(1, 0, 0);
        D_B_GG = norm_with_error(0, 1, 1);
        D_B_GB = norm_with_error(0, 1, 0);
        D_B_BB = norm_with_error(0, 0, 0);

        T1 = h^2 * D_G_GG + 2 * h * (1 - h) * D_G_GB + (1 - h)^2 * D_G_BB;
        T2 = h^2 * D_B_GG + 2 * h * (1 - h) * D_B_GB + (1 - h)^2 * D_B_BB;

        dhdt = h * T1 + (1 - h) * T2 - h;
    end

% Return function handle
reputation_dym_handle = @reputation_dynamics;
end