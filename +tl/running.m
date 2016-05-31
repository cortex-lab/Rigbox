function b = running()
%TL.RUNNING Reports whether Timeline is currently running
%   b = TL.RUNNING() returns true if Timeline is currently running, false
%   otherwise.
% 
% Part of Rigbox

% 2014-01 CB created

global Timeline

b = false;

if isfield(Timeline, 'isRunning')
  if Timeline.isRunning
    b = true;
  end
end

end

