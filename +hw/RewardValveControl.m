classdef RewardValveControl < hw.PulseSwitcher & handle
  %HW.REWARDVALVECONTROL Controls a valve via a DAQ to deliver reward
  %   Must (currently) be sole outputer on DAQ session
  %   TODO
  %
  % Part of Rigbox
  
  % 2013-01 CB created
  
  properties
    Calibrations
    
    % deliveries with measured volumes for calibration.
    % This should be a struct array with fields 'durationSecs' &
    % 'volumeMicroLitres' indicating the duration the valve was open, and the
    % measured volume (in ul) for that delivery. These points are interpolated
    % to work out how long to open the valve for arbitrary volumes.
  end
  
  methods
    function obj = RewardValveControl()
      obj@hw.PulseSwitcher;
      obj.ParamsFun = @obj.pulseParams;
    end
    
    function dt = pulseDuration(obj, ul)
      % Returns the duration the valve should be opened for to deliver
      % microLitres of reward. Is calibrated using interpolation of the
      % measured delivery data.
      recent = obj.Calibrations(end).measuredDeliveries;
      
      volumes = [recent.volumeMicroLitres];
      durations = [recent.durationSecs];
      if ul > max(volumes) || ul < min(volumes)
        warning('Warning requested delivery of %.1f is outside calibration range',...
          ul);
      end
      dt = interp1(volumes, durations, ul, 'pchip');
    end
    
    function ul = sizeFromDuration(obj, dt)
      % Returns the amount of reward the valve would delivery by being open
      % for the duration specified. Is calibrated using interpolation of the
      % measured delivery data.
      volumes = [obj.MeasuredDeliveries.volumeMicroLitres];
      durations = [obj.MeasuredDeliveries.durationSecs];
      ul = interp1(durations, volumes, dt, 'pchip');
    end
    
    %     function ps = pulseGenerator(obj, nPulses, interval)
    %       ps = hw.PulseSwitcher;
    %       ps.ClosedValue = obj.ClosedValue;
    %       ps.OpenValue = obj.OpenValue;
    %       ps.DefaultSize = obj.DefaultSize;
    %       if nargin < 2
    %         nPulses = 1;
    %         interval = 0;
    %       elseif nargin < 3
    %         interval = 0.1;
    %       end
    %       ps.ParamsFun = @(sz) pulseParams(obj, sz, nPulses, interval);
    %     end
    
    function [duration, nPulses, freq] = pulseParams(obj, sz, nPulses, interval)
      if nargin < 3
        nPulses = 1;
        interval = 0;
      elseif nargin < 4
        interval = 0.1;
      end
      if sz > 0
        duration = pulseDuration(obj, sz);
        freq = 1/(duration + interval);
      else
        duration = 0;
        freq = 1000;
      end
    end
  end
  
end

