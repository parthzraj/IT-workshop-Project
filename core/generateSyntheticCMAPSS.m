function data = generateSyntheticCMAPSS(nEngines, seed)
%GENERATESYNTHETICCMAPSS Stand-in data with the same layout as FD001.
%   NOT NASA data. It exists only so the app can be developed and demoed
%   before the real files are downloaded. Report results on real C-MAPSS.
if nargin < 1, nEngines = 100; end
if nargin < 2, seed = 7; end
rng(seed);

%        sensor: 1      2      3      4     5     6     7      8       9     10
base  = [518.67 642.2 1586  1400 14.62 21.61 554.2 2388.05 9050  1.3 ...
         47.3  522.0 2388.05 8130 8.40 0.03 392 2388 100 39.0 23.40];
gain  = [0      1.6   18    32   0     0    -3.2   0.22    45    0  ...
         1.0  -2.8   0.22    38   0.13 0    5   0    0  -0.65 -0.40];
noise = [0      0.30  4.0   5.0  0     0     0.50  0.04    5.0   0  ...
         0.15  0.40  0.04    5.0  0.02 0    1.0 0    0   0.10  0.06];
core2 = zeros(1,21); core2([9 14]) = [30 28];   % second latent factor (core speed drift)

rows = cell(nEngines,1);
for u = 1:nEngines
    L   = round(130 + 230*rand);
    t   = (1:L)';
    a   = 3.5 + 1.5*rand;
    deg = (exp(a*t/L) - 1) / (exp(a) - 1);        % 0 (new) -> 1 (failure)
    f2  = (2*rand - 1) * deg.^0.7 + 0.15*randn;   % engine-specific drift
    wear = 0.08*randn;                            % initial manufacturing wear
    S = repmat(base, L, 1) + (deg + wear)*gain + f2*core2 ...
        + randn(L,21).*repmat(noise, L, 1);
    S(:,17) = round(S(:,17));
    op = [0.002*randn(L,1), 0.0003*randn(L,1), 100*ones(L,1)];
    rows{u} = [u*ones(L,1), t, op, S];
end
data = packCMAPSS(vertcat(rows{:}), 'SYNTHETIC');
end
