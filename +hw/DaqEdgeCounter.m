classdef DaqEdgeCounter < hw.DaqRotaryEncoder
  %HW.DAQEDGECOUNTER Tracks a DAQ edge counter channel
  %   TODO Document DaqEdgeCounter class
  %
  % Part of Rigbox
  
  % 2013-01 CB created  
  
  methods
    function createDaqChannel(obj)
      [ch, idx] = obj.DaqSession.addCounterInputChannel(obj.DaqId, obj.DaqChannelId, 'EdgeCount');

      obj.DaqChannelIdx = idx; % record the index of the channel
      %initialise LastDaqValue with current counter value
      daqValue = obj.DaqSession.inputSingleScan();
      obj.LastDaqValue = daqValue(obj.DaqInputChannelIdx);
      %reset cycle number
      obj.Cycle = 0;
    end

    function msg = wiringInfo(obj)
      ch = obj.DaqSession.Channels(obj.DaqChannelIdx);
      s1 = sprintf('Terminal = %s', ch.Terminal);
      msg = [s1];
    end
  end
end

