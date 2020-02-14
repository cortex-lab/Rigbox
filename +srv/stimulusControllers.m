function sc = stimulusControllers
%SRV.STIMULUSCONTROLLERS Load all configured remote stimulus controllers
%   Loads the remote rigs available to mc.  The configured controllers are
%   expected to be an array of srv.StimulusControl objects named
%   'stimulusControllers', loaded from a file called 'remote.mat' in the
%   paths globalConfig directory.  The list is returned ordered
%   alphabetically by the Name property.
%
%   Output:
%     An array of srv.StimulusControl objects
%
%   Examples:
%     % Save a couple of configurations for loading with this function
%     stimulusControllers = [
%       srv.StimulusControl.create('BigRig', 'ws://desktop-187'),
%       srv.StimulusControl.create('TestRig')];
%     configDir = getOr(dat.paths, 'globalConfig');
%     save(fullfile(configDir, 'remote.mat'), 'stimulusControllers')
%     
%     % Load the stimulus controllers from file
%     sc = srv.stimulusControllers;
%
% See also SRV.STIMULUSCONTROL, EUI.MCONTROL
%
% Part of Rigbox

% 2013-06 CB created

p = dat.paths;

sc = loadVar(fullfile(p.globalConfig, 'remote.mat'), 'stimulusControllers');
% Order alphabetically
[~, I] = sort(arrayfun(@(o)o.Name, sc, 'UniformOutput', false));
sc = sc(I);
end

