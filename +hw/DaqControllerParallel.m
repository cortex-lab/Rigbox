classdef DaqControllerParallel < handle
       
    properties
        ChannelNames = {} % The name used to refer to each output in Signals
        %Signal generator for each output. Each should be an object of class
        %hw.ControlSignalGenerator, for generating command waveforms.
        SignalGenerators = hw.PulseSwitcher.empty
        DaqIds = 'Dev1' % device ID. If different outputs are on different devices, can be a cell e.g. {'Dev1', 'Dev1', 'Dev2'}
        DaqChannelIds = {} % DAQ's ID for the channels associated with each output, e.g. {{'ao0', 'ao1'}, {'port1/line0'}}
        SampleRate = 1000 % output sample rate ("scans/sec") of the daq device
        % 1000 is also the default of the ni daq devices themselves, so if
        % you don't change this, it doesn't actually do anything.
        OutputTypes % For now, outputs can be analog 'a' or digital 'd'. In the future, support could be added for counters
    end
    
    properties (Transient)
        DaqSessions
    end
    
    properties (Dependent)
        NumOutputs % Number of channels controlled
    end
    

    
    methods
        function createDaqChannels(obj)
            % Create session and channels for each output
            for output_i = 1:obj.NumOutputs
                % Make a session for this output
                obj.DaqSessions{output_i} = daq.createSession('ni');
                
                if iscell(obj.DaqIds)
                    daqid = obj.DaqIds{output_i};
                else
                    daqid = obj.DaqIds;
                end
                
                switch obj.OutputTypes(output_i)
                    case 'a' % output is analog
                        for channel_i = 1:length(obj.DaqChannelIds{output_i})
                            obj.DaqSessions{output_i}.Rate = obj.SampleRate;
                            obj.DaqSessions{output_i}.addAnalogOutputChannel(...
                                daqid, obj.DaqChannelIds{output_i}{channel_i}, 'Voltage');
                        end
                    case 'd' % output is digital
                        for channel_i = 1:length(obj.DaqChannelIds{output_i})
                            obj.DaqSessions{output_i}.addDigitalChannel(...
                                daqid, obj.DaqChannelIds{output_i}{channel_i}, 'OutputOnly');
                        end
                    otherwise
                        warning('Unknown output type')
                end
            end
            
            % Send default values to all channels
            obj.reset
        end
        
        
        function command(obj, outputName, values)
            
            % sends output to the daq channels controlled by the output
            % named in 'outputName'. This output's SignalGenerator will
            % receive 'values' as input, and must output something
            % appropriate for its channel type
            
            output_num = find(strcmp(obj.ChannelNames, outputName));
            assert(numel(output_num) == 1 && output_num > 0, 'Unknown output -- check that the name in your expDef matches the name in the hardware file')
            
            gen = obj.SignalGenerators(output_num);
            rate = obj.DaqSessions{output_num}.Rate;
            output = gen.waveform(rate, values);
            
            if obj.DaqSessions{output_num}.IsRunning
                % if a daq operation is in progress, stop it, and set its output
                % to the default value
                reset(obj);
            end
            
            switch obj.OutputTypes(output_num)
                case 'a' % Analog output
                    obj.DaqSessions{output_num}.queueOutputData(output);
                    startBackground(obj.DaqSessions{output_num});
                    readyWait(obj);
                    obj.DaqSessions{output_num}.release;
                    
                case 'd' % Digital output
                    obj.DaqSessions{output_num}.outputSingleScan(output);
            end
            
        end
        
        function v = get.NumOutputs(obj)
            v = numel(obj.ChannelNames);
        end
             
        function reset(obj)
            for sess_i = 1:obj.NumOutputs
                stop(obj.DaqSessions{sess_i});
            end
            
            for output_i = 1:obj.NumOutputs
                v = obj.SignalGenerators(output_i).DefaultValue;
                obj.command(obj.ChannelNames{output_i}, v);
            end
            
        end
    end
    
    methods (Access = protected)
        
        function readyWait(obj)
            for sess_i = 1:obj.NumOutputs
                obj.DaqSessions{sess_i}.IsRunning
                obj.DaqSessions{sess_i}.wait();
            end
        end
    end
    
end

