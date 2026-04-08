function [bistab_flag, rep_equ_list] = bistability_check_n4(norm, strategy, mu_G, mu_B)
% Check bistability for a given social norm and behavioral strategy

arguments
    norm double
    strategy double
    mu_G double
    mu_B double
end

% Initialize
bistab_flag = 0;
mu_E = 0:0.001:1.0;
num_mu = numel(mu_E);
rep_equ_list = cell(num_mu, 1);

% Get reputation equilibrium
if numel(mu_G) > 1
    for i = 1:num_mu
        res = get_rep_equ_res_n4(norm, strategy, mu_E(i), mu_G(i), mu_B(i));
        rep_equ_list{i} = res(:);

        % Check for bistability
        if numel(res) == 3
            bistab_flag = 1;
        end
    end
else
    for i = 1:num_mu
        res = get_rep_equ_res_n4(norm, strategy, mu_E(i), mu_G, mu_B);
        rep_equ_list{i} = res(:);

        % Check for bistability
        if numel(res) >= 3
            bistab_flag = 1;
        end
    end
end

end