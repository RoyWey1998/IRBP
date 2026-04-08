% tool_code_n4.m
% Utility scripts for generating and analyzing four-player results used in this study.

%% 1 generate social norms and strategies
%% 1.1 generate social norms (once)
norms = struct();

% Iterate through all 65536 possible combinations
for num = 0:2^16 - 1
    % Get a 16-bit binary string
    binStr = dec2bin(num, 16);

    % Convert the binary string to a numerical array
    bits = binStr - '0';

    % Convert bits to a 2x8 matrix
    % Order: d_D_B_0G, d_D_B_1G, d_D_B_2G, d_D_B_3G, d_D_G_0G, d_D_G_1G, d_D_G_2G, d_D_G_3G
    %        d_C_B_0G, d_C_B_1G, d_C_B_2G, d_C_B_3G, d_C_G_0G, d_C_G_1G, d_C_G_2G, d_C_G_3G
    mat = zeros(2, 8);
    mat(1, :) = bits(1:8);
    mat(2, :) = bits(9:16);

    % Create a variable name, e.g. 'norm_0010011100001010'
    varName = ['norm_' binStr];

    % Store the matrix in the structure with the corresponding field name
    norms.(varName) = mat;
end

% Save to a .mat file
filename = 'social norm_n4.mat';
save(filename, 'norms');

%% 1.2 generate behavioral strategies (once)
strategies = struct();

% Iterate through all 256 possible combinations
for num = 0:2^8 - 1
    % Get an 8-bit binary string
    binStr = dec2bin(num, 8);

    % Convert the binary string to a numerical array
    bits = binStr - '0';

    % Convert bits to a 2x4 matrix
    % Order: p_B_0G, p_B_1G, p_B_2G, p_B_3G
    %        p_G_0G, p_G_1G, p_G_2G, p_G_3G
    mat = zeros(2, 4);
    mat(1, :) = bits(1:4);
    mat(2, :) = bits(5:8);

    % Create a variable name, e.g. 'resident_00101011'
    varName = ['resident_' binStr];

    % Store the matrix in the structure with the corresponding field name
    strategies.(varName) = mat;
end

% Save to a .mat file
filename = 'behavior strategy_n4.mat';
save(filename, 'strategies');

%% 2 get ESS pairs for n = 4, linear PGG
R = 1.1;
mu_e = 0.02;
mu_G = 0.02;
mu_B = 0.02;

resultDir = strcat('ESS_n4_linear_R=', num2str(R), ...
    '_mu_e=', num2str(mu_e), ...
    '_mu_G=', num2str(mu_G), ...
    '_mu_B=', num2str(mu_B));

if ~exist(resultDir, 'dir')
    mkdir(resultDir);
end

%% 2.1 split norms into parallel jobs and search for ESS pairs
tic

% Load social norms and behavioral strategies
load('social norm_n4.mat');
load('behavior strategy_n4.mat');

% Divide norms into sub-structs for parallel computing
fields = fieldnames(norms);

% Initialize categories
cat_num = 5;
nums = 0:2^cat_num - 1;
categories = string(dec2bin(nums, cat_num));

% Set up parallel computing
corenum = length(categories);
par = parpool('local', corenum);

parfor i = 1:length(categories)
    % Find all fields belonging to the current category
    prefix = "norm_" + categories(i);
    filteredFields = fields(startsWith(fields, prefix));

    % Save them into a new struct
    cate_norms = struct();
    for j = 1:length(filteredFields)
        fieldName = filteredFields{j};
        cate_norms.(fieldName) = norms.(fieldName);
    end

    % Since ALLD is always stable, omit it from the resident strategy set
    strategies_noALLD = rmfield(strategies, 'resident_00000000');

    % Get ESS pairs
    ESS = get_ESS_linear_n4(cate_norms, strategies_noALLD, strategies, ...
        mu_e, mu_G, mu_B, R, categories(i));

    % Save results
    filename = fullfile(resultDir, strcat(prefix, ' ESS_pairs.mat'));
    parsave_ESS(filename, ESS);
