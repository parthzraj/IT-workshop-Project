% RUN_QENGINE_DEMO  Whole Q-Engine pipeline as a script (no GUI).
% Use this first: if it runs, the app will run. It also makes the report figures.
root = fileparts(mfilename('fullpath'));
addpath(fullfile(root, 'core'));

%% 1. Data
dataFolder = fullfile(root, 'data');
if exist(fullfile(dataFolder, 'train_FD001.txt'), 'file')
    data = loadCMAPSS(dataFolder, 'FD001');
else
    warning('train_FD001.txt not found in /data - using SYNTHETIC stand-in data.');
    data = generateSyntheticCMAPSS(100, 7);
end
engine = data.units(end);            % a held-out engine
k = 3;

%% 2. Preprocess
P = preprocessData(data, struct('noiseLevel', 0));
fprintf('%s: %d engines, %d cycles, %d informative sensors\n', ...
    data.name, numel(data.units), numel(data.unit), P.nSensors);

%% 3. Classical PCA and 4. qPCA
cp = classicalPCA(P.Xfit);
qp = quantumPCA(P.Xfit, struct('nAncilla', 8, 'shots', Inf));

%% 5. Compare
T = comparePCA(P, cp, qp, k);
fprintf('\n%-36s %12s %12s\n', 'Metric', 'Classical', 'qPCA');
for i = 1:numel(T.names)
    fprintf('%-36s %12.4f %12.4f\n', T.names{i}, T.classical(i), T.quantum(i));
end

%% 6. Engine health
idx = (data.unit == engine);
st  = engineStatus(T.mq.score(idx), data.cycle(idx), T.mq.health);
fprintf('\nEngine %d: %s (score %.2f), first alarm at cycle %g, %g cycles before failure\n', ...
    engine, st.label, st.score, st.alarmCycle, st.leadTime);

%% 7. Figures
figure('Name', 'Q-Engine demo', 'Color', 'w', 'Position', [80 80 1200 700]);
subplot(2,3,1);
bar([cp.explained(1:6), qp.explained(1:6)]); legend('Classical', 'qPCA');
xlabel('Principal component'); ylabel('Explained variance (%)'); title('Scree plot');

subplot(2,3,2);
stem(qp.phase, qp.counts / sum(qp.counts), 'Marker', 'none'); hold on;
plot(qp.peakPhase(1:k), zeros(k,1), 'rv', 'MarkerFaceColor', 'r');
xlim([0 1]); xlabel('Measured phase  m / 2^t'); ylabel('Probability');
title('QPE outcome distribution');

subplot(2,3,3);
drawQPECircuit(gca, qp.nAnc, qp.nSys);

subplot(2,3,4);
plot(data.cycle(idx), T.mc.score(idx), 'b-', data.cycle(idx), T.mq.score(idx), 'r--', 'LineWidth', 1.5);
hold on; plot(xlim, [0.6 0.6], 'k:', xlim, [0.85 0.85], 'k:');
ylim([0 1.05]); xlabel('Cycle'); ylabel('Anomaly score'); legend('Classical', 'qPCA', 'Location', 'northwest');
title(sprintf('Engine %d health', engine));

subplot(2,3,5);
Z = T.mq.Z(idx, :);
scatter3(Z(:,1), Z(:,2), Z(:,3), 18, T.mq.score(idx), 'filled'); colorbar;
xlabel('PC1'); ylabel('PC2'); zlabel('PC3'); title('qPCA health trajectory'); grid on;

subplot(2,3,6);
S = componentSweep(P, cp, qp, 2:min(10, P.nSensors));
plot(S.k, S.recC, 'bo-', S.k, S.recQ, 'rx--', 'LineWidth', 1.3);
xlabel('Components kept'); ylabel('Reconstruction error'); legend('Classical', 'qPCA');
title('Effect of k'); grid on;
