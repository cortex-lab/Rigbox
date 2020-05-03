classdef SignalsExpQC < qc.ExperimentQC
  %QC.SIGNALSEXPQC Checks for Signals Experiment data integrity
  %   Runs some basic checks on an exp.SignalsExp block file, including
  %   checks for existence of events and consistent timestamps.  May be
  %   subclassed for more specific checks.
  %
  %   Example - Run QC checks for a block file:
  %     ref = '2020-05-03_1_default'
  %     block = dat.loadBlock(ref);
  %     result = qc.SignalsExpQC(block).run;
  %
  %   Example - Run specifc check:
  %     qc.SignalsExpQC(block).run('checkBasicEvents');
  %
  % See also QC.EXPERIMENTQC
  
  properties
    MinRenderFlipDelay = 0.05
    MinParamNewTrialDelay = 0.1
  end
  
  properties (Access = protected)
    % Essential trial events for this Experiment class, in order of
    % occurence
    BasicEvents = ["newTrial", "trialNum", "repeatNum", "endTrial"]
  end
  
  methods
    function obj = SignalsExpQC(block)
      obj = obj@qc.ExperimentQC(block);
    end
  end
  
  methods (Test)
    
    function verifyStimWindowTimes(obj)
      verifyStimWindowTimes@qc.ExperimentQC(obj);
      
      renderTimes = obj.Data.stimWindowRenderTimes;
      updateTimes = obj.Data.stimWindowUpdateTimes;
      
      obj.verifyThat(renderTimes, qc.StrictlyIncreasing)
      obj.verifyEqual(numel(renderTimes), numel(updateTimes))
      obj.verifyTrue(all(renderTimes < updateTimes))
      obj.verifyTrue(all(updateTimes - renderTimes < obj.MinRenderFlipDelay))
    end
    
    function verifyEventsTimings(obj)
      events = obj.Data.events;
      fields = string(fieldnames(events));
      eventTimes = fields(endsWith(fields, 'Times'));
      
      for event = eventTimes'
        % Check event times monotonically increase
        name = erase(event, 'Times');
        msg = sprintf('''%s'' event times are not monotonically increasing', name);
        obj.verifyThat(events.(event), qc.StrictlyIncreasing, msg)
        % Check event times all occur before experiment start
        obj.verifyTrue(all(events.(event) > obj.Data.experimentInitTime), ...
          sprintf('''%s'' event times occur before experiment init', name))
      end
      
    end
    
    function checkBasicEvents(obj)
      % Check basic fields are present
      obj.fatalAssertFieldSet(obj.Data, 'events')
      values = strcat(obj.BasicEvents, 'Values');
      times = strcat(obj.BasicEvents, 'Times');
      for field = [values, times]
        obj.verifyFieldSet(obj.Data.events, field)
        if endsWith(field, 'Times')
          obj.verifyThat(obj.Data.events.(field), qc.StrictlyIncreasing)
        end
      end

      for i = 1:length(times)-1
        tDiff = obj.Data.events.(times(i+1)) - obj.Data.events.(times(i));
        obj.verifyTrue(all(sign(tDiff) == 1))
      end
      obj.Data.events.newTrialTimes;
      obj.Data.events.newTrialValues;
    end
    
    function verify_expStart(obj)
      obj.verifyFieldSet(obj.Data.events, 'expStartTimes')
      obj.verifyFieldSet(obj.Data.events, 'expStartValues')
      obj.assertNumElements(obj.Data.events.expStartTimes, 1)
      obj.verifyEqual(obj.Data.events.expStartValues, obj.Data.expRef)
      obj.verifyTrue(obj.Data.events.expStartTimes > obj.Data.experimentStartedTime)
    end
    
    function verify_expStop(obj)
      obj.verifyFieldSet(obj.Data.events, 'expStopTimes')
      obj.verifyFieldSet(obj.Data.events, 'expStopValues')
      obj.assertNumElements(obj.Data.events.expStopTimes, 1, ...
        'multiple ''expStop'' event times')
      obj.verifyNotEmpty(obj.Data.events.expStopValues, ...
        'empty ''expStop'' event')
      obj.verifyTrue(obj.Data.events.expStopTimes > obj.Data.experimentEndedTime)
    end
    
    function verifyParams(obj)
      b = obj.Data;
      paramVals = b.paramsValues;
      obj.verifyEqual(numel(paramVals), numel(b.paramsTimes))
      obj.verifyEqual(numel(paramVals), numel(b.events.newTrialTimes))
      obj.verifyThat(b.paramsTimes, qc.StrictlyIncreasing)
      paramDelays = b.paramsTimes - b.events.newTrialTimes;
      obj.verifyTrue(all(paramDelays < obj.MinParamNewTrialDelay))
    end
    
    function verifyInputs(obj)
      obj.verifyTrue(all(diff(obj.Data.inputs.wheelTimes) < 1e-1)) % Fails due to reward
    end
  end
  
end