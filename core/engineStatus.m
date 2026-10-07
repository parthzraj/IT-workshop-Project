function S = engineStatus(score, cycle, H)
%ENGINESTATUS Final health call for one engine from its score history.
S.score = score(end);
if S.score >= H.alert
    S.label = 'HIGH ANOMALY';       S.color = [0.85 0.15 0.15];
elseif S.score >= H.warn
    S.label = 'EARLY DEGRADATION';  S.color = [0.93 0.69 0.13];
else
    S.label = 'NORMAL';             S.color = [0.20 0.65 0.30];
end
% first alarm = first cycle from which the score stays above warn for 3 cycles
above = score(:) >= H.warn;
S.alarmCycle = NaN;
for i = 1:numel(above)-2
    if all(above(i:i+2)), S.alarmCycle = cycle(i); break; end
end
S.leadTime = cycle(end) - S.alarmCycle;   % cycles of warning before end of record
end
