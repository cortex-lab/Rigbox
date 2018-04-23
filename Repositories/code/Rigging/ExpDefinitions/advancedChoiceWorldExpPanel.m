classdef advancedChoiceWorldExpPanel < eui.ExpPanel
  %eui.SqueakExpPanel Basic UI control for monitoring an experiment
  %   TODO
  %
  % Part of Rigbox
  
  % 2015-03 CB created
  
  properties
    SignalUpdates = struct('name', cell(500,1), 'value', cell(500,1), 'timestamp', cell(500,1))
    NumSignalUpdates = 0
    LabelsMap
    RecentColour = [0 1 0]
  end
  
  properties (Access = protected)
    PsychometricAxes % Handle to axes of psychometric plot
    ExperimentAxes % Handle to axes of wheel trace and threhold line plot
    ThresholdLineAxes % Handle to axes of right/wrong threshold line plot
    InputSensorPlot % Handle to axes for wheel trace plot
    InputSensorPosTime % Vector of timesstamps in seconds for plotting the wheel trace
    InputSensorPos % Vector of azimuth values for plotting the wheel trace
    InputSensorPosCount = 0 % Running total of azimuth samples recieved for axes plot
    ExtendThresholdLines = false % Flag for plotting dotted threshold lines during cue interactive delay.  Currently unused.
  end
  
  methods
    function obj = advancedChoiceWorldExpPanel(parent, ref, params, logEntry)
      obj = obj@eui.ExpPanel(parent, ref, params, logEntry);
      obj.LabelsMap = containers.Map();
      % Initialize InputSensor properties for speed
      obj.InputSensorPos = nan(1000*60*60*2, 1);
      obj.InputSensorPosTime = nan(1000*60*60*2, 1);
      obj.InputSensorPosCount = 0;
      obj.Block.newTrialTimes = now;
      obj.Block.trial = struct('contrastLeft', [], 'contrastRight', [],...
        'response', [], 'feedback', [], 'repeatNum', []);
    end
    
    function update(obj)
      update@eui.ExpPanel(obj);
      processUpdates(obj); % update labels with latest signal values
      labelsMapVals = values(obj.LabelsMap)';
      labels = deal([labelsMapVals{:}]);
      if ~isempty(labels) % colour decay by recency on labels
        dt = cellfun(@(t)etime(clock,t),...
          ensureCell(get(labels, 'UserData')));
        c = num2cell(exp(-dt/1.5)*obj.RecentColour, 2);
        set(labels, {'ForegroundColor'}, c);
      end
    end
  end
  
  methods %(Access = protected)
    function newTrial(obj, num, condition)
    end
    
    function trialCompleted(obj, num, data)
    end
    
    function event(obj, name, t)
      %called when an experiment event occurs
      phaseChange = false;
      if strEndsWith(name, 'Started')
        if strcmp(name, 'experimentStarted')
          obj.Root.TitleColor = [0 0.8 0.05]; % green title area
        else
          %phase has started, add it to active phases
          phase = name;
          phase(strfind(name, 'Started'):end) = [];
          obj.ActivePhases = [obj.ActivePhases; phase];
          phaseChange = true;
        end
      elseif strEndsWith(name, 'Ended')
        if strcmp(name, 'experimentEnded')
          obj.Root.TitleColor = [0.98 0.65 0.22]; %amber title area
          obj.ActivePhases = {};
          phaseChange = true;
        else
          %phase has ended, remove it from active phases
          phase = name;
          phase(strfind(name, 'Ended'):end) = [];
          obj.ActivePhases(strcmp(obj.ActivePhases, phase)) = [];
          phaseChange = true;
        end
        %       else
        %         disp(name);
      end
      if phaseChange % only update if there was a change for efficiency
        %update status with list of running phases
        phasesStr = ['[' strJoin(obj.ActivePhases, ',') ']'];
        set(obj.StatusLabel, 'String', sprintf('Running %s', phasesStr));
      end
    end
    
    function processUpdates(obj)
      updates = obj.SignalUpdates(1:obj.NumSignalUpdates);
      obj.NumSignalUpdates = 0;
      %       fprintf('processing %i signal updates\n', length(updates));
      for ui = 1:length(updates)
        signame = updates(ui).name;
        switch signame
          case {'events.azimuth', 'events.contrast', 'outputs.reward', ...
                  'events.stimulusOn', 'events.expStart', 'events.response', ...
                  'events.feedback', 'events.endTrial', 'events.interactiveDealy'...
                  'events.preStimulusDelay'}
                % Don't show these signals as labels
          otherwise
            if ~isKey(obj.LabelsMap, signame)
              obj.LabelsMap(signame) = obj.addInfoField(signame, '');
            end
