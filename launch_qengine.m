% LAUNCH_QENGINE  Start the Q-Engine Health Monitor app.
root = fileparts(mfilename('fullpath'));
addpath(root, fullfile(root, 'core'));
app = QEngineApp();