end

delete(par);
toc

%% 2.2 combine ESS results
files = dir(fullfile(resultDir, 'norm_*.mat'));

% Initialize
combined_ESS = struct();

for i = 1:length(files)
    % Load .mat files
    data = load(fullfile(files(i).folder, files(i).name));

    % Check for ESS
    if isfield(data, 'ESS')
        current_ESS = data.ESS;
        flds = fieldnames(current_ESS);
        for j = 1:length(flds)
            fld = flds{j};
            combined_ESS.(fld) = current_ESS.(fld);
        end
    end
end

filename = fullfile(resultDir, 'combined_ESSpairs_n4.mat');
save(filename, 'combined_ESS');

%% 2.3 sort ESS pairs by relative payoff
% Load data
filename = fullfile(resultDir, 'combined_ESSpairs_n4.mat');
load(filename);

% Sort ESS pairs according to relative payoff
refinedFields = fieldnames(combined_ESS);
values = zeros(length(refinedFields), 1);
for i = 1:length(refinedFields)
    curCell = combined_ESS.(refinedFields{i});
    values(i) = curCell{end};
end
[~, sortIdx] = sort(values, 'descend');

% Get sorted ESS pairs
sorted_ESS = struct();
for i = 1:length(sortIdx)
    sortedFieldName = refinedFields{sortIdx(i)};
    sorted_ESS.(sortedFieldName) = combined_ESS.(sortedFieldName);
end

% Save data
save(filename, 'combined_ESS', 'sorted_ESS');

%% 2.4 check for mirror symmetry in ESS collections
filename = fullfile(resultDir, 'combined_ESSpairs_n4.mat');
load(filename);
ESS = sorted_ESS;

allNames = fieldnames(ESS);
missingNames = {};

for i = 1:numel(allNames)
    name = allNames{i};

    % Extract the 16-bit norm string and 8-bit resident string
    parts    = split(name, {'norm_', '_resident_'});
    normBits = parts{2};
    resBits  = parts{3};

    % Generate the mirror field name
    mirrorName = get_mirror_ESSpair_n4(normBits, resBits);

    % If the mirror is not present, record the original
    if ~isfield(ESS, mirrorName)
        missingNames{end + 1} = name; %#ok<SAGROW>
    end
end

% Build a new struct containing only the originals without mirrors
if ~isempty(missingNames)
    ESS_missing = struct();
    for k = 1:numel(missingNames)
        fld = missingNames{k};
        ESS_missing.(fld) = ESS.(fld);
    end
    fprintf('%d fields lack a mirror counterpart.\n', numel(missingNames));
else
    fprintf('All fields have their mirror counterparts present.\n');
end

%% 2.5 prune ESS collection by deleting mirror-symmetric pairs
% Rule:
% For each pair of mirror-symmetric fields, keep only one representative
% according to the ordered bit-comparison rules below.
% If a field has no mirror counterpart, keep it unconditionally.

filename = fullfile(resultDir, 'combined_ESSpairs_n4.mat');
load(filename);

allNames = fieldnames(sorted_ESS);
numNames = numel(allNames);
processed = false(numNames, 1);
keepNames = {};

