classdef NickExpPanel < eui.ChoiceExpPanel
  %EUI.NickExpPanel UI control for monitoring a wheel experiment,
  %potentially with differing rewards, stimulus altitudes, and with no-go
  %responses
  %
  % Part of Rigbox
  
  % 2014-08 NS created
  
  
  properties
    ConditionIndexLabel
  end
  
  methods
    function obj = NickExpPanel(parent, ref, params, logEntry)
      obj = obj@eui.ChoiceExpPanel(parent, ref, params, logEntry);
    end
    
    
    function refresh(obj)
      nTrials = obj.Block.numCompletedTrials;
      obj.PsychometricAxes.clear();
      if nTrials > 0
        trials = obj.Block.trial(1:nTrials);
        conds = [trials.condition];
        nonRepeatTrials = [conds.repeatNum] == 1;
        
        %'performance' trials are those which aren't predictable repeats
        % (e.g. due to the animal getting the last incorrect)
        perfTrials = nonRepeatTrials;
        pc = mean([trials(perfTrials).feedbackType] > 0);
        set(obj.PerformanceLabel, 'String', ...
          iff(isfinite(pc), sprintf('%.1f%%', 100*pc), 'N/A'));
        
        psy.plot2ADCwithAlt(obj.PsychometricAxes.Handle, obj.Block);
      end
    end
    
    function newTrial(obj, num, condition)
        %attempt num is red when on higher than third
        attemptColour = iff(condition.repeatNum > 3, [1 0 0], [0 0 0]);
        set(obj.AttemptNumLabel,...
            'String', sprintf('%i', condition.repeatNum),...
            'ForegroundColor', attemptColour);
        if isfield(condition, 'conditionId')
            if isnumeric(condition.conditionId)
                conditionId = num2str(condition.conditionId);
            else
                conditionId = condition.conditionId;
            end
            set(obj.ConditionLabel, 'String', conditionId);
        end
        
        conDiff = diff(condition.visCueContrast);
        if isfield(condition, 'targetAltitude')
            thisAlt = condition.targetAltitude;
            allAlt = unique(obj.Parameters.Struct.targetAltitude);
            thisAltInd = find(allAlt==thisAlt,1);
            lineType = iff(thisAltInd==1, '-', ':');
        else
            lineType = ':';
        end
        obj.PsychometricAxes.plot(conDiff*[100 100], [-10 110], lineType,...
            'LineWidth', 3, 'Color', [0 0 0]);
    end
    
    function build(obj, parent)
      build@eui.ChoiceExpPanel(obj, parent); %call superclass method
    end
    
  end
  
  
end