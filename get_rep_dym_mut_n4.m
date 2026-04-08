function [reputation_dym_handle] = get_rep_dym_mut_n4(norm, mutant, mu_e, mu_G, mu_B, h_res)
% Get reputation dynamics with symbolic calculation
% Public assessment covering JTB 2004
% Input:
%   norm:      social norm
%   mutant:    mutant behavioral strategy
%   mu_e:      execution error rate
%   mu_G:      assignment error rate for mistakenly assigning a good reputation
%   mu_B:      assignment error rate for mistakenly assigning a bad reputation

% Define the norm_with_error function
    function [D_ijk] = norm_with_error(r0, rc)
        true_action = mutant(r0 + 1, rc + 1);
        D_ijk = (1 - mu_B - mu_G) * ( ...
            (1 - mu_e) * norm(true_action + 1, 4 * r0 + rc + 1) ...
            + mu_e * norm(1, 4 * r0 + rc + 1)) + mu_G;
    end

% Define the reputation_dynamics function
    function [dhdt] = reputation_dynamics(t, h)
        D_G_3G = norm_with_error(1, 3);
        D_G_2G = norm_with_error(1, 2);
        D_G_1G = norm_with_error(1, 1);
        D_G_0G = norm_with_error(1, 0);
        D_B_3G = norm_with_error(0, 3);
        D_B_2G = norm_with_error(0, 2);
        D_B_1G = norm_with_error(0, 1);
        D_B_0G = norm_with_error(0, 0);

        T1 = h_res^3 * D_G_3G + 3 * h_res^2 * (1 - h_res) * D_G_2G + 3 * h_res * (1 - h_res)^2 * D_G_1G + (1 - h_res)^3 * D_G_0G;
        T2 = h_res^3 * D_B_3G + 3 * h_res^2 * (1 - h_res) * D_B_2G + 3 * h_res * (1 - h_res)^2 * D_B_1G + (1 - h_res)^3 * D_B_0G;

        dhdt = h * T1 + (1 - h) * T2 - h;
    end

% Return function handle
reputation_dym_handle = @reputation_dynamics;
end