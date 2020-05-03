function result = runChecks(ref, varargin)
result = [];
% Load the parameters structure
params = dat.expParams(ref);
if isempty(params)
  warning('Rigbox:qc:paramsNotFound', ...
    'No experiment parameters found for %s', ref)
  return
end

% Load the block file
block = dat.loadBlock(ref);
if isempty(block)
  warning('Rigbox:qc:blockNotFound', ...
    'No experiment block found for %s', ref)
  return
end

switch params.type
  case 'custom'
    result = qc.SignalsExpQC(block).run(varargin{:});
  otherwise
    result = qc.ExperimentQC(block).run(varargin{:});
end

if file.exists(dat.expFilePath(ref, 'Timeline'))
  % TODO Timeline QC
  warning('Rigbox:qc:timelineChecksNotImplemented', 'Timeline QC checks not yet implemented')
%   timeline = load(dat.expFilePath(ref, 'Timeline'));
%   tlResult = qc.TimelineQC(load(dat.expFilePath(ref, 'Timeline'))).run;
  % result = [result, tlResult];
end