classdef ExpStatus < uint8
  % EXPSTATUS Standard signals for communicating status between rigs
   enumeration
      CONNECTED (0) % Service is connected
      INITIALIZED (10) % Service is initialized
      RUNNING (20) % Service is running
      STOPPED (30) % Service is stopped
   end
%    properties (Constant)
%      version = '1.0.0'
%    end
end
