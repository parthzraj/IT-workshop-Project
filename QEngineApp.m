classdef QEngineApp < handle
    %QENGINEAPP Q-Engine Health Monitor - qPCA based predictive maintenance.
    %   Start with:  launch_qengine      (or  app = QEngineApp;)
    %   Programmatic App Designer-style app (uifigure). Needs MATLAB R2021a+.
    %   All numerics live in /core so they can be tested without the GUI.

    properties
        Fig
        % state
        Data = []
        Prep = []
        CP = []          % classical PCA result
        QP = []          % quantum PCA result
        Cmp = []         % comparison struct
        DataFolder
        Animating = false
        % header
        EngineLabel; StatusLamp; StatusLabel; ScoreLabel; Footer
        % controls
        SubsetDD; EngineDD; KSpinner; NoiseSlider; NoiseLabel
        AncSpinner; ShotsDD; SourceDD
        % tabs / widgets
        Tabs
        InfoArea; RawTable
        SensorDD; AxSensor; AxSensorAll
        AxScree; AxLoad; PcaLabel
        AxCircuit; AxPhase; QTable; QInfo
        AxScore; Ax3D
        CmpTable; AxEig; AxCmpScore
        AxWhat1; AxWhat2
    end

    methods
        function app = QEngineApp()
            root = fileparts(mfilename('fullpath'));
            addpath(fullfile(root, 'core'));
            app.DataFolder = fullfile(root, 'data');
            app.buildUI();
            app.loadData();
        end

        function delete(app)
            if ~isempty(app.Fig) && isvalid(app.Fig), delete(app.Fig); end
        end
    end

    % ------------------------------------------------------------------ UI
    methods (Access = private)
        function buildUI(app)
            app.Fig = uifigure('Name', 'Q-Engine Health Monitor', ...
                'Position', [60 60 1320 780], 'Color', [0.96 0.97 0.98]);
            main = uigridlayout(app.Fig, [3 2]);
            main.RowHeight = {78, '1x', 24};
            main.ColumnWidth = {270, '1x'};

            % ---------- header
            hp = uipanel(main, 'BackgroundColor', [0.07 0.13 0.25]);
            hp.Layout.Row = 1; hp.Layout.Column = [1 2];
            hg = uigridlayout(hp, [2 5]);
            hg.RowHeight = {'1x', '1x'};
            hg.ColumnWidth = {'2x', '1x', 30, '1.2x', '1x'};
            hg.BackgroundColor = [0.07 0.13 0.25];
            t1 = uilabel(hg, 'Text', 'Q-ENGINE HEALTH MONITOR', 'FontSize', 22, ...
                'FontWeight', 'bold', 'FontColor', 'w');
            t1.Layout.Row = 1; t1.Layout.Column = 1;
            t2 = uilabel(hg, 'Text', 'Quantum PCA based predictive maintenance', ...
                'FontSize', 13, 'FontColor', [0.75 0.85 1]);
            t2.Layout.Row = 2; t2.Layout.Column = 1;
            app.EngineLabel = uilabel(hg, 'Text', 'Engine -', 'FontSize', 18, ...
                'FontWeight', 'bold', 'FontColor', 'w');
            app.EngineLabel.Layout.Row = [1 2]; app.EngineLabel.Layout.Column = 2;
            app.StatusLamp = uilamp(hg, 'Color', [0.5 0.5 0.5]);
            app.StatusLamp.Layout.Row = [1 2]; app.StatusLamp.Layout.Column = 3;
            app.StatusLabel = uilabel(hg, 'Text', 'NOT ANALYSED', 'FontSize', 18, ...
                'FontWeight', 'bold', 'FontColor', 'w');
            app.StatusLabel.Layout.Row = [1 2]; app.StatusLabel.Layout.Column = 4;
            app.ScoreLabel = uilabel(hg, 'Text', 'Score  -', 'FontSize', 18, ...
                'FontWeight', 'bold', 'FontColor', 'w');
            app.ScoreLabel.Layout.Row = [1 2]; app.ScoreLabel.Layout.Column = 5;

            % ---------- left control panel
            cp = uipanel(main, 'Title', 'Controls', 'FontWeight', 'bold');
            cp.Layout.Row = 2; cp.Layout.Column = 1;
            cg = uigridlayout(cp, [22 2]);
            cg.RowHeight = repmat({26}, 1, 22);
            cg.ColumnWidth = {'1x', '1x'};
            cg.RowSpacing = 6;
            r = 0;

            r = r + 1; app.addLabel(cg, r, 'Dataset');
            app.SubsetDD = uidropdown(cg, 'Items', {'FD001', 'FD003', 'Synthetic demo'});
            app.SubsetDD.Layout.Row = r; app.SubsetDD.Layout.Column = 2;
            r = r + 1;
            b = uibutton(cg, 'Text', 'Data folder...', 'ButtonPushedFcn', @(~,~) app.chooseFolder());
            b.Layout.Row = r; b.Layout.Column = 1;
            b = uibutton(cg, 'Text', 'LOAD', 'FontWeight', 'bold', ...
                'ButtonPushedFcn', @(~,~) app.loadData());
            b.Layout.Row = r; b.Layout.Column = 2;

            r = r + 1; app.addLabel(cg, r, 'Engine');
            app.EngineDD = uidropdown(cg, 'Items', {'-'}, ...
                'ValueChangedFcn', @(~,~) app.engineChanged());
            app.EngineDD.Layout.Row = r; app.EngineDD.Layout.Column = 2;

            r = r + 2; app.addLabel(cg, r, 'Components (k)');
            app.KSpinner = uispinner(cg, 'Limits', [2 10], 'Value', 3, 'Step', 1, ...
                'ValueChangedFcn', @(~,~) app.paramChanged());
            app.KSpinner.Layout.Row = r; app.KSpinner.Layout.Column = 2;

            r = r + 1;
            app.NoiseLabel = app.addLabel(cg, r, 'Sensor noise: 0 %');
            app.NoiseLabel.Layout.Column = [1 2];
            r = r + 1;
            app.NoiseSlider = uislider(cg, 'Limits', [0 50], 'Value', 0, ...
                'MajorTicks', 0:10:50, 'ValueChangedFcn', @(~,~) app.noiseChanged());
            app.NoiseSlider.Layout.Row = [r r+1]; app.NoiseSlider.Layout.Column = [1 2];

            r = r + 3; app.addLabel(cg, r, 'Phase qubits (t)');
            app.AncSpinner = uispinner(cg, 'Limits', [4 11], 'Value', 8, 'Step', 1);
            app.AncSpinner.Layout.Row = r; app.AncSpinner.Layout.Column = 2;
            r = r + 1; app.addLabel(cg, r, 'Shots');
            app.ShotsDD = uidropdown(cg, 'Items', {'Exact', '1000', '10000', '100000'});
            app.ShotsDD.Layout.Row = r; app.ShotsDD.Layout.Column = 2;
            r = r + 1; app.addLabel(cg, r, 'Health model from');
            app.SourceDD = uidropdown(cg, 'Items', {'qPCA', 'Classical PCA'}, ...
                'ValueChangedFcn', @(~,~) app.paramChanged());
            app.SourceDD.Layout.Row = r; app.SourceDD.Layout.Column = 2;

            r = r + 2;
            b = uibutton(cg, 'Text', 'RUN CLASSICAL PCA', 'FontWeight', 'bold', ...
                'ButtonPushedFcn', @(~,~) app.onRunClassical());
            b.Layout.Row = r; b.Layout.Column = [1 2];
            r = r + 1;
            b = uibutton(cg, 'Text', 'RUN qPCA', 'FontWeight', 'bold', ...
                'BackgroundColor', [0.10 0.35 0.75], 'FontColor', 'w', ...
                'ButtonPushedFcn', @(~,~) app.onRunQuantum());
            b.Layout.Row = r; b.Layout.Column = [1 2];
            r = r + 1;
            b = uibutton(cg, 'Text', 'COMPARE', 'FontWeight', 'bold', ...
                'ButtonPushedFcn', @(~,~) app.onCompare());
            b.Layout.Row = r; b.Layout.Column = [1 2];
            r = r + 1;
            b = uibutton(cg, 'Text', 'Animate trajectory', ...
                'ButtonPushedFcn', @(~,~) app.onAnimate());
            b.Layout.Row = r; b.Layout.Column = [1 2];

            % ---------- tabs
            app.Tabs = uitabgroup(main);
            app.Tabs.Layout.Row = 2; app.Tabs.Layout.Column = 2;

            % 1 data
            tb = uitab(app.Tabs, 'Title', '1  Data');
            g = uigridlayout(tb, [2 1]); g.RowHeight = {130, '1x'};
            app.InfoArea = uitextarea(g, 'Editable', 'off', 'FontName', 'Consolas', 'FontSize', 13);
            app.RawTable = uitable(g);

            % 2 sensors
            tb = uitab(app.Tabs, 'Title', '2  Sensor health');
            g = uigridlayout(tb, [2 2]); g.RowHeight = {28, '1x'}; g.ColumnWidth = {'1x', '1x'};
            app.SensorDD = uidropdown(g, 'Items', {'-'}, ...
                'ValueChangedFcn', @(~,~) app.plotSensors());
            app.SensorDD.Layout.Row = 1; app.SensorDD.Layout.Column = 1;
            l = uilabel(g, 'Text', 'Right: all informative sensors, z-scored (fleet statistics)');
            l.Layout.Row = 1; l.Layout.Column = 2;
            app.AxSensor = uiaxes(g);    app.AxSensor.Layout.Row = 2;    app.AxSensor.Layout.Column = 1;
            app.AxSensorAll = uiaxes(g); app.AxSensorAll.Layout.Row = 2; app.AxSensorAll.Layout.Column = 2;

            % 3 classical
            tb = uitab(app.Tabs, 'Title', '3  Classical PCA');
            g = uigridlayout(tb, [2 2]); g.RowHeight = {30, '1x'};
            app.PcaLabel = uilabel(g, 'Text', 'Press RUN CLASSICAL PCA', 'FontSize', 15, 'FontWeight', 'bold');
            app.PcaLabel.Layout.Row = 1; app.PcaLabel.Layout.Column = [1 2];
            app.AxScree = uiaxes(g); app.AxScree.Layout.Row = 2; app.AxScree.Layout.Column = 1;
            app.AxLoad  = uiaxes(g); app.AxLoad.Layout.Row = 2;  app.AxLoad.Layout.Column = 2;

            % 4 quantum
            tb = uitab(app.Tabs, 'Title', '4  Quantum PCA');
            g = uigridlayout(tb, [2 2]); g.RowHeight = {'1x', '1x'}; g.ColumnWidth = {'1.4x', '1x'};
            app.AxCircuit = uiaxes(g); app.AxCircuit.Layout.Row = 1; app.AxCircuit.Layout.Column = 1;
            app.QInfo = uitextarea(g, 'Editable', 'off', 'FontName', 'Consolas', 'FontSize', 12);
            app.QInfo.Layout.Row = 1; app.QInfo.Layout.Column = 2;
            app.QInfo.Value = {'WORKFLOW', '', ...
                'Sensor data X (z-scored)', '   -> covariance C = X''X / N', ...
                '   -> density matrix rho = C / tr(C)', ...
                '   -> unitary U = exp(2*pi*i*rho)', ...
                '   -> phase estimation (H, controlled-U^2^k, QFT+)', ...
                '   -> measure phase register: eigenvalues', ...
                '   -> system register: principal components', '', ...
                'Press RUN qPCA'};
            app.AxPhase = uiaxes(g); app.AxPhase.Layout.Row = 2; app.AxPhase.Layout.Column = 1;
            app.QTable = uitable(g); app.QTable.Layout.Row = 2; app.QTable.Layout.Column = 2;

            % 5 health
            tb = uitab(app.Tabs, 'Title', '5  Engine health');
            g = uigridlayout(tb, [1 2]);
            app.AxScore = uiaxes(g);
            app.Ax3D = uiaxes(g);

            % 6 compare
            tb = uitab(app.Tabs, 'Title', '6  Classical vs qPCA');
            g = uigridlayout(tb, [2 2]); g.RowHeight = {230, '1x'};
            app.CmpTable = uitable(g); app.CmpTable.Layout.Row = 1; app.CmpTable.Layout.Column = [1 2];
            app.AxEig = uiaxes(g);      app.AxEig.Layout.Row = 2;      app.AxEig.Layout.Column = 1;
            app.AxCmpScore = uiaxes(g); app.AxCmpScore.Layout.Row = 2; app.AxCmpScore.Layout.Column = 2;

            % 7 what-if
            tb = uitab(app.Tabs, 'Title', '7  What if?');
            g = uigridlayout(tb, [2 2]); g.RowHeight = {32, '1x'};
            b = uibutton(g, 'Text', 'Run noise sweep (0 - 50 %)', ...
                'ButtonPushedFcn', @(~,~) app.onNoiseSweep());
            b.Layout.Row = 1; b.Layout.Column = 1;
            b = uibutton(g, 'Text', 'Run component sweep (k = 2 - 10)', ...
                'ButtonPushedFcn', @(~,~) app.onComponentSweep());
            b.Layout.Row = 1; b.Layout.Column = 2;
            app.AxWhat1 = uiaxes(g); app.AxWhat1.Layout.Row = 2; app.AxWhat1.Layout.Column = 1;
            app.AxWhat2 = uiaxes(g); app.AxWhat2.Layout.Row = 2; app.AxWhat2.Layout.Column = 2;

            % ---------- footer
            app.Footer = uilabel(main, 'Text', 'Ready', 'FontColor', [0.3 0.3 0.3]);
            app.Footer.Layout.Row = 3; app.Footer.Layout.Column = [1 2];
        end

        function l = addLabel(~, parent, row, txt)
            l = uilabel(parent, 'Text', txt);
            l.Layout.Row = row; l.Layout.Column = 1;
        end

        function say(app, msg)
            app.Footer.Text = msg;
            drawnow;
        end
    end

    % ----------------------------------------------------------- callbacks
    methods (Access = private)
        function chooseFolder(app)
            f = uigetdir(app.DataFolder, 'Folder containing train_FD00x.txt');
            figure(app.Fig);
            if ischar(f), app.DataFolder = f; app.loadData(); end
        end

        function loadData(app)
            sub = app.SubsetDD.Value;
            try
                if strcmp(sub, 'Synthetic demo')
                    app.Data = generateSyntheticCMAPSS(100, 7);
                else
                    app.Data = loadCMAPSS(app.DataFolder, sub);
                end
            catch err
                app.SubsetDD.Value = 'Synthetic demo';
                app.Data = generateSyntheticCMAPSS(100, 7);
                uialert(app.Fig, sprintf(['%s\n\nLoaded the SYNTHETIC stand-in instead. ' ...
                    'It is not NASA data - use it for testing the app only.'], err.message), ...
                    'Dataset not found', 'Icon', 'warning');
            end
            items = arrayfun(@(u) sprintf('Engine %d', u), app.Data.units, 'UniformOutput', false);
            app.EngineDD.ItemsData = [];
            app.EngineDD.Items = items;
            app.EngineDD.ItemsData = app.Data.units(:)';
            app.EngineDD.Value = app.Data.units(end);     % a held-out engine by default
            app.invalidate();
            app.SensorDD.Items = app.Prep.names;
            app.SensorDD.Value = app.Prep.names{1};
            app.KSpinner.Limits = [2 min(10, app.Prep.nSensors)];
            app.engineChanged();
            app.say(sprintf('Loaded %s: %d engines, %d cycles.', app.Data.name, ...
                numel(app.Data.units), numel(app.Data.unit)));
        end

        function invalidate(app)
            % data or noise changed: redo preprocessing, drop stale results
            opts = struct('noiseLevel', app.NoiseSlider.Value / 100);
            app.Prep = preprocessData(app.Data, opts);
            app.CP = []; app.QP = []; app.Cmp = [];
            app.StatusLamp.Color = [0.5 0.5 0.5];
            app.StatusLabel.Text = 'NOT ANALYSED';
            app.ScoreLabel.Text = 'Score  -';
        end

        function noiseChanged(app)
            app.NoiseLabel.Text = sprintf('Sensor noise: %.0f %% of sensor std', app.NoiseSlider.Value);
            hadC = ~isempty(app.CP); hadQ = ~isempty(app.QP);
            app.invalidate();
            app.plotSensors();
            if hadC, app.onRunClassical(); end
            if hadQ, app.onRunQuantum(); end
        end

        function paramChanged(app)
            if ~isempty(app.CP), app.plotClassical(); end
            if ~isempty(app.QP), app.plotQuantum(); end
            if ~isempty(app.CP) && ~isempty(app.QP), app.onCompare(false); end
            app.updateHealth();
        end

        function engineChanged(app)
            u = app.EngineDD.Value;
            idx = (app.Data.unit == u);
            app.EngineLabel.Text = sprintf('Engine %d', u);
            if ismember(u, app.Prep.fitUnits), role = 'model-fitting set'; else, role = 'HELD-OUT test set'; end
            s = app.Data.settings(idx, :);
            app.InfoArea.Value = { ...
                sprintf('Dataset            : %s   (%d engines, %d rows)', app.Data.name, numel(app.Data.units), numel(app.Data.unit)), ...
                sprintf('Selected engine    : %d   (%s)', u, role), ...
                sprintf('Cycles to failure  : %d', sum(idx)), ...
                sprintf('Sensors            : 21 recorded, %d informative -> %s', app.Prep.nSensors, strjoin(app.Prep.names, ' ')), ...
                sprintf('Operating settings : mean [%.4f  %.4f  %.1f]', mean(s(:,1)), mean(s(:,2)), mean(s(:,3))), ...
                sprintf('Healthy baseline   : first %d cycles (20 %% of life)', sum(idx & app.Prep.isHealthy))};
            names = [{'cycle', 'set1', 'set2', 'set3'}, ...
                arrayfun(@(i) sprintf('S%d', i), 1:21, 'UniformOutput', false)];
            app.RawTable.Data = [app.Data.cycle(idx), s, app.Data.sensors(idx, :)];
            app.RawTable.ColumnName = names;
            app.plotSensors();
            app.updateHealth();
            if ~isempty(app.Cmp), app.plotCompare(); end
        end

        function onRunClassical(app)
            app.say('Running classical PCA...');
            app.CP = classicalPCA(app.Prep.Xfit);
            app.plotClassical();
            app.updateHealth();
            app.say(sprintf('Classical PCA done in %.4f s.', app.CP.time));
        end

        function onRunQuantum(app)
            app.say('Simulating quantum phase estimation...');
            sh = app.ShotsDD.Value;
            if strcmp(sh, 'Exact'), shots = Inf; else, shots = str2double(sh); end
            app.QP = quantumPCA(app.Prep.Xfit, ...
                struct('nAncilla', app.AncSpinner.Value, 'shots', shots));
            app.plotQuantum();
            app.updateHealth();
            app.say(sprintf('qPCA done in %.3f s (%d phase + %d system qubits, %d components resolved).', ...
                app.QP.time, app.QP.nAnc, app.QP.nSys, app.QP.nResolved));
        end

        function onCompare(app, switchTab)
            if nargin < 2, switchTab = true; end
            if isempty(app.CP), app.onRunClassical(); end
            if isempty(app.QP), app.onRunQuantum(); end
            app.Cmp = comparePCA(app.Prep, app.CP, app.QP, app.KSpinner.Value);
            app.plotCompare();
            if switchTab, app.Tabs.SelectedTab = app.Tabs.Children(6); end
        end

        function onNoiseSweep(app)
            app.say('Noise sweep running (6 full pipeline runs)...');
            sh = app.ShotsDD.Value;
            if strcmp(sh, 'Exact'), shots = Inf; else, shots = str2double(sh); end
            levels = 0:0.1:0.5;
            S = noiseSweep(app.Data, levels, app.KSpinner.Value, ...
                struct('nAncilla', app.AncSpinner.Value, 'shots', shots));
            ax = app.AxWhat1; cla(ax, 'reset');
            yyaxis(ax, 'left');
            plot(ax, 100*S.levels, S.aucC, 'o-', 100*S.levels, S.aucQ, 'x--', 'LineWidth', 1.5);
            ylabel(ax, 'Anomaly AUC (held-out engines)');
            yyaxis(ax, 'right');
            plot(ax, 100*S.levels, S.eigErr, 's:', 'LineWidth', 1.5);
            ylabel(ax, 'qPCA eigenvalue error (%)');
            xlabel(ax, 'Added sensor noise (% of sensor std)');
            legend(ax, {'AUC classical', 'AUC qPCA', 'eigenvalue error'}, 'Location', 'best');
            title(ax, 'Robustness to sensor noise'); grid(ax, 'on');
            app.say('Noise sweep finished.');
        end

        function onComponentSweep(app)
            if isempty(app.CP), app.onRunClassical(); end
            if isempty(app.QP), app.onRunQuantum(); end
            ks = 2:min(10, app.Prep.nSensors);
            S = componentSweep(app.Prep, app.CP, app.QP, ks);
            ax = app.AxWhat2; cla(ax, 'reset');
            yyaxis(ax, 'left');
            plot(ax, S.k, S.recC, 'o-', S.k, S.recQ, 'x--', 'LineWidth', 1.5);
            ylabel(ax, 'Reconstruction error');
            yyaxis(ax, 'right');
            plot(ax, S.k, S.aucC, 'o-', S.k, S.aucQ, 'x--', 'LineWidth', 1.5);
            ylabel(ax, 'Anomaly AUC');
            xlabel(ax, sprintf('Components kept (of %d sensors)', app.Prep.nSensors));
            legend(ax, {'recon. classical', 'recon. qPCA', 'AUC classical', 'AUC qPCA'}, 'Location', 'best');
            title(ax, 'Effect of the number of components'); grid(ax, 'on');
            app.say('Component sweep finished.');
        end

        function onAnimate(app)
            if app.Animating, app.Animating = false; return; end
            [M, idx] = app.currentModel();
            if isempty(M), uialert(app.Fig, 'Run classical PCA or qPCA first.', 'Nothing to animate'); return; end
            app.Tabs.SelectedTab = app.Tabs.Children(5);
            Z = app.pad3(M.Z(idx, :)); sc = M.score(idx);
            ax = app.Ax3D; app.draw3D(ax, M, idx, true);
            hold(ax, 'on');
            trail = plot3(ax, Z(1,1), Z(1,2), Z(1,3), '-', 'Color', [0.2 0.2 0.2], 'LineWidth', 1.5);
            head  = plot3(ax, Z(1,1), Z(1,2), Z(1,3), 'o', 'MarkerSize', 11, ...
                'MarkerFaceColor', [0.2 0.65 0.3], 'MarkerEdgeColor', 'k');
            hold(ax, 'off');
            app.Animating = true;
            for i = 1:size(Z, 1)
                if ~app.Animating || ~isvalid(app.Fig) || ~isvalid(head), break; end
                set(trail, 'XData', Z(1:i,1), 'YData', Z(1:i,2), 'ZData', Z(1:i,3));
                if sc(i) >= M.health.alert, c = [0.85 0.15 0.15];
                elseif sc(i) >= M.health.warn, c = [0.93 0.69 0.13];
                else, c = [0.2 0.65 0.3]; end
                set(head, 'XData', Z(i,1), 'YData', Z(i,2), 'ZData', Z(i,3), 'MarkerFaceColor', c);
                title(ax, sprintf('Cycle %d / %d   score %.2f', i, size(Z,1), sc(i)));
                drawnow limitrate; pause(0.02);
            end
            app.Animating = false;
        end
    end

    % -------------------------------------------------------------- plots
    methods (Access = private)
        function plotSensors(app)
            if isempty(app.Data), return; end
            u = app.EngineDD.Value; idx = (app.Data.unit == u);
            cyc = app.Data.cycle(idx);
            j = find(strcmp(app.Prep.names, app.SensorDD.Value), 1);
            if isempty(j), j = 1; end
            raw = app.Prep.X(idx, j) * app.Prep.sigma(j) + app.Prep.mu(j);
            nH = sum(idx & app.Prep.isHealthy);

            ax = app.AxSensor; cla(ax); hold(ax, 'on');
            yl = [min(raw) max(raw)]; if yl(1) == yl(2), yl = yl + [-1 1]; end
            patch(ax, [1 nH nH 1], [yl(1) yl(1) yl(2) yl(2)], [0.80 0.93 0.80], ...
                'EdgeColor', 'none', 'FaceAlpha', 0.5);
            plot(ax, cyc, raw, '.', 'Color', [0.6 0.6 0.6]);
            plot(ax, cyc, smoothSeries(raw, 10), '-', 'Color', [0.10 0.35 0.75], 'LineWidth', 2);
            hold(ax, 'off'); ylim(ax, yl); xlim(ax, [1 max(cyc)]);
            xlabel(ax, 'Engine cycle'); ylabel(ax, 'Sensor value');
            title(ax, sprintf('%s, engine %d (green = healthy baseline)', app.SensorDD.Value, u));
            legend(ax, {'healthy window', 'raw', '10-cycle mean'}, 'Location', 'best'); grid(ax, 'on');

            ax = app.AxSensorAll; cla(ax); hold(ax, 'on');
            Xs = app.Prep.X(idx, :);
            for c = 1:size(Xs, 2)
                plot(ax, cyc, smoothSeries(Xs(:,c), 10), 'LineWidth', 1.1);
            end
            hold(ax, 'off'); xlim(ax, [1 max(cyc)]);
            xlabel(ax, 'Engine cycle'); ylabel(ax, 'z-score');
            title(ax, 'All informative sensors (smoothed)');
            legend(ax, app.Prep.names, 'Location', 'eastoutside'); grid(ax, 'on');
        end

        function plotClassical(app)
            cp = app.CP; k = app.KSpinner.Value; n = min(10, numel(cp.lambda));
            ax = app.AxScree; cla(ax, 'reset'); yyaxis(ax, 'left');
            bar(ax, 1:n, cp.explained(1:n), 'FaceColor', [0.10 0.35 0.75]);
            ylabel(ax, 'Explained variance (%)');
            yyaxis(ax, 'right');
            plot(ax, 1:n, cumsum(cp.explained(1:n)), 'o-', 'LineWidth', 1.5);
            ylabel(ax, 'Cumulative (%)'); ylim(ax, [0 100]);
            xlabel(ax, 'Principal component'); title(ax, 'Scree plot'); grid(ax, 'on');

            ax = app.AxLoad; cla(ax);
            bar(ax, cp.V(:, 1:min(3, k)));
            set(ax, 'XTick', 1:app.Prep.nSensors, 'XTickLabel', app.Prep.names);
            ylabel(ax, 'Loading'); title(ax, 'Which sensors drive each component');
            legend(ax, arrayfun(@(i) sprintf('PC%d', i), 1:min(3, k), 'UniformOutput', false), ...
                'Location', 'best'); grid(ax, 'on');
            app.PcaLabel.Text = sprintf(['PC1 + PC2 explain %.1f %% of the variance   |   ' ...
                'first %d components: %.1f %%   (%d sensors -> %d components)'], ...
                sum(cp.explained(1:2)), k, sum(cp.explained(1:k)), app.Prep.nSensors, k);
        end

        function plotQuantum(app)
            qp = app.QP; k = app.KSpinner.Value;
            drawQPECircuit(app.AxCircuit, qp.nAnc, qp.nSys);

            ax = app.AxPhase; cla(ax); hold(ax, 'on');
            p = qp.counts / sum(qp.counts);
            stem(ax, qp.phase, max(p, 1e-5), 'BaseValue', 1e-5, 'Marker', 'none', 'Color', [0.10 0.35 0.75], 'LineWidth', 1.2);
            plot(ax, qp.peakPhase(1:k), interp1(qp.phase, p, qp.peakPhase(1:k), 'nearest', 0), ...
                'v', 'MarkerFaceColor', [0.85 0.15 0.15], 'MarkerEdgeColor', 'none', 'MarkerSize', 8);
            hold(ax, 'off');
            set(ax, 'YScale', 'log'); ylim(ax, [1e-5 1]); xlim(ax, [0 min(1, 1.15*qp.peakPhase(1))]);
            xlabel(ax, 'Measured phase  m / 2^t   (= eigenvalue of \rho = fraction of variance)');
            ylabel(ax, 'Probability (log)');
            title(ax, 'Phase register histogram - red markers: top-k eigenvalues'); grid(ax, 'on');

            n = min(10, qp.nResolved);
            T = table((1:n)', qp.peakPhase(1:n), qp.lambda(1:n), qp.explained(1:n), ...
                'VariableNames', {'PC', 'Phase', 'Eigenvalue', 'Variance_pct'});
            if ~isempty(app.CP)
                T.Classical = app.CP.lambda(1:n);
                T.RelErr_pct = 100 * abs(T.Eigenvalue - T.Classical) ./ T.Classical;
            end
            app.QTable.Data = T;
            if isinf(qp.shots), shotTxt = 'exact (infinite shots)'; else, shotTxt = sprintf('%d', qp.shots); end
            app.QInfo.Value = { ...
                'WORKFLOW', ...
                'X -> C = X''X/N -> rho = C/tr(C) -> U = exp(2*pi*i*rho)', ...
                '  -> QPE -> eigenvalues + principal components', '', ...
                sprintf('System qubits   : %d  (%d sensors padded to %d)', qp.nSys, app.Prep.nSensors, 2^qp.nSys), ...
                sprintf('Phase qubits    : %d  (resolution 1/%d of total variance)', qp.nAnc, 2^qp.nAnc), ...
                sprintf('Shots           : %s', shotTxt), ...
                sprintf('Resolved PCs    : %d', qp.nResolved), ...
                sprintf('Simulation time : %.3f s', qp.time), '', ...
                'Simulated on a classical computer. U is built with expm;', ...
                'the cost of preparing rho and exponentiating it on real', ...
                'hardware is not modelled. No quantum advantage is claimed.'};
        end

        function [M, idx] = currentModel(app)
            M = []; idx = [];
            if isempty(app.Data), return; end
            idx = (app.Data.unit == app.EngineDD.Value);
            src = app.SourceDD.Value;
            if strcmp(src, 'qPCA') && ~isempty(app.QP)
                pca = app.QP;
            elseif ~isempty(app.CP)
                pca = app.CP;
            elseif ~isempty(app.QP)
                pca = app.QP;
            else
                return;
            end
            M = evaluateModel(app.Prep, pca, app.KSpinner.Value);
            M.method = pca.method;
        end

        function updateHealth(app)
            [M, idx] = app.currentModel();
            if isempty(M), return; end
            cyc = app.Data.cycle(idx); sc = M.score(idx);
            st = engineStatus(sc, cyc, M.health);
            app.StatusLamp.Color = st.color;
            app.StatusLabel.Text = st.label;
            app.ScoreLabel.Text = sprintf('Score  %.2f', st.score);

            ax = app.AxScore; cla(ax); hold(ax, 'on');
            plot(ax, cyc, M.raw(idx), '.', 'Color', [0.7 0.7 0.7]);
            plot(ax, cyc, sc, '-', 'Color', [0.10 0.35 0.75], 'LineWidth', 2);
            plot(ax, [1 max(cyc)], M.health.warn*[1 1], '--', 'Color', [0.93 0.69 0.13], 'LineWidth', 1.5);
            plot(ax, [1 max(cyc)], M.health.alert*[1 1], '--', 'Color', [0.85 0.15 0.15], 'LineWidth', 1.5);
            names = {'raw score', 'smoothed (5 cycles)', 'early degradation', 'high anomaly'};
            if ~isnan(st.alarmCycle)
                plot(ax, st.alarmCycle*[1 1], [0 1.05], ':k', 'LineWidth', 1.2);
                names{end+1} = 'first alarm';
            end
            hold(ax, 'off'); ylim(ax, [0 1.05]); xlim(ax, [1 max(cyc)]);
            xlabel(ax, 'Engine operating cycle'); ylabel(ax, 'Anomaly score A(x)');
            if isnan(st.alarmCycle)
                ttl = sprintf('%s, k = %d: no alarm', M.method, M.k);
            else
                ttl = sprintf('%s, k = %d: alarm at cycle %d (%d cycles before end)', ...
                    M.method, M.k, st.alarmCycle, st.leadTime);
            end
            title(ax, ttl); legend(ax, names, 'Location', 'northwest'); grid(ax, 'on');

            app.draw3D(app.Ax3D, M, idx, false);
        end

        function draw3D(app, ax, M, idx, faded)
            Z = app.pad3(M.Z(idx, :));
            Zh = app.pad3(M.Z(app.Prep.isFit & app.Prep.isHealthy, :));
            step = max(1, floor(size(Zh,1) / 800));
            cla(ax); hold(ax, 'on');
            scatter3(ax, Zh(1:step:end,1), Zh(1:step:end,2), Zh(1:step:end,3), 6, [0.75 0.85 0.75], 'filled');
            if faded
                plot3(ax, Z(:,1), Z(:,2), Z(:,3), '-', 'Color', [0.85 0.85 0.85]);
            else
                scatter3(ax, Z(:,1), Z(:,2), Z(:,3), 24, M.score(idx), 'filled');
                plot3(ax, Z(:,1), Z(:,2), Z(:,3), '-', 'Color', [0.6 0.6 0.6]);
            end
            hold(ax, 'off');
            colormap(ax, [linspace(0.2,0.93,32)', linspace(0.65,0.69,32)', linspace(0.3,0.13,32)'; ...
                          linspace(0.93,0.85,32)', linspace(0.69,0.15,32)', linspace(0.13,0.15,32)']);
            caxis(ax, [0 1]); cb = colorbar(ax); cb.Label.String = 'Anomaly score';
            xlabel(ax, 'PC1'); ylabel(ax, 'PC2'); zlabel(ax, 'PC3');
            title(ax, 'Engine-health map (pale green = fleet healthy region)');
            grid(ax, 'on'); view(ax, 35, 22);
        end

        function Z = pad3(~, Z)
            if size(Z, 2) < 3, Z(:, end+1:3) = 0; end
            Z = Z(:, 1:3);
        end

        function plotCompare(app)
            C = app.Cmp; if isempty(C), return; end
            app.CmpTable.Data = table(C.names, C.classical, C.quantum, ...
                'VariableNames', {'Metric', 'Classical_PCA', 'qPCA'});
            k = C.k;
            ax = app.AxEig; cla(ax);
            bar(ax, [app.CP.lambda(1:k), app.QP.lambda(1:k)]);
            set(ax, 'XTick', 1:k);
            xlabel(ax, 'Principal component'); ylabel(ax, 'Eigenvalue \lambda');
            legend(ax, {'Classical PCA', 'qPCA'}, 'Location', 'northeast');
            title(ax, sprintf('Eigenvalues (mean rel. error %.2f %%)', C.quantum(3))); grid(ax, 'on');

            idx = (app.Data.unit == app.EngineDD.Value);
            cyc = app.Data.cycle(idx);
            ax = app.AxCmpScore; cla(ax); hold(ax, 'on');
            plot(ax, cyc, C.mc.score(idx), '-', 'Color', [0.10 0.35 0.75], 'LineWidth', 2);
            plot(ax, cyc, C.mq.score(idx), '--', 'Color', [0.85 0.15 0.15], 'LineWidth', 2);
            plot(ax, [1 max(cyc)], [0.6 0.6], ':k');
            hold(ax, 'off'); ylim(ax, [0 1.05]); xlim(ax, [1 max(cyc)]);
            xlabel(ax, 'Engine cycle'); ylabel(ax, 'Anomaly score');
            legend(ax, {'Classical PCA', 'qPCA', 'threshold'}, 'Location', 'northwest');
            title(ax, sprintf('Engine %d: anomaly score from both methods', app.EngineDD.Value));
            grid(ax, 'on');
        end
    end
end
