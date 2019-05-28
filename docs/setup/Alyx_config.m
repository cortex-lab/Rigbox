%% Setting up Alyx
% Alyx is an...
% Info on setting up database instance
% Add submodule:
git.install('alyx-matlab'); %TODO some code that runs init on this submodule

% To activate Alyx
opentoline(which('eui.MControl'),755,46)
% obj.AlyxPanel = eui.AlyxPanel(headerBox);

% Default database url
url = getOr(dat.paths, 'databaseURL');

%% More info:
opentoline(which('Examples.m'),1,1)