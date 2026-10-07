function auc = aucScore(scores, isPositive)
%AUCSCORE Area under the ROC curve (Mann-Whitney statistic, ties averaged).
scores = scores(:); isPositive = logical(isPositive(:));
nP = sum(isPositive); nN = sum(~isPositive);
if nP == 0 || nN == 0, auc = NaN; return; end
[s, order] = sort(scores);
r = zeros(size(s));
i = 1; n = numel(s);
while i <= n
    j = i;
    while j < n && s(j+1) == s(i), j = j + 1; end
    r(i:j) = (i + j) / 2;
    i = j + 1;
end
ranks = zeros(n, 1); ranks(order) = r;
auc = (sum(ranks(isPositive)) - nP*(nP+1)/2) / (nP * nN);
end
