classdef ExpSignal < uint8
  % EXPSIGNAL Standard experiment signals for communicating between rigs
   enumeration
      EXPINIT (10) % Experiment is initializing
      EXPSTART (20) % Experiment has begun
      EXPEND (30) % Experiment has stopped
      EXPCLEANUP (40) % Experiment cleanup begun
      EXPINTERRUPT (50) % Experiment interrupted
      EXPSTATUS (1) % Experiment status
      EXPINFO (2) % Experiment info, including task protocol start and end
      ALYX (3) % Alyx token
   end
end

