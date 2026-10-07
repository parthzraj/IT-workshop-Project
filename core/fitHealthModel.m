function H = fitHealthModel(Zhealthy)
%FITHEALTHMODEL Describe the normal operating region in the reduced PC space.
%   The region is a Gaussian ellipsoid (mean + covariance of healthy cycles).
%   d2ref is the 99th percentile of the healthy Mahalanobis distances.
k = size(Zhealthy, 2);
H.m0 = mean(Zhealthy, 1);
S0 = cov(Zhealthy) + 1e-9 * eye(k);
H.Sinv = inv(S0);
d2 = mahal2(Zhealthy, H);
ds = sort(d2);
H.d2ref = ds(max(1, ceil(0.99 * numel(ds))));
H.warn  = 0.60;    % score reached when d2 = d2ref
H.alert = 0.85;
end

function d2 = mahal2(Z, H)
Zc = Z - repmat(H.m0, size(Z,1), 1);
d2 = sum((Zc * H.Sinv) .* Zc, 2);
end
