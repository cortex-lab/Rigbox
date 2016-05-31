classdef ExponentialInterval < exp.TimeSampler
  %EXP.EXPONENTIALINTERVAL A time sampled with a flat hazard function
  %   TODO. See also EXP.TIMESAMPLER
  %
  % Part of Rigbox
  
  % 2014-06 NS created
  % 2014-07 CB sanitised

  properties
    Min %The minimum time
    Max %The maximum time
    Lambda% The time constant
  end
  
  methods
    function obj = ExponentialInterval(min, max, lambda)
      obj.Min = min;
      obj.Max = max;
      obj.Lambda = lambda;
    end
    
    function t = secs(obj)
      t = obj.Min + exprnd(obj.Lambda);
      if t > obj.Max
        t = obj.Max;
      end
    end
  end
  
end

