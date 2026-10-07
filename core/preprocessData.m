function P = preprocessData(data, opts)
%PREPROCESSDATA Sensor selection, noise injection, split and z-scoring.
%   opts.noiseLevel  extra Gaussian noise as a fraction of each sensor's std (0 = none)
%   opts.healthyFrac first fraction of each engine's life treated as healthy (0.20)
%   opts.fitFrac     fraction of engines used to fit the model (0.80); rest are held out
%   opts.seed        RNG seed for the injected noise
if nargin < 2, opts = struct(); end
opts = setDefault(opts, 'noiseLevel', 0);
opts = setDefault(opts, 'healthyFrac', 0.20);
opts = setDefault(opts, 'fitFrac', 0.80);
opts = setDefault(opts, 'seed', 1);

S = data.sensors;

% 1) keep informative sensors only (constant / two-valued channels carry no variance)
keep = false(1, size(S,2));
for j = 1:size(S,2)
    keep(j) = numel(unique(S(:,j))) > 2;
end
S = S(:, keep);
P.sensorIdx = find(keep);
P.names = arrayfun(@(i) sprintf('S%d', i), P.sensorIdx, 'UniformOutput', false);

% 2) optional "what-if" sensor noise
if opts.noiseLevel > 0
    rng(opts.seed);
    S = S + opts.noiseLevel * randn(size(S)) .* repmat(std(S,0,1), size(S,1), 1);
end

% 3) engine-level split: model is fitted on fitUnits, evaluated on testUnits
nU = numel(data.units);
nFit = max(1, min(nU-1, round(opts.fitFrac*nU)));
if nU == 1, nFit = 1; end
P.fitUnits  = data.units(1:nFit);
P.testUnits = data.units(nFit+1:end);
P.isFit     = ismember(data.unit, P.fitUnits);

% 4) z-score with statistics of the fitting engines only (no leakage)
P.mu    = mean(S(P.isFit,:), 1);
P.sigma = std(S(P.isFit,:), 0, 1);
P.sigma(P.sigma == 0) = 1;
P.X = (S - repmat(P.mu, size(S,1), 1)) ./ repmat(P.sigma, size(S,1), 1);

P.Xfit      = P.X(P.isFit,:);
P.isHealthy = data.cycle <= ceil(opts.healthyFrac * data.life);
P.isFailing = data.rul <= 30;
P.unit  = data.unit;
P.cycle = data.cycle;
P.rul   = data.rul;
P.opts  = opts;
P.nSensors = size(S,2);
end

function s = setDefault(s, f, v)
if ~isfield(s, f) || isempty(s.(f)), s.(f) = v; end
end
