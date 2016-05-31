classdef FixedTime < exp.TimeSampler
  %EXP.FIXEDTIME Always generates a fixed time
  %   TODO. See also EXP.TIMESAMPLER.
  %
  % Part of Rigbox

  % 2012-11 CB created  
  
  properties
    TimeSecs %Time always generated
  end
  
  methods
    function obj = FixedTime(secs)
      obj.TimeSecs = secs;
    end

    function t = secs(obj)
      t = obj.TimeSecs;
    end
  end
  
end

