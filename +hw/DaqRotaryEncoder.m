classdef DaqRotaryEncoder < hw.PositionSensor
  %HW.DAQROTARYENCODER Tracks rotary encoder position from a DAQ
  %   Communicates with rotary encoder via a DAQ. Will configure a DAQ
  %   session counter channel for you, log position and times every time you
  %   call readPosition, and allows 'zeroing' at the current position. Also
  %   takes care of the DAQ counter overflow when ticking over backwards.
  %
  %   e.g. use:
  %     session = daq.createSession('ni')
  %     enc = RotaryEncoder  % I think this line should say: enc = hw.DaqRotaryEncoder % NS 2014-10-28
  %     enc.DaqSession = session
  %     enc.DaqId = 'Dev1'
  %     enc.createDaqChannel
  %     [x, time] = enc.readPosition
  %     enc.zero
  %     [x, time] = enc.readPosition
  %     X = enc.Positions
  %     T = enc.PositionTimes
  %
  %   If using a KÜBLER 2400 series encoder and an NI DAQ, calling
  %   createDaqChannel, then wiringInfo will give a specific wiring message
  %
  %   Note 1: using X4 encoding, we record all edges (up and down) from both
  %   channels for maximum resolution. This means that e.g. a KÜBLER 2400 with
  %   100 pulses per revolution will actually generate *400* position ticks per
  %   full revolution.
  %
  %   Note 2: For mouse standard Lego wheel & rotary encoder, set
  %   MillimetresFactor to 0.4869. This applies to Lego wheel used for mouse
  %   with 31mm radius. The standard KÜBLER rotary encoder is 100 pulses per
  %   revolution means the wheel period is 400 (see Note 1 above).
  %   Thus, 31*2*pi/400 ~ 0.4869 (i.e. this gives accuracy down to ~0.5mm)
  %
  % Part of Rigbox
  
  % 2013-01 CB created
  
  properties
    DaqSession = [] %DAQ session for input (see session-based interface docs)
    DaqId = 'Dev1' %DAQ's device ID, e.g. 'Dev1'
    DaqChannelId = 'ctr0' %DAQ's ID for the counter channel. e.g. 'ctr0'
    %Size of DAQ counter range for detecting over- and underflows (e.g. if
    %the DAQ's counter is 32-bit, this should be 2^32)
    DaqCounterPeriod = 2^32
  end
  
  properties (Access = protected)
    %Created when listenForAvailableData is called, allowing logging of
    %positions during DAQ background acquision
    DaqListener
    DaqInputChannelIdx %Index into acquired input data matrices for our channel
    LastDaqValue %Last value obtained from the DAQ counter
    %Accumulated cycle number for position (i.e. when the DAQ's counter has
    %over- or underflowed its range, this is incremented or decremented
    %accordingly)
    Cycle
  end
  
  properties (Dependent)
    DaqChannelIdx % index into DaqSession's channels for our data
  end
  
  methods
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
    
    function createDaqChannel(obj)
      [ch, idx] = obj.DaqSession.addCounterInputChannel(obj.DaqId, obj.DaqChannelId, 'Position');
      % quadrature encoding where each pulse from the channel updates
      % the counter - ie. maximum resolution (see http://www.ni.com/white-paper/7109/en)
      ch.EncoderType = 'X4';
      obj.DaqChannelIdx = idx; % record the index of the channel
      %initialise LastDaqValue with current counter value
      daqValue = obj.DaqSession.inputSingleScan();
      obj.LastDaqValue = daqValue(obj.DaqInputChannelIdx);
      %reset cycle number
      obj.Cycle = 0;
    end
    
    function msg = wiringInfo(obj)
      ch = obj.DaqSession.Channels(obj.DaqChannelIdx);
      s1 = sprintf('Terminals: A = %s, B = %s\n', ...
        ch.TerminalA, ch.TerminalB);
      s2 = sprintf('For KÜBLER 2400 series wiring is:\n');
      s3 = sprintf('GREEN -> %s, GREY -> %s, BROWN -> +5V, WHITE -> DGND\n',...
        ch.TerminalA, ch.TerminalB);
      msg = [s1 s2 s3];
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
      end;
    end
    
    function x = decodeDaq(obj, newValue)
      %correct for 32-bit overflow/underflow
      d = diff([obj.LastDaqValue; newValue]);
      %decrement cycle for 'underflows', i.e. below 0 to a large value
      %increment cycle for 'overflows', i.e. past max value to small values
      cycle = obj.Cycle + cumsum(d < -0.5*obj.DaqCounterPeriod)...
        - cumsum(d > 0.5*obj.DaqCounterPeriod);
      x = obj.DaqCounterPeriod*cycle + newValue;
      obj.Cycle = cycle(end);
      obj.LastDaqValue = newValue(end);
    end
  end
  
  methods %(Access = protected)
    function [x, time] = readAbsolutePosition(obj)
      if obj.DaqSession.IsRunning
        disp('waiting for session');
        obj.DaqSession.wait;
        disp('done waiting');
      end
      preTime = obj.Clock.now;
      daqVal = inputSingleScan(obj.DaqSession);
      x = decodeDaq(obj, daqVal(obj.DaqInputChannelIdx));
      postTime = obj.Clock.now;
      time = 0.5*(preTime + postTime); % time is mean of before & after
    end
  end
  
  methods (Access = protected)
    function daqListener(obj, src, event)
      acqStartTime = obj.Clock.fromMatlab(event.TriggerTime);
      values = decode(obj, event.Data(:,obj.DaqInputChannelIdx)) - obj.ZeroOffset;
      times = acqStartTime + event.TimeStamps(:,obj.DaqInputChannelIdx);
      logSamples(obj, values, times);
    end
  end
end

