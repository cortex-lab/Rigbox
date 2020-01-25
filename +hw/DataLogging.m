classdef DataLogging < handle
  %DataLogging Abstract class that can log some values and associated times
  %   Detailed explanation goes here
  %
  % Part of Rigbox

  % 2012-11 CB created
  
  properties
    Clock = hw.ptb.Clock
  end
  
  properties (SetAccess = protected)
    SampleCount = 0
  end
  
  properties (Access = protected)
    DataBuffer = []
    TimesBuffer = []
  end
  
  methods
    function clearData(obj)
      obj.SampleCount = 0;
      obj.DataBuffer = zeros(length(obj.DataBuffer), 1);
      obj.TimesBuffer = zeros(length(obj.DataBuffer), 1);
    end
    
    function n = bufferSize(obj)
      n = length(obj.DataBuffer);
    end
    
    function accommodateBuffers(obj, n)
      % n: number of extra spaces needed in buffer
      if nargin < 2
        n = 1; % default extra spaces is 1
      end
      % makes sure the data buffers are large enough to handle more data
      currLen = length(obj.DataBuffer);
      lenNeeded = obj.SampleCount + n;
      if currLen < lenNeeded
        % at least double the sizes of the arrays
        extra = max(n, currLen);
        obj.DataBuffer = [obj.DataBuffer ; zeros(extra, 1)];
        obj.TimesBuffer = [obj.TimesBuffer ; zeros(extra, 1)];
      end
    end
  end

  methods (Access = protected)
    function logSample(obj, value, time)
      if nargin < 3
        time = obj.Clock.now;
      end
      accommodateBuffers(obj);
      obj.SampleCount = obj.SampleCount + 1;
      obj.DataBuffer(obj.SampleCount) = value;
      obj.TimesBuffer(obj.SampleCount) = time;
    end

    function logSamples(obj, values, times)
      nValues = length(values);
      accommodateBuffers(obj, nValues);
      fromIdx = obj.SampleCount + 1;
      toIdx = obj.SampleCount + nValues;
      obj.SampleCount = obj.SampleCount + nValues;
      obj.DataBuffer(fromIdx:toIdx) = values;
      obj.TimesBuffer(fromIdx:toIdx) = times;
    end
  end
  
end