function y = smoothSeries(x, w)
%SMOOTHSERIES Causal moving average over the last w samples (no look-ahead).
x = x(:);
y = filter(ones(w,1)/w, 1, x);
for i = 1:min(w-1, numel(x))
    y(i) = mean(x(1:i));
end
end
