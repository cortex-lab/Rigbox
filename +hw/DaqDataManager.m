classdef DaqDataManager
  %HW.DAQDATAMANAGER [Unused] Interface for adding and configuring DAQ channels 
  %   This class was started, presumably by Chris, at an unknown time and
  %   appears to have been created to manage the channels in the
  %   HW.DAQCONTROLLER object in a more user-friendly way.  
  %
  %   Perhaps this would be useful for creating and configuering a
  %   hardware.mat file (that used by SRV.EXPSERVER and MC to load and
  %   configure task-related hardware) in a more automated fashion.
  %
  %   TODO: Finish this class, perhaps ask Chris what his aim was with this
  % Part of Rigbox
  
  % xxxx-xx CB created
  
  properties
  end
  
  methods
    function id = manageAnalogOutputChannel(chan, defaultValue)
    end
    
    function submit
    end
  end
  
end

