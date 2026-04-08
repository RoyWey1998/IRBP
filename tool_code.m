% tool_code.m
% Utility scripts for generating and analyzing results used in this study.

%% 1 generate social norms and strategies in full space
%% 1.1 generate social norms (once)
norms = struct();

% Iterate through all 4096 possible combinations
for num = 0:2^12-1
    % Get a 12-bit binary string
    binStr = dec2bin(num,12);

    % Convert the binary string to a numerical array
    bits = binStr - '0';

    % Convert bits to a 2x6 matrix
    % Order: d_D_B_BB(1,1), d_D_B_GB(1,2), d_D_B_GG(1,3), d_D_G_BB(1,4), d_D_G_GB(1,5), d_D_G_GG(1,6)
    %        d_C_B_BB(2,1), d_C_B_GB(2,2), d_C_B_GG(2,3), d_C_G_BB(2,4), d_C_G_GB(2,5), d_C_G_GG(2,6)
    mat = zeros(2,6);
    mat(1,:) = bits(1:6);
    mat(2,:) = bits(7:12);

    % Create a variable name, e.g. 'norm_000000001010'
    varName = ['norm_' binStr];

    % Store the matrix in the structure with the corresponding field name
    norms.(varName) = mat;
end

% Save to a .mat file
filename = 'social norm_full space.mat';
save(filename, 'norms');

%% 1.2 generate behavioral strategies (once)
strategies = struct();

% Iterate through all 64 possible combinations
for num = 0:2^6-1
    % Get a 6-bit binary string
    binStr = dec2bin(num,6);

    % Convert the binary string to a numerical array
    bits = binStr - '0';

    % Convert bits to a 2x3 matrix
    % Order: p_B_BB(1,1), p_B_GB(1,2), p_B_GG(1,3)
    %        p_G_BB(2,1), p_G_GB(2,2), p_G_GG(2,3)
    mat = zeros(2,3);
    mat(1,:) = bits(1:3);
    mat(2,:) = bits(4:6);

    % Create a variable name, e.g. 'resident_001011'
    varName = ['resident_' binStr];

    % Store the matrix in the structure with the corresponding field name
    strategies.(varName) = mat;
end

% Save to a .mat file
filename = 'behavior strategy_full space.mat';
save(filename, 'strategies');

%% 2 get ESS pairs in full space, linear PGG
% Use one unified parameter set and one dedicated result folder
R = 2;
mu_e = 0.02;
mu_G = 0.02;
mu_B = 0.02;

resultDir = strcat('ESS_linear_R=', num2str(R), ...
    '_mu_e=', num2str(mu_e), ...
    '_mu_G=', num2str(mu_G), ...
    '_mu_B=', num2str(mu_B));

if ~exist(resultDir, 'dir')
    mkdir(resultDir);
end

%% 2.1 split norms into 16 parallel threads and search for ESS pairs
tic

% Load social norms and behavioral strategies
load('social norm_full space.mat');
load('behavior strategy_full space.mat');

% Divide norms into sub-structs for parallel computing
fields = fieldnames(norms);

categories = ["0000", "0001", "0010", "0011", "0100", "0101", "0110", "0111", ...
    "1000", "1001", "1010", "1011", "1100", "1101", "1110", "1111"];

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

    % Get ESS pairs
    ESS = get_ESS_linear(cate_norms, strategies, strategies, mu_e, mu_G, mu_B, R, categories(i));

    % Save results
    filename = fullfile(resultDir, strcat(prefix, ' ESS_pairs.mat'));
    parsave_ESS(filename, ESS);
end

delete(par);
toc

%% 2.2 combine ESS results
% Load results of all categories from the dedicated folder
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

filename = fullfile(resultDir, 'combined_ESSpairs.mat');
save(filename, 'combined_ESS');

%% 2.3 remove ALLD and sort by relative payoff
% Load data
filename = fullfile(resultDir, 'combined_ESSpairs.mat');
load(filename);

% Find ESS pairs of ALLD
fields = fieldnames(combined_ESS);
idx = endsWith(fields, '000000');
numofALLD = sum(idx);

% Get the remaining ESS pairs
refined_ESS = rmfield(combined_ESS, fields(idx));

% Sort the remaining ESS pairs according to relative payoff
refinedFields = fieldnames(refined_ESS);
values = zeros(length(refinedFields), 1);
for i = 1:length(refinedFields)
    curCell = refined_ESS.(refinedFields{i});
    values(i) = curCell{end};
end
[~, sortIdx] = sort(values, 'descend');

% Get sorted and refined ESS pairs
sorted_ESS = struct();
for i = 1:length(sortIdx)
    sortedFieldName = refinedFields{sortIdx(i)};
    sorted_ESS.(sortedFieldName) = refined_ESS.(sortedFieldName);
end

% Save data
save(filename, 'combined_ESS', 'refined_ESS', 'sorted_ESS');

%% 2.4 check for common entries
checkDir = strcat('ESS_linear_R=', num2str(R), ...
    '_mu_e=', num2str(mu_e), ...
    '_mu_G=', num2str(mu_G), ...
    '_mu_B=', num2str(mu_B));

filename = fullfile(checkDir, 'combined_ESSpairs.mat');
load(filename);
sorted_ESSNames = fieldnames(sorted_ESS);
numFields = numel(sorted_ESSNames);

% Initialize two cell arrays for norms and strategies
group1 = cell(numFields, 1);
group2 = cell(numFields, 1);

for i = 1:numFields
    % Split field names by '_'
    parts = strsplit(sorted_ESSNames{i}, '_');
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

%% 3 reputation dynamics and bistability in full space
% Reputation equilibrium for one strategy
tic
load("specialESS.mat");
ESSfields = fieldnames(specialESS128);

ESSid = 117;

