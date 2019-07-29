classdef RewardValveControl2 < hw.ControlSignalGenerator & handle
    %HW.REWARDVALVECONTROL Controls two reward valves
    %
    % Part of Rigbox
    
    % 2013-01 CB created
    % 2019-07 KJM modified to allow for a second reward valve
    
    properties
        Calibrations1
        Calibrations2
        % deliveries with measured volumes for calibration.
        % This should be a struct array with fields 'durationSecs' &
        % 'volumeMicroLitres' indicating the duration the valve was open, and the
        % measured volume (in ul) for that delivery. These points are interpolated
        % to work out how long to open the valve for arbitrary volumes.
        WaterType = 'Water'
        % The type of water dispenced by the rig.  This is used to populate the
        % water_type field in Alyx sessions.
        OpenValue = 1
        ClosedValue = 0
        %A function of command that returns [duration, number of pulses, freq]
        ParamsFun
    end
    
    methods
        function obj = RewardValveControl2()
            obj.DefaultValue = obj.ClosedValue;
        end
        
        function samples = waveform(obj, sampleRate, command)
            assert(numel(command) == 2, ...
                ['Command to RewardValveControl2 must consist of two numbers: '...
                'the number of microliters to deliver from each valve']);
            
            time1 = pulseDuration(obj, command(1), 1);
            time2 = pulseDuration(obj, command(2), 2);
            
            nSamples1 = sampleRate*time1;
            nSamples2 = sampleRate*time2;
            
            samples(1,1:nSamples1) = obj.OpenValue;
            samples(2,1:nSamples2) = obj.OpenValue;
            samples(:,end) = obj.ClosedValue;
        end
        
        
        
        
        
        function dt = pulseDuration(obj, ul, valve)
            % Returns the duration the valve should be opened for to deliver
            % microLitres of reward. Is calibrated using interpolation of the
            % measured delivery data.
            if valve==1
                
                recent = obj.Calibrations1(end).measuredDeliveries;
            elseif valve == 2
                recent = obj.Calibrations2(end).measuredDeliveries;
            else
                error('Unknown valve number')
            end
            
            volumes = [recent.volumeMicroLitres];
            durations = [recent.durationSecs];
            if ul > max(volumes) || ul < min(volumes)
                warning('Warning requested delivery of %.1f is outside calibration range',...
                    ul);
            end
            dt = interp1(volumes, durations, ul, 'pchip');
        end
        
        
        
    end
    
end

