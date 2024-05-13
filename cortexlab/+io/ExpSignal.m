classdef ExpSignal < uint8
  % EXPSIGNAL Standard experiment signals for communicating between rigs
   enumeration
      EXPINIT (1) % Experiment is initializing
      EXPSTART (2) % Experiment has begun
      EXPEND (4) % Experiment has stopped
      EXPCLEANUP (8) % Experiment cleanup begun
      EXPINTERRUPT (16) % Experiment interrupted
      EXPSTATUS (32) % Experiment status
      EXPINFO (64) % Experiment info, including task protocol start and end
      ALYX (128) % Alyx token
   end
%    properties (Constant)
%      version = '1.0.0'
%    end
end
