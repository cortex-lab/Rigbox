function history = funSpy(varargin)
persistent log

if isempty(log)
  log = containers.Map('KeyType', 'double', 'ValueType', 'any');
end
log(now) = varargin;
end