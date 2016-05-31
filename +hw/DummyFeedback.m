classdef DummyFeedback < hw.RewardController
  %HW.DUMMYFEEDBACK hw.RewardController implementation that does nothing
  %   Detailed explanation goes here
  %
  % Part of Rigbox

  % 2012-10 CB created  
  
  properties
  end
  
  methods
    function deliverBackground(obj, size)
      % do nothing for now
      fprintf('reward %f\n', size);
      logSample(obj, size, obj.Clock.now);
    end
    function deliverMultiple(obj, size, interval, n)
      % do nothing for now
    end
  end
end

