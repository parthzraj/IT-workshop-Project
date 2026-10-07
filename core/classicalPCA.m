function R = classicalPCA(X)
%CLASSICALPCA Baseline PCA by eigendecomposition of C = X'X/N.
%   X must already be centred (z-scored). Returns eigenvalues in descending order.
t0 = tic;
N = size(X,1);
C = (X' * X) / N;
C = (C + C') / 2;
[V, D] = eig(C);
[lambda, order] = sort(real(diag(D)), 'descend');
V = V(:, order);
V = fixSigns(V);
R.method    = 'Classical PCA';
R.C         = C;
R.V         = V;
R.lambda    = lambda;
R.explained = 100 * lambda / sum(lambda);
R.time      = toc(t0);
end
