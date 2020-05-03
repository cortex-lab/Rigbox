classdef ExperimentQC < matlab.unittest.TestCase
  %QC.EXPERIMENTQC Checks for Experiment data integrity
  %   Runs some basic checks on an Experiment block file, including checks
  %   for existence of fields and timestamps are consistent.  May be
  %   subclassed for more specific checks.  
  %
  %   Example - Run QC checks for a block file:
  %     ref = '2020-05-03_1_default'
  %     block = dat.loadBlock(ref);
  %     result = qc.ExperimentQC(block).run;
  %
  %   Example - Run specifc check:
  %     qc.ExperimentQC(block).run('checkStimWindowTimes');
  %
  % See also QC.SIGNALSEXPQC
  
  properties
    Data
  end
  
  methods
    function obj = ExperimentQC(block)
      obj.Data = block;
    end
    
    function verifyFieldSet(obj, S, field, msg)
      % TODO https://uk.mathworks.com/help/matlab/matlab_prog/create-custom-constraint.html
      if nargin < 4, msg = sprintf('data field ''%s'' not set', field); end
      obj.verifyNotEmpty(getOr(S, field, []), msg)
    end
    
    function assertFieldSet(obj, S, field, msg)
      if nargin < 4, msg = sprintf('data field ''%s'' not set', field); end
      obj.assertNotEmpty(getOr(S, field, []), msg)
    end
    
    function fatalAssertFieldSet(obj, S, field, msg)
      if nargin < 4, msg = sprintf('data field ''%s'' not set', field); end
      obj.fatalAssertNotEmpty(getOr(S, field, []), msg)
    end
    
  end
  
  methods (Test)
    
    function checkBlockStructure(obj)
      % For base class
      obj.verifyFieldSet(obj.Data, 'rigName', 'Rig name not set')
      obj.verifyFieldSet(obj.Data, 'endStatus')
      obj.verifyTrue(ismember(obj.Data.endStatus, {'quit', 'aborted', 'exception'}))
      if strcmp(obj.Data.endStatus, 'exception')
        obj.verifyFieldSet(obj.Data, 'exceptionMessage')
      end
      % TODO Other times, expRef, etc.
      obj.verifyTrue(obj.Data.experimentInitTime < obj.Data.experimentStartedTime)
      obj.verifyTrue(obj.Data.experimentEndedTime < obj.Data.experimentCleanupTime)
      accurateDuration = (obj.Data.experimentCleanupTime - ...
        obj.Data.experimentInitTime - ...
        obj.Data.duration) < 0.1;
      obj.verifyTrue(accurateDuration)
    end
    
    function checkStimWindowTimes(obj)
      obj.verifyFieldSet(obj.Data, 'stimWindowUpdateTimes')
      obj.verifyThat(obj.Data.stimWindowUpdateTimes, qc.StrictlyIncreasing)
    end
    
  end
  
end