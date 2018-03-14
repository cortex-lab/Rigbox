classdef TimelineClock < hw.Clock
  %TimelineClock A Clock that uses Timeline time
  %   This clock returns time as counted by relative to Timeline's clock.
  %   See also hw.Clock.
  %
  % Part of Rigbox
  
  % 2013-01 CB created
  
  properties
      Timeline % Handle to rig timeline object
  end
  
  methods
      
    function obj = TimelineClock(tl)
      if nargin
        obj.Timeline = tl;
      end
    end
    
  end
  
  methods (Access = protected)
      
    function t = absoluteTime(obj)
      if isempty(obj.Timeline)
        t = tl.time;
      else
        t = obj.Timeline.time();
      end
    end
    
  end
  
end