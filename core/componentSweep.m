function S = componentSweep(P, cp, qp, ks)
%COMPONENTSWEEP Variance, reconstruction error and AUC as a function of k.
S.k = ks(:);
n = numel(ks);
S.varC = zeros(n,1); S.varQ = zeros(n,1);
S.recC = zeros(n,1); S.recQ = zeros(n,1);
S.aucC = zeros(n,1); S.aucQ = zeros(n,1);
for i = 1:n
    mc = evaluateModel(P, cp, ks(i));
    mq = evaluateModel(P, qp, ks(i));
    S.varC(i) = mc.varCaptured; S.varQ(i) = mq.varCaptured;
    S.recC(i) = mc.reconError;  S.recQ(i) = mq.reconError;
    S.aucC(i) = mc.auc;         S.aucQ(i) = mq.auc;
end
end
