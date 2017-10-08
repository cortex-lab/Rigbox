function defaults = defaultOutputs
    tlOutputs = {'chrono', 'acqLive', 'clock'; 'port0/line0', 'port0/line1', 'ctr3'};
    names = {'name', 'daqChannelID'};
    defaults = cell2struct(tlOutputs, names);