for i = 1:numNames
    if processed(i)
        continue;
    end

    name = allNames{i};

    % Split the field name into normBits (16-bit) and resBits (8-bit)
    parts    = split(name, {'norm_', '_resident_'});
    normBits = parts{2};
    resBits  = parts{3};

    % Generate the mirror field name
    mirrorName = get_mirror_ESSpair_n4(normBits, resBits);

    % Find the index of the mirror field in allNames
    j = find(strcmp(allNames, mirrorName), 1);

    if isempty(j)
        % No mirror exists, so keep this field
        keepNames{end + 1} = name; %#ok<SAGROW>
        processed(i) = true;
    else
        % Mirror found and neither has been processed yet
        if ~processed(j)
            % Also split the mirror field name
            partsM    = split(mirrorName, {'norm_', '_resident_'});
            normBitsM = partsM{2};
            resBitsM  = partsM{3};

            % Apply the retention rules
            % 1) Compare the 8th bit of resident bits
            if resBits(8) ~= resBitsM(8)
                if resBits(8) == '1'
                    keepNames{end + 1} = name; %#ok<SAGROW>
                else
                    keepNames{end + 1} = mirrorName; %#ok<SAGROW>
                end

            % 2) Compare the 4th bit of resident bits
            elseif resBits(4) ~= resBitsM(4)
                if resBits(4) == '1'
                    keepNames{end + 1} = name; %#ok<SAGROW>
                else
                    keepNames{end + 1} = mirrorName; %#ok<SAGROW>
                end

            % 3) Compare the 16th bit of norm bits
            elseif normBits(16) ~= normBitsM(16)
                if normBits(16) == '1'
                    keepNames{end + 1} = name; %#ok<SAGROW>
                else
                    keepNames{end + 1} = mirrorName; %#ok<SAGROW>
                end

            % 4) Compare the 8th bit of norm bits
            elseif normBits(8) ~= normBitsM(8)
                if normBits(8) == '0'
                    keepNames{end + 1} = name; %#ok<SAGROW>
                else
                    keepNames{end + 1} = mirrorName; %#ok<SAGROW>
                end

            % 5) Compare the 12th bit of norm bits
            elseif normBits(12) ~= normBitsM(12)
                if normBits(12) == '1'
                    keepNames{end + 1} = name; %#ok<SAGROW>
                else
                    keepNames{end + 1} = mirrorName; %#ok<SAGROW>
                end

            % 6) Compare the 4th bit of norm bits
            elseif normBits(4) ~= normBitsM(4)
                if normBits(4) == '0'
                    keepNames{end + 1} = name; %#ok<SAGROW>
                else
                    keepNames{end + 1} = mirrorName; %#ok<SAGROW>
                end

            else
                fprintf('Error: fields "%s" and "%s" have identical key bits.\n', ...
                    name, mirrorName);
                return;
            end

            % Mark both fields as processed
            processed(i) = true;
            processed(j) = true;
        end
    end
end

% Build the new struct containing only the fields in keepNames
ESS_pruned = struct();
for k = 1:numel(keepNames)
    fld = keepNames{k};
    ESS_pruned.(fld) = sorted_ESS.(fld);
end

save(filename, 'ESS_pruned', 'sorted_ESS', 'combined_ESS');

fprintf('Original struct had %d fields; the new struct retains %d fields.\n', ...
    numNames, numel(keepNames));

%% 2.6 check for common entries
R = 1.3;
mu_e = 0.02;
mu_G = 0.02;
mu_B = 0.02;

checkDir = strcat('ESS_n4_linear_R=', num2str(R), ...
    '_mu_e=', num2str(mu_e), ...
    '_mu_G=', num2str(mu_G), ...
    '_mu_B=', num2str(mu_B));

filename = fullfile(checkDir, 'combined_ESSpairs_n4.mat');
load(filename);

pruned_ESSNames = fieldnames(ESS_pruned);
numinterested = 2048;

% Initialize two cell arrays for norms and strategies
group1 = cell(numinterested, 1);
group2 = cell(numinterested, 1);

for i = 1:numinterested
    % Split field names by '_'
    parts = strsplit(pruned_ESSNames{i}, '_');
    group1{i} = parts{2};
    group2{i} = parts{4};
end

% Convert cell arrays to character matrices
group1Mat = char(group1);
group2Mat = char(group2);

fprintf('Norm part:\n');
for pos = 1:size(group1Mat, 2)
    colData = group1Mat(:, pos);
    uniqueDigits = unique(colData);
    if length(uniqueDigits) == 1
        fprintf('At position %d, all fields are %s\n', pos, uniqueDigits);
    end
end

