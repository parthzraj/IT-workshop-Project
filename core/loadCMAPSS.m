function data = loadCMAPSS(folder, subset)
%LOADCMAPSS Load a NASA C-MAPSS training file (run-to-failure trajectories).
%   data = loadCMAPSS(folder, 'FD001') reads <folder>/train_FD001.txt
if nargin < 2, subset = 'FD001'; end
file = fullfile(folder, ['train_' subset '.txt']);
if ~exist(file, 'file')
    error('QEngine:noData', ...
        'Cannot find %s.\nDownload C-MAPSS and put train_%s.txt in that folder.', file, subset);
end
M = load('-ascii', file);
data = packCMAPSS(M, subset);
end
