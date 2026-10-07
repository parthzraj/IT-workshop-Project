function [A, d2] = anomalyScore(Z, H)
%ANOMALYSCORE Map distance from the healthy region to a 0..1 score.
%   d2(x) = (z - m0)' * inv(S0) * (z - m0)        Mahalanobis distance in PC space
%   A(x)  = 1 - exp( -ln(2.5) * d2 / d2ref )      A = 0.60 exactly at d2 = d2ref
Zc = Z - repmat(H.m0, size(Z,1), 1);
d2 = sum((Zc * H.Sinv) .* Zc, 2);
A  = 1 - exp(-log(2.5) * d2 / H.d2ref);
end
