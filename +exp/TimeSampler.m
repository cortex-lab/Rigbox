classdef TimeSampler
  %EXP.TIMESAMPLER Interface for generating times from some distribution
  %   TODO. See also EXP.FIXEDTIME, EXP.UNIFORMINTERVAL
  %
  % Part of Rigbox
  
  % 2012-11 CB created
  
  properties
  end
  
  methods (Abstract)
    t = secs(obj)
  end
  
  methods (Static)
    function sampler = using(time)
      %Factory method for creating an appropriate TimeSampler for given
      %parameters.
      sampler = [];
      if isreal(time)
        if isscalar(time)
          % passed a scalar: set the delay to an equivalent FixedTime
          sampler = exp.FixedTime(time);
        elseif numel(time) == 2
          % 2 parameters indicates an interval: set the delay to an
          % equivalent exp.UniformInterval
          sampler = exp.UniformInterval(time(1), time(2));
        elseif numel(time) == 3
          % 3 parameters indicates a times drawn from a distribution with a
          % a flat hazard function, with params as [min, max, time const]
          sampler = exp.ExponentialInterval(time(1), time(2), time(3));
        else
          error('Unknown format for creating an exp.TimeSampler');
        end
      elseif isa(time, 'exp.TimeSampler')
        sampler = time;
      end
      if isempty(sampler)
        error('Invalid time value');
      end
    end
  end
  
end

