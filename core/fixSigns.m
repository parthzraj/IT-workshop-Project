function V = fixSigns(V, Vref)
%FIXSIGNS Remove the arbitrary sign of eigenvectors.
%   fixSigns(V)       makes the largest-magnitude entry of each column positive.
%   fixSigns(V, Vref) aligns each column with the matching column of Vref.
for j = 1:size(V,2)
    if nargin > 1 && j <= size(Vref,2)
        s = sign(Vref(:,j)' * V(:,j));
    else
        [~, i] = max(abs(V(:,j)));
        s = sign(V(i,j));
    end
    if s == 0, s = 1; end
    V(:,j) = s * V(:,j);
end
end
