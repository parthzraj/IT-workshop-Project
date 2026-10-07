function S = noiseSweep(data, levels, k, qopts)
%NOISESWEEP "What if the sensors get noisier?" - rerun the whole pipeline per level.
S.levels = levels(:);
n = numel(levels);
S.aucC = zeros(n,1); S.aucQ = zeros(n,1); S.eigErr = zeros(n,1); S.fid = zeros(n,1);
for i = 1:n
    P  = preprocessData(data, struct('noiseLevel', levels(i)));
    cp = classicalPCA(P.Xfit);
    qp = quantumPCA(P.Xfit, qopts);
    T  = comparePCA(P, cp, qp, k);
    S.aucC(i) = T.classical(7);  S.aucQ(i) = T.quantum(7);
    S.eigErr(i) = T.quantum(3);  S.fid(i) = T.quantum(4);
end
end
