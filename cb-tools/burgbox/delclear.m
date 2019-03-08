function delclear(h)
%DELCLEAR deletes a graphics object, and clears a variable referencing that
% object from the called workspace
%
% Inputs:
%   `var`: variable to be cleared from the workspace
%
% Example:
%   h = figure;
%   delclear(h); % deletes the figure object, and clears `f` from workspace
  delete(h);
  
  name=inputname(1);
  if ~isempty(name)
      evalin('caller', ['clear ',inputname(1)]) ;
  else
      warning 'Deleted, but not cleared.'
  end
  
end

