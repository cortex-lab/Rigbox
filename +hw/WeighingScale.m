classdef WeighingScale < handle
  %HW.WEIGHINGSCALE Interface to a weighing scale connected via serial
  %   Allows you to read the current weight from scales and tare it.
  %
  % Part of Rigbox

  % 2013-02 CB created  
  
  properties
    ComPort = 'COM1'
    TareCommand = hex2dec('54')
    Port = []
  end
  
  properties (Access = protected)
    LastGrams = []
  end
  
  events
    NewReading
  end
  
  methods
    function tare(obj)
      fprintf(obj.Port, obj.TareCommand);
      obj.LastGrams = 0;
    end
    
    function g = readGrams(obj)
      g = obj.LastGrams;
    end
    
    function init(obj)
      if isempty(obj.Port)
        obj.Port = serial(obj.ComPort, 'InputBufferSize', 32768);
        set(obj.Port, 'BytesAvailableFcn', @obj.onBytesAvail);
        fopen(obj.Port);
        fprintf('Opened scales on "%s"\n', obj.ComPort);
      end
    end
    
    function cleanup(obj)
      if ~isempty(obj.Port)
        set(obj.Port, 'BytesAvailableFcn', '');
        fclose(obj.Port);
        obj.Port = [];
        fprintf('Closed scales on "%s"\n', obj.ComPort);
      end
    end
    
    function delete(obj)
      cleanup(obj);
    end
    
    function onBytesAvail(obj, src, evt)
      nr = src.BytesAvailable/13;
      for i = 1:nr
        d = sscanf(fscanf(src),'%s %f %*s');
        g = d(2);
        if d(1) == 45
          g = -g;
        end
        obj.LastGrams = g;
        notify(obj, 'NewReading');
      end
    end
  end
  
end

