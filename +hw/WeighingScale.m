classdef WeighingScale < handle
  %HW.WEIGHINGSCALE Interface to a weighing scale connected via serial
  %   Allows you to read the current weight from scales and tare it.  This
  %   class has been tested only with the ES-300HA 300gx0.01g Precision
  %   Scale + RS232 to USB Converter.
  %
  % Part of Rigbox

  % 2013-02 CB created  
  
  properties
    ComPort = 'COM1'
    TareCommand = hex2dec('54')
    Port = []
    WeightRange = [20, 25]; % Weight range for fake reading
  end
  
  properties (Access = protected)
    LastGrams = []
  end
  
  properties (Hidden)
    Timer = []
  end
  
  events
    NewReading
  end
  
  methods
    function tare(obj)
%       fprintf(obj.Port, obj.TareCommand);
      obj.LastGrams = 0;
      obj.WeightRange = [-1, 1];
    end
    
    function g = readGrams(obj)
      g = obj.LastGrams;
    end
    
    function init(obj)
      fprintf('Opened scales on "%s"\n', obj.ComPort);
      obj.Timer = timer('Period', 0.5, 'ExecutionMode', 'fixedSpacing',...
        'BusyMode', 'drop', 'StartDelay', 5,...
        'TimerFcn', @(src, evt)onBytesAvail(obj, src, evt));
%       start(obj.Timer);
    end
    
    function cleanup(obj)
      if ~isempty(obj.Timer)
        if strcmp(obj.Timer.Running, 'on')
          stop(obj.Timer);
        end
        delete(obj.Timer);
        obj.Timer = [];
      end
      if ~isempty(obj.Port)
%         set(obj.Port, 'BytesAvailableFcn', '');
%         fclose(obj.Port);
        obj.Port = [];
        fprintf('Closed scales on "%s"\n', obj.ComPort);
      end
    end
    
    function delete(obj)
      cleanup(obj);
    end
    
    function onBytesAvail(obj, ~, ~)
        g = obj.WeightRange;
        obj.LastGrams = round((g(2)-g(1)).*rand(1,1) + g(1), 2, 'decimals');
        pause(randi([0, 2],1,1))
        notify(obj, 'NewReading');
    end
  end
  
end

