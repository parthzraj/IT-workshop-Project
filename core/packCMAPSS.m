function data = packCMAPSS(M, name)
%PACKCMAPSS Convert a raw 26-column C-MAPSS matrix into a struct.
%   Columns: 1 unit | 2 cycle | 3-5 operating settings | 6-26 sensors 1..21
if size(M,2) < 26
    error('QEngine:format', 'Expected 26 columns, found %d.', size(M,2));
end
data.name     = name;
data.unit     = M(:,1);
data.cycle    = M(:,2);
data.settings = M(:,3:5);
data.sensors  = M(:,6:26);
data.units    = unique(data.unit);
data.life     = zeros(size(data.unit));   % total life of the engine the row belongs to
for u = data.units(:)'
    idx = (data.unit == u);
    data.life(idx) = max(data.cycle(idx));
end
data.rul = data.life - data.cycle;        % remaining useful life (run-to-failure data)
end
