classdef DigitalInput < hw.DataLogging
  % HW.DigitalInput class for accepting digital input
  %
  % Part of Rigbox

  % 2018-07 KJM created

  
 
%% Properties
  properties (Dependent = true)
    Inputs % All recorded positions
    InputTimes % Times for each recorded position
    LastInput % Most recent position read
    
    DaqChannelIdx % Index into DaqSession's channels for our data
  end
  
  
  properties
    % DAQ session for input (see session-based interface docs)
    DaqSession = []
    % DAQ's device ID, e.g. 'Dev1'
    DaqId = 'Dev1'
    % DAQ's ID for the digital channel. e.g. 'ctr0'
    DaqChannelId = 'pfi2'
  end
  
  
  properties (Access = protected)
    % Index into acquired input data matrices for our channel
    DaqInputChannelIdx
    % Last value obtained from the DAQ counter Accumulated cycle number for
    % position (i.e. when the DAQ's counter has over- or underflowed its
    % range, this is incremented or decremented accordingly)
    LastDaqValue
  end
  
  properties (Transient, Access = protected)
    % Created when listenForAvailableData is called, allowing logging of
    % positions during DAQ background acquision
    DaqListener
    
  end
  
  
  
  
  %% Methods for getting and setting
  methods
    function value = get.Inputs(obj)
      value = obj.DataBuffer(1:obj.SampleCount);
    end

    function value = get.InputTimes(obj)
      value = obj.TimesBuffer(1:obj.SampleCount);
    end
    
    function value = get.LastInput(obj)
      value = [];
      if obj.SampleCount
        value = obj.DataBuffer(obj.SampleCount);
      end
    end

    function value = get.DaqChannelIdx(obj)
      inputs = find(strcmpi('input', io.daqSessionChannelDirections(obj.DaqSession)));
      value = inputs(obj.DaqInputChannelIdx);
      
      
    end
    
    function set.DaqChannelIdx(obj, value)
      % get directions of all channels on this session
      dirs = io.daqSessionChannelDirections(obj.DaqSession);
      % logical array flagging all input channels
      inputsUptoChannel = strcmp(dirs(1:value), 'Input');
      % ensure the channel we're setting is an input
      assert(inputsUptoChannel(value), 'Channel %i is not an input', value);
      % find channel number counting inputs only
      obj.DaqInputChannelIdx = sum(inputsUptoChannel);
    end
    
  end
  
  %% Methods for reading data
  methods
    
    function [input, time, changed] = readInput(obj)
       % reads, logs, and returns the current input. Records the time
       if obj.DaqSession.IsRunning
        disp('waiting for session');
        obj.DaqSession.wait;
        disp('done waiting');
      end
      preTime = obj.Clock.now;
      daqVal = inputSingleScan(obj.DaqSession);
      input = daqVal(obj.DaqInputChannelIdx);
      postTime = obj.Clock.now;
      time = 0.5*(preTime + postTime); % time is mean of before & after
      
      if obj.SampleCount < 1
        % first sample, so say it has changed
        changed = true;
      else
        % changed if this sample is different from the last
        changed = input ~= obj.DataBuffer(obj.SampleCount);
      end
      logSample(obj, input, time);
    end

    
    
    function listenForAvailableData(obj)
      % adds a listener to the DAQ session that will receive and process
      % data when the DAQ is acquiring data in the background (i.e.
      % startBackground() has been called on the session).
      deleteListeners(obj);
      obj.DaqListener = obj.DaqSession.addlistener('DataAvailable', ...
        @(src, event) daqListener(obj, src, event));
    end
    
    function delete(obj)
      deleteListeners(obj);
    end
    
    function deleteListeners(obj)
      if ~isempty(obj.DaqListener)
        delete(obj.DaqListener);
      end
    end
    
    end
    
    
  
  methods (Access = protected)
    function daqListener(obj, ~, event)
      acqStartTime = obj.Clock.fromMatlab(event.TriggerTime);
      values = decode(obj, event.Data(:,obj.DaqInputChannelIdx)) - obj.ZeroOffset;
      times = acqStartTime + event.TimeStamps(:,obj.DaqInputChannelIdx);
      logSamples(obj, values, times);
    end
  end
  
 
  
   methods
    function createDaqChannel(obj)
      [ch, idx] = obj.DaqSession.addDigitalChannel(obj.DaqId, obj.DaqChannelId, 'InputOnly');
      obj.DaqChannelIdx = idx; % record the index of the channel
    end
    
  end
  
end

