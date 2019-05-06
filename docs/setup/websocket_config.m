%% Configuring WebSockets
% In order for the two computers to communicate...

% The stimulus controllers are loaded from a MAT file with the name
% 'remote' in the globalConfig directory, defined in dat.paths:
p = fullfile(getOr(dat.paths, 'globalConfig'), 'remote.mat');

% Let's create a new stimulus controller
name = ipaddress(hostname);
stimulusControllers = srv.StimulusControl.create(name);

% A note on adding new computers.  Do not simply copy objects, instead use
% the following method:
uri = 'ws://192.168.0.1:5000';
stimulusControllers(2) = srv.StimulusControl.create('rig2', uri);

% the stimulus controllers can be loaded using the srv.stimulusControllers
% function:
sc = srv.stimulusControllers;

%% Configuring Services
% srv.prepareExp
% srv.findService

%% UDP communication
