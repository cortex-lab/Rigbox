classdef DigitalOnOff < hw.ControlSignalGenerator
    %HW.DIGITALONOFF Digital HIGH/LOW switch
    %   Currently converts input to either HIGH or LOW digital output. In the
    %   future timed switch should be introduced.
    %
    % See also HW.DAQCONTROLLER
    %
    % Part of Rigbox
    
    % 2017-07 MW created
    
    properties
        OnValue = 5 % The HIGH voltage to output
        OffValue = 0 % The LOW voltage to output
        NumBits = 1 % The number of bits this output controls
        ParamsFun = @(in) logical(in); % Converts input to logical
    end
    
    methods
        function obj = DigitalOnOff()
            % DefaultValue is a property of the superclass
            % ControlSignalGenerator. Assign it a value here. 
            obj.DefaultValue = obj.OffValue * ones(1,obj.NumBits);
        end
        
        function set.NumBits(obj, numBits)
            obj.NumBits = numBits;
            obj.DefaultValue = obj.OffValue * ones(1,obj.NumBits);
        end
        
        function out = waveform(obj, ~, command)
            out = obj.ParamsFun(command);
        end
    end
    
end

