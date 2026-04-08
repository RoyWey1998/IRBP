function [ESS] = get_ESS_linear(norms, residents, mutants, mu_e, mu_G, mu_B, R, cate_idx)
% Get ESS (d,p) pairs under linear payoff

% Initialize ESS storage as a structure
ESS = struct();

% Get the numbers of norms and strategies
fields_norm = fieldnames(norms);
fields_resident = fieldnames(residents);
fields_mutant = fieldnames(mutants);
num_norm = length(fields_norm);
num_resident = length(fields_resident);
num_mutant = length(fields_mutant);

% Fix a social norm
for idx_norm = 1:num_norm
    if mod(idx_norm, 64) == 1
        note = "norm_" + cate_idx + " idx_norm=" + num2str(idx_norm);
        disp(note);
    end

    % Get norm
    normID = fields_norm{idx_norm};
    norm = norms.(normID);

    for idx_resident = 1:num_resident
        % Get resident strategy
        residentID = fields_resident{idx_resident};
        resident = residents.(residentID);

        % Get reputation equilibrium of the resident strategy
        rep_equ = get_rep_equ_res(norm, resident, mu_e, mu_G, mu_B);
        h_res = max(rep_equ);

        % Cooperation rate of the resident
        theta_p_pp = resident(2,3) * h_res^3 + 2 * resident(2,2) * h_res^2 * (1 - h_res) + ...
            resident(2,1) * h_res * (1 - h_res)^2 + resident(1,3) * h_res^2 * (1 - h_res) + ...
            2 * resident(1,2) * h_res * (1 - h_res)^2 + resident(1,1) * (1 - h_res)^3;

        % Expected payoff of a resident player
        w_res = theta_p_pp * (R - 1);

        ESS_flag = 1;
        idx_mutant = 0;

        while ESS_flag == 1 && idx_mutant < num_mutant
            idx_mutant = idx_mutant + 1;

            % Get mutant strategy
            mutantID = fields_mutant{idx_mutant};
            mutant = mutants.(mutantID);

            % Skip if the mutant is identical to the resident strategy
            if isequal(mutant, resident)
                continue
            end

            % Get reputation equilibrium of the mutant strategy
            h_mut = get_rep_equ_mut(norm, mutant, mu_e, mu_G, mu_B, h_res);

            % Mutant's cooperation rate and resident's cooperation rate against the mutant
            theta_m_pp = mutant(2,3) * h_res^2 * h_mut + 2 * mutant(2,2) * h_res * (1 - h_res) * h_mut + ...
                mutant(2,1) * (1 - h_res)^2 * h_mut + mutant(1,3) * h_res^2 * (1 - h_mut) + ...
                2 * mutant(1,2) * h_res * (1 - h_res) * (1 - h_mut) + mutant(1,1) * (1 - h_res)^2 * (1 - h_mut);

            theta_p_mp = resident(2,3) * h_res^2 * h_mut + resident(2,2) * h_res * ((1 - h_res) * h_mut + h_res * (1 - h_mut)) + ...
                resident(2,1) * h_res * (1 - h_res) * (1 - h_mut) + resident(1,3) * h_res * (1 - h_res) * h_mut + ...
                resident(1,2) * (1 - h_res) * ((1 - h_res) * h_mut + h_res * (1 - h_mut)) + resident(1,1) * (1 - h_res)^2 * (1 - h_mut);

            % Expected payoff of a mutant player
            w_mut = theta_m_pp * (R / 3 - 1) + theta_p_mp * 2 * R / 3;

            if w_mut >= w_res
                ESS_flag = 0;
            end
        end

        % Determine whether it is an ESS strategy
        if ESS_flag == 1
            ESS_pair = {norm, resident, theta_p_pp};
            pairname = string(normID) + "_" + string(residentID);
            ESS.(pairname) = ESS_pair;
        end
    end
end

end