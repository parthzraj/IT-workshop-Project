% TEST_QENGINE  Sanity checks for the core functions. Run:  run('tests/test_qengine.m')
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..', 'core'));

folder = fullfile(here, '..', 'data');
if exist(fullfile(folder, 'train_FD001.txt'), 'file')
    data = loadCMAPSS(folder, 'FD001');
else
    data = generateSyntheticCMAPSS(100, 7);
end
fprintf('Dataset: %s, %d engines, %d rows\n', data.name, numel(data.units), numel(data.unit));

P  = preprocessData(data, struct());
cp = classicalPCA(P.Xfit);
assert(abs(sum(cp.explained) - 100) < 1e-8);
assert(norm(cp.V' * cp.V - eye(P.nSensors)) < 1e-10);
fprintf('Sensors kept: %s\n', strjoin(P.names, ' '));

for t = [6 8 10]
    qp = quantumPCA(P.Xfit, struct('nAncilla', t));
    assert(abs(sum(qp.Pm) - 1) < 1e-10);
    assert(norm(qp.U' * qp.U - eye(size(qp.U,1))) < 1e-10);       % unitary
    assert(norm(qp.V' * qp.V - eye(P.nSensors)) < 1e-8);          % orthonormal
    C = comparePCA(P, cp, qp, 3);
    fprintf('t=%2d  resolved=%2d  eigErr=%.3f%%  fidelity=%.4f  AUC c/q = %.4f / %.4f\n', ...
        t, qp.nResolved, C.quantum(3), C.quantum(4), C.classical(7), C.quantum(7));
end
assert(C.quantum(3) < 1);          % <1% eigenvalue error at t = 10
assert(C.quantum(4) > 0.99);

qs = quantumPCA(P.Xfit, struct('nAncilla', 8, 'shots', 10000));
Cs = comparePCA(P, cp, qs, 3);
fprintf('shots=1e4  eigErr=%.3f%%  fidelity=%.4f  AUC=%.4f\n', Cs.quantum(3), Cs.quantum(4), Cs.quantum(7));

fprintf('lambda classical: %s\n', mat2str(cp.lambda(1:5)', 4));
fprintf('lambda qPCA     : %s\n', mat2str(qp.lambda(1:5)', 4));
assert(abs(aucScore([1 2 3 4], [0 0 1 1]) - 1) < 1e-12);
disp('All tests passed.');