%             time = datenum(updates(ui).timestamp);
            %             str = ['[' datestr(time,'HH:MM:SS') ']    ' toStr(updates(ui).value)];
            str = toStr(updates(ui).value);
            set(obj.LabelsMap(signame), 'String', str, 'UserData', clock,...
              'ForegroundColor', obj.RecentColour);
        end
      end
    end
    
    function expUpdate(obj, rig, evt)
      if strcmp(evt.Name, 'signals')
        type = 'signals';
      else
        type = evt.Data{1};
      end
      switch type
        case 'signals' %queue signal updates
          updates = evt.Data;
          newNUpdates = obj.NumSignalUpdates + length(updates);
          if newNUpdates > length(obj.SignalUpdates)
            %grow message queue to accommodate
            obj.SignalUpdates(2*newNUpdates).value = [];
          end
          try
            obj.SignalUpdates(obj.NumSignalUpdates+1:newNUpdates) = updates;
          catch
            warning('Error caught in signals updates: length of updates = %g, length newNUpdates = %g', length(updates), newNUpdates-(obj.NumSignalUpdates+1))
          end
          obj.NumSignalUpdates = newNUpdates;

          % Update wheel trace
          idx = strcmp('events.azimuth', {updates.name});
          %update sensor pos plot with new data
          plotwindow = [-5 0]; t = 0;
          if any(idx)
            x = updates(find(idx, 1, 'last')).value;
            t = (24*3600*datenum(updates(find(idx, 1, 'last')).timestamp))-(24*3600*obj.StartedDateTime);
            % Downsample wheel trace plot to 10Hz
%             if obj.InputSensorPosCount==0||...
%                     t(end)-obj.InputSensorPosTime(obj.InputSensorPosCount) > 0.1
              %update our record of sensor positions
              lastidx = obj.InputSensorPosCount + 1;
              obj.InputSensorPosCount = lastidx;
              obj.InputSensorPos(lastidx) = x;
              obj.InputSensorPosTime(lastidx) = t(end);
              % little hack to look back twice the plot window in samples if
              % they are received at 25Hz
              firstidx = round(max(1, lastidx + 2*25*plotwindow(1)));
              if ~isempty(obj.InputSensorPlot)
                  set(obj.InputSensorPlot,...
                      'XData', obj.InputSensorPos(firstidx:lastidx),...
                      'YData', obj.InputSensorPosTime(firstidx:lastidx));
              else % First plot
                  obj.InputSensorPlot = plot(obj.ExperimentAxes,...
                      obj.InputSensorPos(firstidx:lastidx),...
                      obj.InputSensorPosTime(firstidx:lastidx),...
                      'Color', .75*[1 1 1]);
              end
              
              set(obj.ExperimentAxes.Handle, 'YLim', plotwindow + t(end));
%             end
          end
          
          % Build block structure for plotting
          idx = strcmp('events.newTrial', {updates.name});
          if any(idx); obj.Block.newTrialTimes(end+1) = datenum(updates(idx).timestamp); end
