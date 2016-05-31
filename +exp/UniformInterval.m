classdef UniformInterval < exp.TimeSampler
  %EXP.UNIFORMINTERVAL A time sampled uniformly from an interval
  %   TODO. See also EXP.TIMESAMPLER
  %
  % Part of Rigbox
  
  % 2012-11 CB created
  
  properties
    Min %The minimum time
    Max %The maximum time
  end
  
  methods
    function obj = UniformInterval(min, max)
      obj.Min = min;
      obj.Max = max;
    end

    function t = secs(obj)
      t = obj.Min + (obj.Max - obj.Min)*rand;
    end
  end
  
end

