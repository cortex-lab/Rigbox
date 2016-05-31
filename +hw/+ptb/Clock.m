classdef Clock < hw.Clock
  %HW.PTB.CLOCK A hw.Clock that uses Psychtoolbox GetSecs
  %   This clock returns time as counted by Psychtoolbox's GetSecs 
  % function. See also hw.Clock.
  %
  % Part of Rigbox

  % 2012-10 CB created
  
  methods (Access = protected)
    function t = absoluteTime(obj)
      t = GetSecs;
    end
  end
  
end