classdef DigiRewardValveControl < hw.RewardValveControl & handle
  %HW.REWARDVALVECONTROL Controls a valve via a DAQ to deliver reward
  %   Must (currently) be sole outputer on DAQ session
  %   TODO
  %
  % Part of Rigbox
  
  % 2013-01 CB created
  
  properties
  end
  
  methods
    function obj = DigiRewardValveControl()
      obj@hw.RewardValveControl;
      obj.ParamsFun = @obj.clockParams;
    end
    
    function duration = waveform(obj, sampleRate, sz)
      
      if sz > 0
        duration = pulseDuration(obj, sz);
      else
        duration = 0;
      end
      
    end
    
  end
  
end