% ESSpair = specialFields16{ESSid};
ESSpair = specialESS128.(ESSfields{ESSid});
ESSnorm = ESSpair{1};
ESSstrategy = ESSpair{2};

% Set up
default;
mu_B = 0.05;
as_list = [200,300,400];

coreNum = length(as_list);
par = parpool('local', coreNum);

parfor p = 1:length(as_list)
    as = as_list(p);
    mu_G = mu_B/as;
    mu_E = 0:0.001:1.0;
    num_mue = length(mu_E);

    % Initialize
    rep_equ = {};

    for i = 1:num_mue
        mu_e = mu_E(i);
        res = get_rep_equ(ESSnorm, ESSstrategy, mu_e, mu_G, mu_B);
        rep_equ{i} = res(:);
    end

    filename = strcat(ESSfields{ESSid}, '_id=', num2str(ESSid), ...
        ' mu_B=', num2str(mu_B), ' as=', num2str(as), ' rep_equ.mat');
    parsave_rep_equ(filename, rep_equ);
end

delete(par);
toc

%% 4 check for mirror symmetry in ESS collections
% Load the original ESS collection
q = 1;
R = 2;
mu_e = 0.005;
mu_G = 0.005;
mu_B = 0.005;

if q == 1
    filename0 = strcat('R=', num2str(R), ' mu_e=', num2str(mu_e), ...
        ' mu_G=', num2str(mu_G), ' mu_B=', num2str(mu_B), '_ESSpairs.mat');
else
    filename0 = strcat('q=', num2str(q), ' R=', num2str(R), ...
        ' mu_e=', num2str(mu_e), ' mu_G=', num2str(mu_G), ...
        ' mu_B=', num2str(mu_B), '_ESSpairs.mat');
end
load(filename0);
ESS = sorted_ESS;

allNames = fieldnames(ESS);
missingNames = {};

for i = 1:numel(allNames)
    name = allNames{i};

    % Extract the 12-bit norm string and 6-bit resident string
    parts    = split(name, {'norm_','_resident_'});
    normBits = parts{2};
    resBits  = parts{3};

    % Generate the mirror field name
    mirrorName = get_mirror_ESSpair(normBits, resBits);

    % Record fields whose mirrors are absent
    if ~isfield(ESS, mirrorName)
        missingNames{end+1} = name;
    end
end

% Build a new struct containing only fields without mirror counterparts
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

%% 4.1 prune ESS collection by deleting mirror-symmetric pairs
% Rule:
% For each pair of mirror-symmetric fields, keep only one representative
% according to the ordered bit-comparison rules below.
% If a field has no mirror counterpart, keep it unconditionally.

q = 1;
R = 2;
mu_e = 0.005;
mu_G = 0.005;
mu_B = 0.005;

if q == 1
    filename0 = strcat('R=', num2str(R), ' mu_e=', num2str(mu_e), ...
        ' mu_G=', num2str(mu_G), ' mu_B=', num2str(mu_B), '_ESSpairs.mat');
else
    filename0 = strcat('q=', num2str(q), ' R=', num2str(R), ...
        ' mu_e=', num2str(mu_e), ' mu_G=', num2str(mu_G), ...
        ' mu_B=', num2str(mu_B), '_ESSpairs.mat');
end
load(filename0);

allNames = fieldnames(sorted_ESS);
numNames = numel(allNames);
processed = false(numNames, 1);
keepNames = {};

for i = 1:numNames
    if processed(i)
        continue;
    end

    name = allNames{i};

    % Split the field name into normBits (12-bit) and resBits (6-bit)
    parts    = split(name, {'norm_', '_resident_'});
    normBits = parts{2};
    resBits  = parts{3};

    % Generate the mirror field name
    mirrorName = get_mirror_ESSpair(normBits, resBits);

    % Find the index of the mirror field in allNames
    j = find(strcmp(allNames, mirrorName), 1);

    if isempty(j)
        % No mirror exists, so keep this field
        keepNames{end+1} = name;
        processed(i) = true;
    else
        if ~processed(j)
            % Also split the mirror field name
            partsM    = split(mirrorName, {'norm_', '_resident_'});
            normBitsM = partsM{2};
            resBitsM  = partsM{3};

            % Apply the retention rules
            if resBits(6) ~= resBitsM(6)
                if resBits(6) == '1'
                    keepNames{end+1} = name;
                else
                    keepNames{end+1} = mirrorName;
                end

            elseif resBits(3) ~= resBitsM(3)
                if resBits(3) == '1'
                    keepNames{end+1} = name;
                else
                    keepNames{end+1} = mirrorName;
                end

            elseif normBits(12) ~= normBitsM(12)
                if normBits(12) == '1'
                    keepNames{end+1} = name;
                else
                    keepNames{end+1} = mirrorName;
                end

            elseif normBits(6) ~= normBitsM(6)
                if normBits(6) == '0'
                    keepNames{end+1} = name;
                else
                    keepNames{end+1} = mirrorName;
                end

            elseif normBits(9) ~= normBitsM(9)
                if normBits(9) == '1'
                    keepNames{end+1} = name;
                else
                    keepNames{end+1} = mirrorName;
                end

            elseif normBits(3) ~= normBitsM(3)
                if normBits(3) == '0'
                    keepNames{end+1} = name;
                else
                    keepNames{end+1} = mirrorName;
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

% Build the new struct containing only fields in keepNames
ESS_pruned = struct();
for k = 1:numel(keepNames)
    fld = keepNames{k};
    ESS_pruned.(fld) = sorted_ESS.(fld);
end

save(filename0, 'ESS_pruned', 'sorted_ESS', 'combined_ESS');

fprintf('Original struct had %d fields; the new struct retains %d fields.\n', ...
    numNames, numel(keepNames));

