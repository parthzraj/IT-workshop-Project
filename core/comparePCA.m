function T = comparePCA(P, cp, qp, k)
%COMPAREPCA Side-by-side metrics for classical PCA and qPCA.
mc = evaluateModel(P, cp, k);
mq = evaluateModel(P, qp, k);
relErr = abs(qp.lambda(1:k) - cp.lambda(1:k)) ./ cp.lambda(1:k);
fid    = abs(sum(cp.V(:,1:k) .* qp.V(:,1:k), 1))';            % |<v_c|v_q>| per component
subsp  = norm(cp.V(:,1:k)' * qp.V(:,1:k), 'fro')^2 / k;       % 1 = identical subspace
T.k = k;
T.mc = mc; T.mq = mq;
T.eigRelErr = relErr;
T.fidelity  = fid;
T.subspace  = subsp;
T.names = {'Components kept (k)'; 'Variance captured (%)'; ...
           'Mean eigenvalue rel. error (%)'; 'Mean component fidelity'; ...
           'Subspace overlap'; 'Reconstruction error (held-out)'; ...
           'Anomaly AUC (held-out)'; 'Run time (s)'};
T.classical = [k; mc.varCaptured; 0; 1; 1; mc.reconError; mc.auc; cp.time];
T.quantum   = [k; mq.varCaptured; 100*mean(relErr); mean(fid); subsp; ...
               mq.reconError; mq.auc; qp.time];
end
