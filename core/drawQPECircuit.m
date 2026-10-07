function drawQPECircuit(ax, t, n)
%DRAWQPECIRCUIT Schematic of the phase-estimation circuit used by quantumPCA.
%   t ancilla (phase) qubits, n system qubits holding rho.
cla(ax); hold(ax, 'on');
shown = min(t, 3);                       % draw at most 3 ancilla wires
yAnc  = (shown:-1:1) + 1.2;
ySys  = 0.6;
xEnd  = 3 + shown*1.5 + 4.2;
blue  = [0.10 0.35 0.75]; grey = [0.25 0.25 0.25];

for i = 1:shown
    plot(ax, [0.6 xEnd], [yAnc(i) yAnc(i)], '-', 'Color', grey, 'LineWidth', 1);
    if i == shown && t > shown
        lbl = sprintf('a_{%d}', t-1);
    else
        lbl = sprintf('a_{%d}', i-1);
    end
    text(ax, 0.5, yAnc(i), ['|0\rangle  ' lbl], 'HorizontalAlignment', 'right', 'FontSize', 11);
    box(ax, 1.3, yAnc(i), 0.7, 0.6, 'H', [1 1 1], grey);
end
if t > shown
    text(ax, 0.2, (yAnc(end-1)+yAnc(end))/2, '\vdots', 'HorizontalAlignment', 'right', 'FontSize', 12);
end
plot(ax, [0.6 xEnd], [ySys ySys], '-', 'Color', blue, 'LineWidth', 3);
text(ax, 0.5, ySys, sprintf('\\rho  (%d qubits)', n), 'HorizontalAlignment', 'right', ...
    'FontSize', 11, 'Color', blue);

for i = 1:shown
    x = 3 + (i-1)*1.5;
    if i == shown && t > shown
        p = sprintf('U^{2^{%d}}', t-1);
    elseif i == 1
        p = 'U';
    else
        p = sprintf('U^{%d}', 2^(i-1));
    end
    plot(ax, [x x], [ySys+0.35 yAnc(i)], '-', 'Color', grey, 'LineWidth', 1);
    plot(ax, x, yAnc(i), 'o', 'MarkerFaceColor', grey, 'MarkerEdgeColor', grey, 'MarkerSize', 7);
    box(ax, x, ySys, 1.2, 0.7, p, [0.88 0.93 1], blue);
end

xq = 3 + shown*1.5 + 0.6;
yMid = mean(yAnc); hq = (yAnc(1) - yAnc(end)) + 0.8;
box(ax, xq, yMid, 1.5, hq, 'QFT^{\dagger}', [1 0.95 0.85], [0.8 0.5 0.1]);
for i = 1:shown
    box(ax, xq + 2.0, yAnc(i), 0.8, 0.6, 'M', [0.92 0.92 0.92], grey);
end
text(ax, xq + 2.7, yMid, '\rightarrow  m \approx \lambda\cdot2^{t}', 'FontSize', 11);
text(ax, xq + 2.0, ySys - 0.55, '\rightarrow eigenvector |v_\lambda\rangle', ...
    'HorizontalAlignment', 'center', 'FontSize', 10, 'Color', blue);
text(ax, 3 + (shown-1)*0.75, ySys - 0.6, 'U = e^{2\pi i \rho}', ...
    'HorizontalAlignment', 'center', 'FontSize', 10, 'Color', blue);

hold(ax, 'off');
set(ax, 'XLim', [-2.2 xEnd + 2.6], 'YLim', [-0.4 yAnc(1) + 0.8], ...
    'XTick', [], 'YTick', [], 'Box', 'on');
title(ax, sprintf('Quantum phase estimation: %d phase qubits + %d system qubits', t, n));
end

function box(ax, x, y, w, h, str, face, edge)
rectangle('Parent', ax, 'Position', [x-w/2, y-h/2, w, h], 'FaceColor', face, ...
    'EdgeColor', edge, 'LineWidth', 1.2, 'Curvature', 0.15);
text(ax, x, y, str, 'HorizontalAlignment', 'center', 'FontSize', 11);
end
