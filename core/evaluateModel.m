function M = evaluateModel(P, pca, k)
%EVALUATEMODEL Project, score and measure a PCA result (classical or quantum).
%   Everything is fitted on P.fitUnits; metrics are reported on held-out engines.
k  = min(k, size(pca.V, 2));
Vk = pca.V(:, 1:k);
M.k = k;
M.Z = P.X * Vk;                                   % reduced representation, all cycles
M.health = fitHealthModel(M.Z(P.isFit & P.isHealthy, :));
[M.raw, M.d2] = anomalyScore(M.Z, M.health);

% causal 5-cycle smoothing per engine
M.score = zeros(size(M.raw));
us = unique(P.unit);
for u = us(:)'
    idx = (P.unit == u);
    M.score(idx) = smoothSeries(M.raw(idx), 5);
end

test = ~P.isFit;
if ~any(test), test = P.isFit; end                % single-engine edge case
Xt = P.X(test, :);
E  = Xt - (Xt * Vk) * Vk';
M.reconError  = sum(E(:).^2) / sum(Xt(:).^2);
M.varCaptured = sum(pca.explained(1:k));
sel = test & (P.isHealthy | P.isFailing);
M.auc = aucScore(M.score(sel), P.isFailing(sel));
end
