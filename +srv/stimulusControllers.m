function sc = stimulusControllers
%SRV.STIMULUSCONTROLLERS Load all configured remote stimulus controllers
%   TODO. See also SRV.STIMULUSCONTROL.
%
% Part of Rigbox

% 2013-06 CB created

p = dat.paths;

sc = loadVar(fullfile(p.globalConfig, 'remote.mat'), 'stimulusControllers');
% Order alphabetically
[~, I] = sort(arrayfun(@(o)o.Name, sc, 'UniformOutput', false));
sc = sc(I);
end

