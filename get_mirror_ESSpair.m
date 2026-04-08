function mirrorName = get_mirror_ESSpair(normBits, resBits)
% Generate the mirror-symmetry ESS-pair field name.
% Input:
%   normBits : 1x12 char vector of '0'/'1'
%   resBits  : 1x6 char vector of '0'/'1'
% Output:
%   mirrorName : string of the form
%       'norm_<mirrorNorm>_resident_<mirrorRes>'

% Validate inputs
assert(ischar(normBits) && numel(normBits) == 12 && all(ismember(normBits, '01')), ...
    'normBits must be a 1x12 char array of 0/1');
assert(ischar(resBits) && numel(resBits) == 6 && all(ismember(resBits, '01')), ...
    'resBits must be a 1x6 char array of 0/1');

% Helper to flip '0' <-> '1'
flipBit = @(c) char('1' + '0' - c);

% Split normBits, reverse each half, then flip bits
firstHalf  = normBits(1:6);
secondHalf = normBits(7:12);
rev1       = firstHalf(end:-1:1);
rev2       = secondHalf(end:-1:1);
mirrorNorm = [flipBit(rev1), flipBit(rev2)];

% Reverse the resident bits (no bit flip)
mirrorRes = resBits(end:-1:1);

% Assemble final field name
mirrorName = sprintf('norm_%s_resident_%s', mirrorNorm, mirrorRes);
end