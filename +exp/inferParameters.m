function parsStruct = inferParameters(expdef)
%EXP.INFERPARAMETERS Infers the parameters defined in an exp def
%
% Inputs:
% 'expdef': the "experiment definition" .m file from which the parameters
% are inferred. This argument can be set as a string or function handle
%
% Outputs:
% 'parsStruct': the inferred parameters, returned as a MATLAB struct
%
% Example:
%   parsStruct = exp.inferParameters([fileparts(which('addRigboxPaths'))...
%     '\signals\doc\examples\expdefs\...']);
%
%  fh = @...
%  parsStruct = exp.inferParameters(fh)
%
% See also:
%
% todo: update example

try
  if ischar(expdef) && file.exists(expdef) % if 'expdef' is a string
    expdeffun = fileFunction(expdef);
  else % if 'expdef' is a function handle
    expdeffun = expdef;
    expdef = which(func2str(expdef));
  end
catch ex
  error(['Input argument must be a string of the full filename,'... 
    'or a function handle']);
end

% create some signals just to pass to the exp def and track which parameter
% names are used
e = sig.void;
pars = sig.void(true);
audio.Devices = @dummyDev;

% try to call the exp def file get the parameters defined in the file
try
  expdeffun(e.t, e.events, pars, e.visual, e.inputs, e.outputs, audio);
  parsStruct = pars.Subscripts;
  
  % Check for reserved fieldnames
  reserved = {'randomiseConditions', 'services', 'expPanelFun', ...
    'numRepeats', 'defFunction', 'waterType', 'isPassive'};
  assert(~any(ismember(fieldnames(parsStruct), reserved)), ...
    'exp:InferParameters:ReservedParameters', ...
    'The following param names are reserved:\n%s', ...
    strjoin(intersect(fieldnames(parsStruct), reserved), ', '))
  
  szFcn = @(a)iff(ischar(a), @()size(a,1), @()size(a,2));
  sz = iff(isempty(fieldnames(parsStruct)), 1,... % if there are no paramters sz = 1
      structfun(szFcn, parsStruct)); % otherwise get number of columns
  % add 'numRepeats' parameter, where total number of trials = 1000
  parsStruct.numRepeats = ones(1,max(sz))*floor(1000/max(sz));
  parsStruct.defFunction = expdef;
  parsStruct.type = 'custom';
  % Define the ExpPanel to use (automatically by name convention for now)
  [path, name, ext] = fileparts(expdef);
  ExpPanel_name = [name 'ExpPanel'];
  ExpPanel_fn = [path filesep ExpPanel_name ext];
  if exist(ExpPanel_fn,'file'); parsStruct.expPanelFun = ExpPanel_name; end
catch ex
  rethrow(ex)
end

  function dev = dummyDev(~)
    % Returns a dummy audio device structure, regardless of input
    %   Returns a standard structure with values for generating tone
    %   samples.  This function gets around the problem of querying the
    %   rig's audio devices when inferring parameters.
    dev = struct('DeviceIndex', -1,...
          'DefaultSampleRate', 44100,...
          'NrOutputChannels', 2);
  end
end
