classdef RewardValveControl2 < hw.ControlSignalGenerator & handle
    %HW.REWARDVALVECONTROL Controls two reward valves
    %
    % Part of Rigbox
    
    % 2013-01 CB created
    % 2019-07 KJM modified to allow for a second reward valve
    
    properties
        Calibrations1 = struct('measuredDeliveries', struct('durationSecs', [0.1, 0.2], 'volumeMicroLitres', [1, 2]))
        Calibrations2 = struct('measuredDeliveries', struct('durationSecs', [0.1, 0.2], 'volumeMicroLitres', [1, 2]))
        % deliveries with measured volumes for calibration.
        % This should be a struct array with fields 'durationSecs' &
        % 'volumeMicroLitres' indicating the duration the valve was open, and the
        % measured volume (in ul) for that delivery. These points are interpolated
        % to work out how long to open the valve for arbitrary volumes.
        WaterType = 'Water'
        % The type of water dispenced by the rig.  This is used to populate the
        % water_type field in Alyx sessions.
        OpenValue = 5
        ClosedValue = 0
        %A function of command that returns [duration, number of pulses, freq]
        ParamsFun
    end
    
    methods
        function obj = RewardValveControl2()
            obj.DefaultValue = obj.ClosedValue * ones(1,2);
        end
        
        function samples = waveform(obj, sampleRate, command)
            
            % If there is only one number in the command, only open the
            % first valve
            if numel(command) == 1
               command = [command, 0]; 
            end
            assert(numel(command) == 2 || numel(command) == 1, ...
                ['Command to RewardValveControl2 must consist of one or numbers: '...
                'the number of microliters to deliver from each valve']);
            
            time1 = pulseDuration(obj, command(1), 1);
            time2 = pulseDuration(obj, command(2), 2);
            
            nSamples1 = round(sampleRate*time1);
            nSamples2 = round(sampleRate*time2);
            
            nSamplesAll = max(nSamples1, nSamples2) + 1;
            samples = obj.ClosedValue*ones(nSamplesAll,2);
            
            samples(1:nSamples1, 1) = obj.OpenValue;
            samples(1:nSamples2, 2) = obj.OpenValue;
            
        end
        
        
        
        
        
        function dt = pulseDuration(obj, ul, valve)
            % Returns the duration the valve should be opened for to deliver
            % microLitres of reward. Is calibrated using interpolation of the
            % measured delivery data.
            
            % For zero water: open the valve for zero time
            if ul == 0
                dt = 0;
                return
            end
            
            % Get the appropriate calibration
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
            
            % Use a linear fit to get correct valuve open time
            w = glmfit(volumes, durations);
            dt = w(1) + w(2)*ul;
            dt = max(dt, 0); % Don't let dt fall below zero
        end
        
       
        
    end
    
end

