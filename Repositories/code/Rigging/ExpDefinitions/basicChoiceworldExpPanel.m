classdef basicChoiceworldExpPanel < eui.ExpPanel
  %BASICCHOICEWORLDEXPPANEL 
  % AP 2017-03-31 created
  % MW 2018-01-01 modified
  % plotting panel for basicChoiceworldExpPanel
  
  properties
    SignalUpdates = struct('name', cell(500,1), 'value', cell(500,1), 'timestamp', cell(500,1))
    NumSignalUpdates = 0
    LabelsMap
    RecentColour = [0 1 0]
  end
  
  properties (Access = protected)
    PsychometricAxes % Handle to axes of psychometric plot
    ExperimentAxes % Handle to axes of wheel trace
    ThresholdLineAxes % Handle to axes of right/wrong threshold line plot
    InputSensorPlot % Handle to axes for wheel trace plot
    InputSensorPosTime % Vector of timesstamps in seconds for plotting the wheel trace
    InputSensorPos % Vector of azimuth values for plotting the wheel trace
    InputSensorPosCount = 0 % Running total of azimuth samples recieved for axes plot
    ExtendThresholdLines = false % Flag for plotting dotted threshold lines during cue interactive delay.  Currently unused.
  end

  
  methods
    function obj = basicChoiceworldExpPanel(parent, ref, params, logEntry)
      obj = obj@eui.ExpPanel(parent, ref, params, logEntry);
      obj.LabelsMap = containers.Map();
      % Initialize InputSensor properties for speed
      obj.InputSensorPos = nan(1000*60*60*2, 1);
      obj.InputSensorPosTime = nan(1000*60*60*2, 1);
      obj.InputSensorPosCount = 0;
    end
    
    function update(obj)
      update@eui.ExpPanel(obj);
      processUpdates(obj); % update labels with latest signal values
%       labels = cell2mat(values(obj.LabelsMap))';
      labelsMapVals = values(obj.LabelsMap)';
      labels = gobjects(size(values(obj.LabelsMap)));
      for i=1:length(labelsMapVals) % using for loop (sorry Chris!) to populate object array 2017-02-14 MW
          labels(i) = labelsMapVals{i};
      end
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
          case {'events.newTrial', 'events.stimAzimuth', 'outputs.reward',...
                  'events.stimOn', 'events.expStart', 'events.response',...
                  'events.sessionPerformance', 'events.stimOff',...
                  'events.endTrial', 'events.repeatOnMiss', 'events.staircase',...
                  'events.hitBuffer', 'events.interactiveOn', 'events.contrasts',...
                  'events.azimuth'}
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
          
          %update sensor pos plot with new data
          plotwindow = [-5 0]; t = 0;
          % Record the current trial contrast
          idx = strcmp('events.trialSide', {updates.name});
          if any(idx); obj.Block.trialSide = updates(idx).value; end
          if isfield(obj.Block,'trialSide')
            side = obj.Block.trialSide;
          else
            side = [];
          end
          % After a response has been given set the threshold bars to be
          % white
          idx = strcmp('events.response',{updates.name});
          if any(idx)
            side = [];
            t = (24*3600*datenum(updates(idx).timestamp))-(24*3600*obj.StartedDateTime);
            lastidx = obj.InputSensorPosCount + 1;
            obj.InputSensorPosCount = lastidx;
            obj.InputSensorPos(lastidx) = NaN;
            obj.InputSensorPosTime(lastidx) = t(end);
          end
          % Update wheel trace
          idx = strcmp('events.azimuth', {updates.name});
          if any(idx)
            x = updates(idx).value-(side*90);
            t = (24*3600*datenum(updates(idx).timestamp))-(24*3600*obj.StartedDateTime);
            % Downsample wheel trace plot to 10Hz
            if obj.InputSensorPosCount==0||...
                    t(end)-obj.InputSensorPosTime(obj.InputSensorPosCount) > 0.1
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
            end
          end
          
          if sign(side)==1
            leftSpec = 'g';
            rightSpec = 'r';
          elseif sign(side)==-1
            leftSpec = 'r';
            rightSpec = 'g';
          elseif isempty(side)
            leftSpec = 'w';
            rightSpec = 'w';
          else
            leftSpec = 'g';
            rightSpec = 'g';
          end
          azimuth = 90; % Starting azimuth is hard-coded in basicChoiceWorld
          
          if isempty(obj.ThresholdLineAxes)
            obj.ThresholdLineAxes = obj.ExperimentAxes.plot(...
               [-azimuth -azimuth], plotwindow + t, leftSpec,... %L boundary
               [azimuth  azimuth], plotwindow + t, rightSpec,'LineWidth', 4);%R boundary
          else
            set(obj.ThresholdLineAxes(1),...
              'XData', [-azimuth -azimuth], 'YData', plotwindow + t,...
              'Color', leftSpec);
            set(obj.ThresholdLineAxes(2),...
              'XData', [azimuth azimuth], 'YData', plotwindow + t,...
              'Color', rightSpec);
          end

          % Plot psychometric
          idx = strcmp('events.sessionPerformance',{updates.name});
          if any(idx)
              curr_performance_data = updates(idx).value;
              conditions = curr_performance_data(1,:);
              leftward = curr_performance_data(3,:)./curr_performance_data(2,:);
              obj.PsychometricAxes.plot(conditions(~isnan(leftward)), ...
                  leftward(~isnan(leftward)),'o-k');
              obj.PsychometricAxes.XLim = [-1,1];
              obj.PsychometricAxes.YLim = [0,1];
              xLabel(obj.PsychometricAxes,'Condition');
              yLabel(obj.PsychometricAxes,'% Left');
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
      obj.CustomPanel = uiextras.HBox('Parent', obj.MainVBox);
      
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
      obj.PsychometricAxes.YLim = [0 1];
      obj.PsychometricAxes.XLim = [-1 1];
      obj.PsychometricAxes.NextPlot = 'add';
      xLabel(obj.PsychometricAxes,'Condition');
      yLabel(obj.PsychometricAxes,'% Left');
      hold(obj.PsychometricAxes.Handle, 'off');

      
      uiextras.Empty('Parent', plotgrid, 'Visible', 'off');
      obj.ExperimentAxes = bui.Axes(plotgrid);
      obj.ExperimentAxes.ActivePositionProperty = 'position';
      obj.ExperimentAxes.XTickLabel = [];
      obj.ExperimentAxes.XLim = [-90 90]; % Starting azimuth is hard-coded in basicChoiceWorld
      obj.ExperimentAxes.NextPlot = 'add';
      uiextras.Empty('Parent', plotgrid, 'Visible', 'off');
      uiextras.Empty('Parent', plotgrid, 'Visible', 'off');
      
      obj.PsychometricAxes.yLabel('% right-ward');
      
      plotgrid.ColumnSizes = [50 -1 10];
      plotgrid.RowSizes = [-1 50 -2 40];    
    end
  end
  
end

