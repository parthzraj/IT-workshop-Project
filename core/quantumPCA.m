function R = quantumPCA(X, opts)
%QUANTUMPCA Quantum PCA by quantum phase estimation (statevector simulation).
%
%   Formulation (Lloyd, Mohseni & Rebentrost, Nature Physics 2014):
%     1. rho = X'X / tr(X'X)        covariance as a density matrix (trace 1)
%     2. U   = exp(2*pi*i*rho)      unitary whose eigenphases ARE the eigenvalues of rho
%     3. QPE with t ancilla qubits on U, system register prepared in rho itself
%     4. measuring the ancillas gives m ~ lambda*2^t with probability lambda,
%        and leaves the system register in the matching eigenvector
%
%   What is simulated exactly : the full QPE circuit (Hadamards, controlled
%       U^(2^k), inverse QFT, measurement) acting on a purification of rho.
%   What is NOT simulated     : (a) building U from many copies of rho
%       (density-matrix exponentiation) - U is formed with expm;
%       (b) QRAM state preparation; (c) gate noise.
%   Eigenvectors are read from the post-measurement system state, which on
%   hardware would need state tomography. With finite shots a simple
%   1/sqrt(n) tomography noise model is applied (an approximation).
%
%   opts.nAncilla  phase-register qubits t (default 8) -> resolution 1/2^t
%   opts.shots     number of measurements, Inf = exact probabilities (default)
%   opts.seed      RNG seed for shot sampling
if nargin < 2, opts = struct(); end
if ~isfield(opts, 'nAncilla'), opts.nAncilla = 8; end
if ~isfield(opts, 'shots'),    opts.shots = Inf; end
if ~isfield(opts, 'seed'),     opts.seed = 1; end
t0 = tic;
rng(opts.seed);

[N, d] = size(X);
n = max(1, ceil(log2(d)));          % system qubits
D = 2^n;                            % padded dimension
t = opts.nAncilla;
T = 2^t;

% --- 1) state preparation -------------------------------------------------
% |psi> = sum_ij A_ij |i>_sys |j>_env with A*A' = rho. A comes from the QR
% factor of the data, i.e. it is the amplitude-encoded data matrix up to an
% isometry on the environment register. No eigendecomposition is used here.
[~, Rf] = qr(X, 0);
A = zeros(D, size(Rf,1));
A(1:d, :) = Rf' / norm(X, 'fro');
rho = A * A';  rho = (rho + rho') / 2;
trC = norm(X, 'fro')^2 / N;         % trace of the covariance, restores the scale

% --- 2) unitary -----------------------------------------------------------
U = expm(2i * pi * rho);

% --- 3) phase estimation --------------------------------------------------
% After H^t and the controlled-U^(2^k) gates the state is
%   (1/sqrt(T)) * sum_tau |tau> (U^tau A).  The inverse QFT is an FFT over tau.
Phi = zeros(D, size(A,2), T);
B = A;
for tau = 1:T
    Phi(:,:,tau) = B;
    B = U * B;
end
Phi = fft(Phi, [], 3) / T;          % Phi(:,:,m+1) = amplitude block for outcome m
Pm = squeeze(sum(sum(abs(Phi).^2, 1), 2));
Pm = Pm / sum(Pm);

% --- 4) measurement -------------------------------------------------------
if isfinite(opts.shots)
    counts = sampleCounts(Pm, opts.shots);
else
    counts = Pm;                    % exact limit
end

% conditional (unnormalised) system states  R_m = Tr_env |Phi_m><Phi_m|
Rm = zeros(D, D, T);
for m = 1:T
    Rm(:,:,m) = real(Phi(:,:,m) * Phi(:,:,m)');
end

% --- 5) read out eigenvectors (tomography of the conditional states) -------
cand = zeros(D, 0); wgt = zeros(1, 0);
minShots = 20;
for m = 1:T
    if isfinite(opts.shots)
        if counts(m) < minShots, continue; end
        E = randn(D); E = (E + E') / 2;
        est = Rm(:,:,m) / Pm(m) + E / sqrt(counts(m));   % noisy tomography
        est = est * counts(m) / opts.shots;
    else
        if Pm(m) < 1e-9, continue; end
        est = Rm(:,:,m);
    end
    [W, S] = eig((est + est') / 2);
    s = diag(S);
    keepIdx = find(s > 1e-3 * max(s) & s > 1e-10);
    cand = [cand, W(:, keepIdx)];            %#ok<AGROW>
    wgt  = [wgt,  s(keepIdx)'];              %#ok<AGROW>
end

% greedy selection: strongest candidates first, skip duplicates (the same
% eigenvector leaks into neighbouring phase bins)
[~, order] = sort(wgt, 'descend');
Vq = zeros(D, 0);
for c = order
    v = cand(:, c);
    v = v - Vq * (Vq' * v);
    if norm(v)^2 > 0.5
        Vq = [Vq, v / norm(v)];              %#ok<AGROW>
    end
    if size(Vq, 2) == d, break; end
end

% --- 6) eigenvalue of each component = centroid of its phase peak ----------
nq = size(Vq, 2);
lamRho = zeros(nq, 1);
bins = (0:T-1)';
for j = 1:nq
    w = zeros(T, 1);
    for m = 1:T
        w(m) = Vq(:,j)' * Rm(:,:,m) * Vq(:,j);
    end
    [~, m0] = max(w);
    win = max(1, m0-2):min(T, m0+2);
    ww = w(win);
    if isfinite(opts.shots)
        ww = sampleCounts(ww / sum(ww), max(1, round(opts.shots * sum(ww))));
    end
    lamRho(j) = sum(bins(win) .* ww) / sum(ww) / T;
end
[lamRho, order] = sort(lamRho, 'descend');
Vq = Vq(:, order);

% back to the d physical sensors, complete the basis if QPE resolved fewer
V = Vq(1:d, :);
[Q, ~] = qr([V, eye(d)], 0);
V = [V, Q(:, nq+1:d)];
for j = 1:nq, V(:,j) = V(:,j) / norm(V(:,j)); end
lambda = [lamRho; zeros(d - nq, 1)] * trC;

R.method     = 'qPCA (QPE simulation)';
R.V          = fixSigns(V);
R.lambda     = lambda;
R.explained  = 100 * lambda / trC;   % eigenvalue of rho = fraction of variance
R.rho        = rho;
R.U          = U;
R.Pm         = Pm;                   % exact outcome distribution of the phase register
R.counts     = counts;               % sampled histogram (== Pm when shots = Inf)
R.phase      = bins / T;
R.peakPhase  = lamRho;
R.nResolved  = nq;
R.nSys       = n;
R.nAnc       = t;
R.shots      = opts.shots;
R.resolution = trC / T;              % eigenvalue resolution in covariance units
R.time       = toc(t0);
end

function c = sampleCounts(p, shots)
% multinomial sampling without toolboxes
edges = [0; cumsum(p(:))];
edges(end) = 1;
r = rand(shots, 1);
c = histc(r, edges); %#ok<HISTC>
c = c(1:end-1);
c(end) = c(end) + (shots - sum(c));
end