%           if obj.Block.numCompletedTrials == 0; i = 1; else; i = obj.Block.numCompletedTrials+1; end
          idx = strcmp('events.contrastLeft', {updates.name});
          if any(idx)
            i = find(datenum(updates(idx).timestamp) > [obj.Block.newTrialTimes], 1, 'last');
            obj.Block.trial(i).contrastLeft = updates(idx).value;
          end
          idx = strcmp('events.contrastRight', {updates.name});
          if any(idx)
            i = find(datenum(updates(idx).timestamp) > [obj.Block.newTrialTimes], 1, 'last');
            obj.Block.trial(i).contrastRight = updates(idx).value;
          end
          idx = strcmp('events.repeatNum', {updates.name});
          if any(idx)
            i = find(datenum(updates(idx).timestamp) > [obj.Block.newTrialTimes], 1, 'last');
            obj.Block.trial(i).repeatNum = updates(idx).value;
          end
          idx = strcmp('events.response', {updates.name});
          if any(idx)
            i = find(datenum(updates(idx).timestamp) > [obj.Block.newTrialTimes], 1, 'last');
            obj.Block.trial(i).response = updates(idx).value; 
            t = (24*3600*datenum(updates(idx).timestamp))-(24*3600*obj.StartedDateTime);
            lastidx = obj.InputSensorPosCount + 1;
            obj.InputSensorPosCount = lastidx;
            obj.InputSensorPos(lastidx) = NaN;
            obj.InputSensorPosTime(lastidx) = t(end);
          end
          idx = strcmp('events.feedback', {updates.name});
          if any(idx)
            i = find(datenum(updates(idx).timestamp) > [obj.Block.newTrialTimes], 1, 'last');
            obj.Block.trial(i).feedback = updates(idx).value;
          end
          idx = strcmp('events.trialNum', {updates.name});
          contrast = diff([obj.Block.trial(end).contrastLeft obj.Block.trial(end).contrastRight]);
          if any(idx)
            obj.Block.numCompletedTrials = updates(idx).value-1; 
            obj.PsychometricAxes.clear();
            % make plot
            if ~isempty(contrast)&&...
                any(obj.Block.trial(end).contrastLeft>0 & obj.Block.trial(end).contrastRight>0)
              % Plot a dotted line to indicate the current trial's contrast
              obj.PsychometricAxes.plot(contrast*[100 100], [-10 110], 'k:', 'LineWidth', 3)
            end
            if obj.Block.numCompletedTrials > 2
              psy.plot2AUFC(obj.PsychometricAxes.Handle, obj.Block);
            end
          end
           
          if sign(contrast)==1
            leftSpec = 'g';
            rightSpec = 'r';
          elseif sign(contrast)==-1
            leftSpec = 'r';
            rightSpec = 'g';
          elseif isempty(contrast)
            leftSpec = 'w';
            rightSpec = 'w';
          else
            leftSpec = 'r';
            rightSpec = 'r';
          end
          az = obj.Parameters.Struct.stimulusAzimuth;
          if isempty(obj.ThresholdLineAxes)
            obj.ThresholdLineAxes = obj.ExperimentAxes.plot(...
               [-az -az], plotwindow + t, leftSpec,... %L boundary
               [az  az], plotwindow + t, rightSpec,'LineWidth', 4);%R boundary
          else
            set(obj.ThresholdLineAxes(1),...
              'XData', [-az -az], 'YData', plotwindow + t,...
              'Color', leftSpec);
            set(obj.ThresholdLineAxes(2),...
              'XData', [az az], 'YData', plotwindow + t,...
              'Color', rightSpec);
          end
          
        case 'newTrial'
          cond = evt.Data{2}; %condition data for the new trial
          trialCount = obj.Block.numCompletedTrials;
          %add the trial condition to a new trial in the block
          obj.mergeTrialData(trialCount + 1, struct('condition', cond));
          obj.newTrial(trialCount + 1, cond);
        case 'trialData'
          %a trial just completed
          data = evt.Data{2}; %the final data from that trial
          nTrials = obj.Block.numCompletedTrials + 1;
          obj.Block.numCompletedTrials = nTrials; %inc trial number in block
          %merge the new data with the rest of the trial data in the block
          obj.mergeTrialData(nTrials, data);
          obj.trialCompleted(nTrials, data);
          set(obj.TrialCountLabel, 'String', sprintf('%i', nTrials));
        case 'event'
          %           disp(evt.Data);
          obj.event(evt.Data{2}, evt.Data{3});
      end
    end
    
    function build(obj, parent)
      obj.Root = uiextras.BoxPanel('Parent', parent,...
        'Title', obj.Ref,... %default title is the experiment reference
        'TitleColor', [0.98 0.65 0.22],...%amber title area
        'Padding', 5,...
        'CloseRequestFcn', @obj.closeRequest,...
        'DeleteFcn', @(~,~) obj.cleanup());
      
      obj.MainVBox = uiextras.VBox('Parent', obj.Root, 'Spacing', 5);
      
      obj.InfoGrid = uiextras.Grid('Parent', obj.MainVBox);
