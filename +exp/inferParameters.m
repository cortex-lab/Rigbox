function parsStruct = inferParameters(expdef)
%EXP.INFERPARAMETERS Infers the parameters required for experiment
%   Detailed explanation goes here

% create some signals just to pass to the definition function and track
% which parameter names are used

if ischar(expdef) && file.exists(expdef)
  expdeffun = fileFunction(expdef);
else
  expdeffun = expdef;
  expdef = which(func2str(expdef));
end

net = sig.Net;
e = struct;
e.t = net.origin('t');
e.events = net.subscriptableOrigin('events');
e.pars = net.subscriptableOrigin('pars');
e.pars.CacheSubscripts = true;
e.visual = net.subscriptableOrigin('visual');
e.audio = net.subscriptableOrigin('audio');
e.inputs = net.subscriptableOrigin('inputs');
e.outputs = net.subscriptableOrigin('outputs');

try
  expdeffun(e.t, e.events, e.pars, e.visual, e.inputs , e.outputs);
  % paramNames will be the strings corresponding to the fields of e.pars
  % that the user tried to reference in her expdeffun.
  paramNames = e.pars.Subscripts.keys';
  %The paramValues are signals corresponding to those parameters and they
  %will all be empty, except when they've been given explicit numerical
  %definitions right at the end of the function - and in that case, we'll
  %take those values (extracted into matlab datatypes, from the signals,
  %using .Node.CurrValue) to be the desired default values.
  paramValues = e.pars.Subscripts.values';
  parsStruct = cell2struct(cell(size(paramNames)), paramNames);
  for i = 1:size(paramNames,1)
      parsStruct.(paramNames{i}) = paramValues{i}.Node.CurrValue;
  end
  parsStruct.numRepeats = 0; % add 'numRepeats' parameter
  parsStruct.defFunction = expdef;
  parsStruct.type = 'custom';
catch ex
  net.delete();
  rethrow(ex)
end

net.delete();


end