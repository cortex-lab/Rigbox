classdef WeighingScale < handle
  %HW.WEIGHINGSCALE Interface to a weighing scale connected via serial
  %   Allows you to read the current weight from scales and tare it.  This
  %   class has been tested only with the ES-300HA 300gx0.01g Precision
  %   Scale, and Ohaus SPX222 Scout Portable Balance 220G x 0.01g + RS232
  %   to USB Converter.
  %
  % Part of Rigbox
  
  % 2013-02 CB created
  
  properties
    Name = 'ES-300HA' % 'SPX222'
    ComPort = 'COM1'
    TareCommand = hex2dec('54') % For SPX222 use 'T'
    FormatSpec = '%s %f %*s' % For SPX222 use '%f'
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
        switch obj.Name
          case 'SPX222'
            % Optional settings may be set manually instead
            fprintf(obj.Port, 'IP'); % Auto print stable non-zero weight and stable zero reading
            fprintf(obj.Port, '1M'); % Weight mode
            fprintf(obj.Port, '1U'); % Weight unit grammes
          otherwise
            % Do nothing
        end
      end
      obj.tare(); % Tare the scale to ensure LastGrams is never empty
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
    
    function onBytesAvail(obj, src, ~)
      nr = src.BytesAvailable/13;
      for i = 1:nr
        g = sscanf(fscanf(src), obj.FormatSpec);
        if length(g) > 1 && g(1) == 45
          g = -g(2); % 45 == '-'
        elseif length(g) > 1 && g(1) == 43
          g = g(2); % 43 == '+'
        end
        obj.LastGrams = g;
        notify(obj, 'NewReading');
      end
    end
  end
  
end
