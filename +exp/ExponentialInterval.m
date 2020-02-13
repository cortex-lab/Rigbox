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
      % Draw a random value from an exponential distribution by applying
      % the exponential inverse CDF.
      r = -obj.Lambda * log(rand);
      t = obj.Min + r;
      if t > obj.Max
        t = obj.Max;
      end
    end
  end
  
end

