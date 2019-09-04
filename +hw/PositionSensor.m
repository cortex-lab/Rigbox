classdef PositionSensor < hw.DataLogging
  %HW.POSITIONSENSOR Abstract class for tracking positions from a sensor
  %   Takes care of logging positions and times every time readPosition is
  %   called. Has a zeroing function and a gain parameter.  This class is
  %   intended only for linear position sensors.
  %
  % Part of Rigbox

  % 2012-11 CB created

  properties
    MillimetresFactor %Factor to convert position to millimetre units
  end

  properties (Dependent, Transient)
    Positions %All recorded positions
    PositionTimes %Times for each recorded position
    LastPosition %Most recent position read
  end
  
  properties (SetAccess = protected)
    ZeroOffset = 0
  end

  methods (Abstract)%, Access = protected)
    [x, time] = readAbsolutePosition(obj)
  end

  methods
    function value = get.Positions(obj)
      value = obj.DataBuffer(1:obj.SampleCount);
    end

    function value = get.PositionTimes(obj)
      value = obj.TimesBuffer(1:obj.SampleCount);
    end
    
    function value = get.LastPosition(obj)
      value = [];
      if obj.SampleCount
        value = obj.DataBuffer(obj.SampleCount);
      end
    end

    function zero(obj, log)
      % zeros the position counter relative to sensor current position, and if 
      % (optional) log is true, will log that zero in Positions and PositionTimes
      if nargin < 2
        log = false; % by default don't log zero at this time
      end
      [x, time] = readAbsolutePosition(obj);
      obj.ZeroOffset = x;
      if log
        logSample(obj, 0, time);
      end
    end

    function [pos, time, changed] = readPosition(obj)
      % reads, logs and returns the current position. Also records
      % the time the reading was made (according to the clock)
      [absPos, time] = readAbsolutePosition(obj);
      pos = absPos - obj.ZeroOffset;
      if obj.SampleCount < 1
        % first sample, so say it has changed
        changed = true;
      else
        % changed if this sample is different from the last
        changed = pos ~= obj.DataBuffer(obj.SampleCount);
      end
      logSample(obj, pos, time);
    end
  end
  
end

