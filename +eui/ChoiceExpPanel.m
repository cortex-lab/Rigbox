classdef ChoiceExpPanel < eui.ExpPanel
  %EUI.CHOICEEXPPANEL UI control for monitoring a TAFC experiment
  %   TODO
  %
  % Part of Rigbox
  
  % 2013-06 CB created
  
  properties
    SymbolPlots = []
    ThreshLinesPlot = zeros(0,2)
  end
  
  properties (Access = protected)
    RewardLabel
    PerformanceLabel
    AttemptNumLabel
    PsychometricAxes
    ExperimentAxes
    InputSensorPlot
    InputSensorPosTime
    InputSensorPos
    InputSensorPosCount = 0
    TotalReward = 0
    ExtendThresholdLines = false
    NumTrialPlots = 3 % how many threshold line sets to keep plotting
  end
  
  methods
    function obj = ChoiceExpPanel(parent, ref, params, logEntry)
      obj = obj@eui.ExpPanel(parent, ref, params, logEntry);
      obj.InputSensorPos = nan(1000*60*60*2, 1);
      obj.InputSensorPosTime = nan(1000*60*60*2, 1);
      obj.InputSensorPosCount = 0;
    end
    
    function refresh(obj)
      nTrials = obj.Block.numCompletedTrials;
      obj.PsychometricAxes.clear();
      if nTrials > 0
        trials = obj.Block.trial(1:nTrials);
        conds = [trials.condition];
        if isfield(conds, 'cueOrientation')
          condfun = @(tri) sign([conds.cueOrientation]).*psy.visualContrasts(tri);
        else
          condfun = @(tri) diff(psy.visualContrasts(tri), [], 1);
        end
        contrasts = condfun(trials);
        nonRepeatTrials = [conds.repeatNum] == 1;
        %'performance' trials are those which aren't predictable repeats
        % (e.g. due to the animal getting the last incorrect), and non-blanks
        if (isfield(obj.Parameters.Struct,'responseWindow')&&isfinite(obj.Parameters.Struct.responseWindow))||...
                (~any(abs(contrasts))&&isfield(conds, 'targetOrientation'))
            perfTrials = nonRepeatTrials;
        else
            perfTrials = abs(contrasts) > 0 & nonRepeatTrials;
        end
        pc = mean([trials(perfTrials).feedbackType] > 0);
        set(obj.PerformanceLabel, 'String', ...
          iff(isfinite(pc), sprintf('%.1f%%', 100*pc), 'N/A'));
        % TODO: need to handle single data point cases better
        
        if obj.Block.numCompletedTrials > 0
            if ~any(abs(contrasts))&&isfield(conds, 'targetOrientation')
                psy.plot2ADCwithOri(obj.PsychometricAxes.Handle, obj.Block);
            else
                psy.plot2ADC(obj.PsychometricAxes.Handle, obj.Block);
            end
          %           [pRight, n, cond] = psy.responseByCondition(obj.Block);
          %           %compute sigmoid fit parameters & plot
          %           [gam, mu, sig, n, c] = psy.fit(obj.Block);
          %           cc = linspace(min(c), max(c), 100);
          %           nn = round(interp1(c, n, cc));
          %           [prr, ci] = binofit(nn.*psy.lapseNormalLikelihood(cc, gam, mu, sig), nn);
          %           ax = obj.PsychometricAxes.Handle;
          %           fitcolour = [0.85 0.85 1];
          %           %shade the best fit confidence interval
          %           plt.hshade(ax, 100*cc , 100*ci(:,2)', 100*ci(:,1)', fitcolour, 'w', 1);
          %           %plot the best fit function
          %           obj.PsychometricAxes.plot(100*cc, 100*prr, 'Color', .8*fitcolour);
          %           %now plot data points with binomial errorbars
          %           [~, pci] = binofit(pRight.*n, n);
          %           errorbar(100*cond, 100*pRight,...
          %             100*(pci(:,1) - pRight), 100*(pci(:,2) - pRight),...
          %             'ok', 'Parent', obj.PsychometricAxes.Handle, 'LineWidth', 2);
          %           obj.PsychometricAxes.XLim = 105*[min(cond) max(cond)];
          %           obj.PsychometricAxes.xLabel('Contrast (%)');
          %           text(obj.PsychometricAxes.XLim(1) + 0.05*diff(obj.PsychometricAxes.XLim), 50, ...
          %             sprintf('Best fit:\n\\lambda=%.1f%%\n\\sigma_c=%.1f%%\n\\mu_c=%.1f%%',...
          %             100*gam, 100*sig, 100*mu),...
          %             'HorizontalAlignment', 'left', 'FontSize', 8, 'Parent', ax);
        end
        %         toc;
      end
    end
  end
  
  methods (Access = protected)
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
      if ~any(diff(condition.visCueContrast))&&isfield(condition, 'targetOrientation')
        oriDiff = diff(condition.targetOrientation);
        obj.PsychometricAxes.plot(oriDiff*[1 1], [-10 110], 'k:',...
        'LineWidth', 3);
      else
        conDiff = diff(condition.visCueContrast);
        obj.PsychometricAxes.plot(conDiff*[100 100], [-10 110], 'k:',...
        'LineWidth', 3);
      end
    end
    
    function trialCompleted(obj, num, data)
      obj.refresh();
    end
    
    function event(obj, name, t)
      event@eui.ExpPanel(obj, name, t); %call superclass method
      switch name
        case 'negFeedbackSoundPlayed'
          xpos = sign(obj.InputSensorPos(obj.InputSensorPosCount));
          obj.SymbolPlots = [obj.SymbolPlots
            scatter(obj.ExperimentAxes, xpos, t, pi*10^2, 'rx', 'LineWidth', 4)];
        case 'stimulusCueStarted'
          %create a new thresholds plot with contrast response boundaries
          condition = obj.Block.trial(end).condition;
          contrast = condition.visCueContrast;
          if numel(contrast) == 1
            baseColour = min(max((1 - contrast)*[1 1 1], 0), 1);
            ori = sign(condition.cueOrientation);
            if ori > 0 
              leftColour = [1 1 1];
              rightColour = baseColour;
            else
              leftColour = baseColour;
              rightColour = [1 1 1];
            end
          elseif numel(contrast)>1&&~any(abs(contrast))&&isfield(condition, 'targetOrientation')
            ori = condition.targetOrientation;
            leftColour = iff(abs(ori(1)/45)>1,[1 1 1],abs(ori(1)/45)*[1 1 1]);
            rightColour = iff(abs(ori(2)/45)>1,[1 1 1],abs(ori(2)/45)*[1 1 1]);
          else
            leftColour = (1 - contrast(1))*[1 1 1];
            rightColour = (1 - contrast(2))*[1 1 1];
          end
          leftColour = min(max(leftColour, 0), 1);
          rightColour = min(max(rightColour, 0), 1);
          ax = obj.ExperimentAxes;
          obj.ThreshLinesPlot = [...
            obj.ThreshLinesPlot
            ax.plot([-1 -1], [t t], ':', 'Color', leftColour, 'LineWidth', 4),... %L boundary
            ax.plot([ 1  1], [t t], ':', 'Color', rightColour, 'LineWidth', 4)... %R boundary
            ];
          % get rid of threshold line pairs when we accrue too many
          % each trial has two pairs - stimulus & interactive
          while size(obj.ThreshLinesPlot, 1)/2 > obj.NumTrialPlots
            delete(obj.ThreshLinesPlot(1,:));%delete oldest pair from plot
            obj.ThreshLinesPlot(1,:) = [];%remove pair from list
          end
          % same but for symbols
          while numel(obj.SymbolPlots) > obj.NumTrialPlots
            delete(obj.SymbolPlots(1));%delete oldest symbol from plot
            obj.SymbolPlots(1) = [];%remove from list
          end
          obj.ExtendThresholdLines = true;
          %           text(0, t, sprintf('%.1f%%', 100*diff(contrast)),...
          %             'Parent', obj.ExperimentAxes.Handle,...
          %              'VerticalAlignment', 'bottom',...
          %              'HorizontalAlignment', 'center');
        case 'interactiveStarted'
          extendThreshLines(obj, t); %extend stimulus lines up to now
          %create a new thresholds plot with coloured response boundaries
          feedback = obj.Block.trial(end).condition.feedbackForResponse;
          leftSpec = iff(feedback(1) > 0, 'g', 'r');
          rightSpec = iff(feedback(2) > 0, 'g', 'r');
          obj.ThreshLinesPlot = [...
            obj.ThreshLinesPlot;...
            obj.ExperimentAxes.plot(...
              [-1 -1], [t t], leftSpec,... %L boundary
              [ 1  1], [t t], rightSpec,'LineWidth', 4)'];%R boundary
              
        case 'interactiveEnded'
          %update with final time range on y axis
          extendThreshLines(obj, t);
          %clear flah so threshold lines dont get extended
          %anymore
          obj.ExtendThresholdLines = false;
          %obj.ThreshLinesPlot = [];
      end
    end
    
    function expUpdate(obj, rig, evt)
      expUpdate@eui.ExpPanel(obj, rig, evt); %call superclass method
      %process update dependent on its type
      type = evt.Data{1};
      switch type
        case 'inputSensorPos'
          x = evt.Data{2};
          t = evt.Data{3};
          %update our record of sensor positions
          lastidx = obj.InputSensorPosCount + 1;
          obj.InputSensorPosCount = lastidx;
          obj.InputSensorPos(lastidx) = x;
          obj.InputSensorPosTime(lastidx) = t;
          %update sensor pos plot with new data
          plotwindow = [-5 0];
          % little hack to look back twice the plot window in samples if
          % they are received at 25Hz
          firstidx = round(max(1, lastidx + 2*25*plotwindow(1)));

          if ~isempty(obj.InputSensorPlot)
            set(obj.InputSensorPlot,...
              'XData', obj.InputSensorPos(firstidx:lastidx),...
              'YData', obj.InputSensorPosTime(firstidx:lastidx));
          else
            obj.InputSensorPlot = plot(obj.ExperimentAxes,...
              obj.InputSensorPos(firstidx:lastidx),...
              obj.InputSensorPosTime(firstidx:lastidx),...
              'Color', .75*[1 1 1]);
          end
          
          if obj.ExtendThresholdLines
            extendThreshLines(obj, t);
          end
          set(obj.ExperimentAxes.Handle, 'YLim', plotwindow + t);
        case 'rewardDelivered'
          obj.TotalReward = obj.TotalReward + evt.Data{2};
          t = evt.Data{3};
          set(obj.RewardLabel, 'String', sprintf('%.1fµl', obj.TotalReward));
          xpos = sign(obj.InputSensorPos(obj.InputSensorPosCount));
          obj.SymbolPlots = [obj.SymbolPlots
            scatter(obj.ExperimentAxes, xpos, t, pi*10^2, 'b', 'filled')];
      end
    end
    
    function extendThreshLines(obj, t)
      %extend the response threshold lines in time
      if size(obj.ThreshLinesPlot, 1) > 0
%         size(obj.ThreshLinesPlot)
        current = obj.ThreshLinesPlot(end,:);
        for i = 1:numel(current)
          yd = get(current(i), 'YData');
          yd(2) = t;
          set(current(i), 'YData', yd);
        end
      end
    end
    
    function build(obj, parent)
      build@eui.ExpPanel(obj, parent); %call superclass method
      obj.AttemptNumLabel = obj.addInfoField('Attempt no.', 'N/A');
      obj.PerformanceLabel = obj.addInfoField('Performance', 'N/A');
      obj.RewardLabel = obj.addInfoField('Reward delivered', '0.0µl');
      
      plotgrid = uiextras.Grid('Parent', obj.CustomPanel, 'Padding', 5);
      uiextras.Empty('Parent', plotgrid, 'Visible', 'off');
      uiextras.Empty('Parent', plotgrid, 'Visible', 'off');
      uiextras.Empty('Parent', plotgrid, 'Visible', 'off');
      uiextras.Empty('Parent', plotgrid, 'Visible', 'off');
      obj.PsychometricAxes = bui.Axes(plotgrid);
      obj.PsychometricAxes.ActivePositionProperty = 'position';
      %       obj.PsychometricAxes.XLim = [-100 100];
      obj.PsychometricAxes.YLim = [-1 101];
      obj.PsychometricAxes.NextPlot = 'add';
      uiextras.Empty('Parent', plotgrid, 'Visible', 'off');
      obj.ExperimentAxes = bui.Axes(plotgrid);
      obj.ExperimentAxes.ActivePositionProperty = 'position';
      obj.ExperimentAxes.XTickLabel = [];
      obj.ExperimentAxes.XLim = [-2 2];
      obj.ExperimentAxes.NextPlot = 'add';
      uiextras.Empty('Parent', plotgrid, 'Visible', 'off');
      uiextras.Empty('Parent', plotgrid, 'Visible', 'off');
      
      obj.PsychometricAxes.yLabel('% right-ward');
      obj.ExperimentAxes.yLabel('time (s)');
      
      plotgrid.ColumnSizes = [50 -1 10];
      plotgrid.RowSizes = [-1 50 -2 40];
    end
  end
  
end