%       obj.InfoGrid.ColumnSizes = [150, -1];
      %panel for subclasses to add their own controls to
      obj.CustomPanel = uiextras.VBox('Parent', obj.MainVBox);
      
      bui.label('Comments', obj.MainVBox);
      
      obj.CommentsBox = uicontrol('Parent', obj.MainVBox,...
        'Style', 'edit',... %text editor
        'String', obj.LogEntry.comments,...
        'Max', 2,... %make it multiline
        'HorizontalAlignment', 'left',... %make it align to the left
        'BackgroundColor', [1 1 1],...%background to white
        'Callback', @obj.commentsChanged); %update comment in log
      
      buttonpanel = uiextras.HBox('Parent', obj.MainVBox);
      %info grid size will be updated as fields are added, the other
      %default panels get reasonable space, and the custom panel gets
      %whatever's left
      obj.MainVBox.Sizes = [0 -1 15 80 24];
      
      %add the default set of info fields to the grid
      obj.StatusLabel = obj.addInfoField('Status', 'Pending');
      obj.DurationLabel = obj.addInfoField('Elapsed', '-:--');
      
      if isfield(obj.Parameters.Struct, 'conditionId')
        obj.ConditionLabel = obj.addInfoField('Condition', 'N/A');
      end
      
      %buttons to stop experiment running if and when it is, by default
      %hidden
      obj.StopButtons = [...
        uicontrol('Parent', buttonpanel,...
        'Style', 'pushbutton',...
        'String', 'End'),...
        uicontrol('Parent', buttonpanel,...
        'Style', 'pushbutton',...
        'String', 'Abort')];
      set(obj.StopButtons, 'Enable', 'off', 'Visible', 'off');
      uicontrol('Parent', buttonpanel,...
        'Style', 'pushbutton',...
        'String', 'Parameters...',...
        'Callback', @(~, ~) obj.viewParams());
    
      % Build the psychometric axes
      plotgrid = uiextras.Grid('Parent', obj.CustomPanel, 'Padding', 5);
      uiextras.Empty('Parent', plotgrid, 'Visible', 'off');
      uiextras.Empty('Parent', plotgrid, 'Visible', 'off');
      uiextras.Empty('Parent', plotgrid, 'Visible', 'off');
      uiextras.Empty('Parent', plotgrid, 'Visible', 'off');
      obj.PsychometricAxes = bui.Axes(plotgrid);
      obj.PsychometricAxes.ActivePositionProperty = 'position';
      obj.PsychometricAxes.YLim = [-1 101];
      obj.PsychometricAxes.NextPlot = 'add';
      
      uiextras.Empty('Parent', plotgrid, 'Visible', 'off');
      obj.ExperimentAxes = bui.Axes(plotgrid);
      obj.ExperimentAxes.ActivePositionProperty = 'position';
      obj.ExperimentAxes.XTickLabel = [];
      obj.ExperimentAxes.XLim = [-obj.Parameters.Struct.stimulusAzimuth...
          obj.Parameters.Struct.stimulusAzimuth];
      obj.ExperimentAxes.NextPlot = 'add';
      uiextras.Empty('Parent', plotgrid, 'Visible', 'off');
      uiextras.Empty('Parent', plotgrid, 'Visible', 'off');
            
      plotgrid.ColumnSizes = [50 -1 10];
      plotgrid.RowSizes = [-1 50 -2 40];
    end
  end
  
end