fprintf('Strategy part:\n');
for pos = 1:size(group2Mat, 2)
    colData = group2Mat(:, pos);
    uniqueDigits = unique(colData);
    if length(uniqueDigits) == 1
        fprintf('At position %d, all fields are %s\n', pos, uniqueDigits);
    end
end

%% 3 export ESS collection to Excel
% Select ESS struct
S = ESS_pruned;
fn = fieldnames(S);
n = numel(fn);

% Initialize
normBits = strings(n, 1);
resBits = strings(n, 1);
cooperate = zeros(n, 1);

for i = 1:n
    name = fn{i};

    % Split field names
    parts = split(name, {'norm_', '_resident_'});
    normBits(i) = parts{2};
    resBits(i)  = parts{3};

    % Get the cooperation rate
    v = S.(name);
    cooperate(i) = v{3};
end

% Build a table and export to Excel
T = table(normBits, resBits, cooperate, ...
    'VariableNames', {'Norm', 'Strategy', 'CooperationRate'});
writetable(T, 'n4_ESS_analysis.xlsx');

%% 4 bistability analysis for selected ESS pairs
%% 4.1 bistability check for selected ESS pairs
tic

% Load selected ESS pairs
load('specialESS2048_n4.mat');

% Set parameter values
mu_G = 0.0001;
mu_B = 0.05;

% Get the selected ESS collection
ESSfields = fieldnames(specialESS2048);
ESSnum = numel(ESSfields);

% Set up parallel computing
corenum = 8;
par = parpool('local', corenum);

res_field = cell(ESSnum, 1);
res_flag  = false(ESSnum, 1);
res_list  = cell(ESSnum, 1);

parfor i = 1:ESSnum
    if mod(i, 64) == 1
        note = "ESSidx=" + num2str(i);
        disp(note);
    end

    fieldName = ESSfields{i};
    ESSpair = specialESS2048.(fieldName);
    norm = ESSpair{1};
    strategy = ESSpair{2};

    [bistab_flag, rep_equ_list] = bistability_check_n4(norm, strategy, mu_G, mu_B);

    res_field{i} = fieldName;
    res_flag(i)  = bistab_flag;
    res_list{i}  = rep_equ_list;
end

bistab_res = [res_field, num2cell(res_flag), res_list];

% Save results
bistabDir = 'n4_bistability_results';
if ~exist(bistabDir, 'dir')
    mkdir(bistabDir);
end
filename = fullfile(bistabDir, strcat('mu_G=', num2str(mu_G), '_mu_B=', num2str(mu_B), '_bistability.mat'));
save(filename, 'bistab_res');

delete(par);
toc

%% 4.2 refine bistability results with a finer grid
tic
mu_G = 0.0001;
mu_B = 0.05;

bistabDir = 'n4_bistability_results';
filename = fullfile(bistabDir, strcat('mu_G=', num2str(mu_G), '_mu_B=', num2str(mu_B), '_bistability.mat'));
load(filename);

idx = find([bistab_res{:, 2}] == 1);
ESS_bistable = bistab_res(idx', :);
temp = cell(numel(idx), 1);

% Set up parallel computing
corenum = 12;
par = parpool('local', corenum);

parfor i = 1:numel(idx)
    if mod(i, 32) == 1
        note = "ESSidx=" + num2str(i);
        disp(note);
    end

    ESSstr = ESS_bistable(i, 1);
    parts = split(ESSstr, "_");

    norm_string = parts{2};
    norm_digits = double(norm_string) - '0';
    norm = reshape(norm_digits, 8, 2)';

    strategy_string = parts{4};
    strategy_digits = double(strategy_string) - '0';
    strategy = reshape(strategy_digits, 4, 2)';

    [~, rep_equ_list] = bistability_check_n4(norm, strategy, mu_G, mu_B);
    temp{i} = rep_equ_list;
end

ESS_bistable(:, 3) = temp;
save(filename, 'bistab_res', 'ESS_bistable');

delete(par);
toc
