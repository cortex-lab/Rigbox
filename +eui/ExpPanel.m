classdef ExpPanel < handle
  %EUI.EXPPANEL Basic UI control for monitoring an experiment
  %   TODO
  %
  % Part of Rigbox
  
  % 2013-06 CB created
  
  properties
    Block = struct('numCompletedTrials', 0, 'trial', struct([]))
    %log entry pertaining to this experiment
    LogEntry
    Listeners
  end
  
  properties (Access = protected)
    ExpRunning = false
    ActivePhases = {}
    Root
    Ref
    SubjectRef
    InfoGrid
    InfoLabels %label text controls for each info field
    InfoFields %field controls for each info field
    StatusLabel
    TrialCountLabel
    ConditionLabel
    DurationLabel
    StopButtons
    StartedDateTime
%     ElapsedTimer
    CloseButton
    CommentsBox
    CustomPanel
    MainVBox
    Parameters
  end
  
  methods (Static)
    function p = live(parent, ref, remoteRig, paramsStruct)
      subject = dat.parseExpRef(ref);
      try
        logEntry = dat.addLogEntry(...
          subject, now, 'experiment-info', struct('ref', ref), '');
      catch ex
        logEntry.comments = '';
        warning(ex.getReport());
      end
      params = exp.Parameters(paramsStruct);
      if isfield(params.Struct, 'expPanelFun')
        p = params.Struct.expPanelFun(parent, ref, params, logEntry);
      else
        switch params.Struct.type
          case {'SingleTargetChoiceWorld' 'ChoiceWorld' 'DiscWorld' 'SurroundChoiceWorld'}
            p = eui.ChoiceExpPanel(parent, ref, params, logEntry);
%           case 'GaborMapping'
%             p = eui.GaborMappingExpPanel(parent, ref, params, logEntry);
          case 'BarMapping'
            p = eui.MappingExpPanel(parent, ref, params, logEntry);
          case {'PositionTargetRange'}
            p = eui.RangeExpPanel(parent, ref, params, logEntry);
          case 'custom'
            p = eui.SqueakExpPanel(parent, ref, params, logEntry);
          otherwise
            p = eui.ExpPanel(parent, ref, params, logEntry);
        end
      end
      
      set(p.StopButtons(1), 'Callback',...
        @(src, ~) fun.run(true,...
        @() remoteRig.quitExperiment(false),...
        @() set(src, 'Enable', 'off')));
      set(p.StopButtons(2), 'Callback',...
        @(src, ~) fun.run(true,...
        @() remoteRig.quitExperiment(true),...
        @() set(p.StopButtons, 'Enable', 'off')));
      
      p.Root.Title = sprintf('%s on ''%s''', p.Ref, remoteRig.Name);
      p.Listeners = [...
        ...event.listener(remoteRig, 'Connected', @p.expStarted)
        ...event.listener(remoteRig, 'Disconnected', @p.expStopped)
        event.listener(remoteRig, 'ExpStarted', @p.expStarted)
        event.listener(remoteRig, 'ExpStopped', @p.expStopped)
        event.listener(remoteRig, 'ExpUpdate', @p.expUpdate)];
%       p.ElapsedTimer = timer('Period', 0.9, 'ExecutionMode', 'fixedSpacing',...
%         'TimerFcn', @(~,~) set(p.DurationLabel, 'String',...
%         sprintf('%i:%02.0f', floor(p.elapsed/60), mod(p.elapsed, 60))));
    end
  end
  
  methods
    function obj = ExpPanel(parent, ref, params, logEntry)
      obj.Ref = ref;
      obj.SubjectRef = dat.parseExpRef(ref);
      obj.LogEntry = logEntry;
      obj.Parameters = params;
      obj.build(parent);
    end
    
    function delete(obj)
      disp('ExpPanel destructor called');
      obj.cleanup();
      if obj.Root.isvalid
        obj.Root.delete();
      end
    end
    
    function update(obj)
      if obj.ExpRunning
        elapsed = round(etime(datevec(now), datevec(obj.StartedDateTime)));
        set(obj.DurationLabel, 'String',...
          sprintf('%i:%02.0f', floor(elapsed/60), rem(elapsed, 60)));
      end
    end
  end
  
  methods %(Access = protected)
    function cleanup(obj)
%       if ~isempty(obj.ElapsedTimer)
%         t = obj.ElapsedTimer;
%         stop(t);
%         delete(t);
%         obj.ElapsedTimer = [];
%       end
    end
    
    function closeRequest(obj, src, evt)
      obj.delete();
    end
    
    function newTrial(obj, num, condition)
      %do nothing, this is for subclasses to override and react to
    end
    
    function trialCompleted(obj, num, data)
      %do nothing, this is for subclasses to override and react to
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
    
    function expStarted(obj, rig, evt)
      if strcmp(evt.Ref, obj.Ref)
        set(obj.StatusLabel, 'String', 'Running'); %staus to running
        set(obj.StopButtons, 'Enable', 'on', 'Visible', 'on'); %enable stop buttons
        obj.StartedDateTime = now; %take note of the experiment start time
        obj.ExpRunning = true;
      else
        %started experiment does not match expected
        %staus to error
        set(obj.StatusLabel, 'String',...
          'Error (inconsistent experiment ref from rig)');
        %stop listening to further rig events
        obj.Listeners = [];
      end
    end
    
    function expStopped(obj, rig, evt)
      set(obj.StatusLabel, 'String', 'Completed'); %staus to completed
      obj.ExpRunning = false;
      set(obj.StopButtons, 'Enable', 'off'); %disable stop buttons
      %stop listening to further rig events
      obj.Listeners = [];
      obj.Root.TitleColor = [1 0.3 0.22]; % red title area
    end
    
    function expUpdate(obj, rig, evt)
      type = evt.Data{1};
      switch type
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
    
    function mergeTrialData(obj, idx, data)
      fields = fieldnames(data);
      for i = 1:numel(fields)
        f = fields{i};
        obj.Block.trial(idx).(f) = data.(f);
      end
    end
    
    function saveLogEntry(obj)
      dat.updateLogEntry(obj.SubjectRef, obj.LogEntry.id, obj.LogEntry);
    end
    
    function viewParams(obj)
      f = figure('Name', sprintf('%s Parameters', obj.Ref),...
        'MenuBar', 'none',...
        'Toolbar', 'none',...
        'NumberTitle', 'off',...
        'Units', 'normalized');%...
      %         'OuterPosition', [0.1 0.2 0.8 0.7]);
      params = obj.Parameters;
      editor = eui.ParamEditor(params, f);
      editor.Enable = 'off';
    end
    
    function [fieldCtrl] = addInfoField(obj, label, field)
      obj.InfoLabels = [obj.InfoLabels; bui.label(label, obj.InfoGrid)];
      fieldCtrl = bui.label(field, obj.InfoGrid);
      obj.InfoFields = [obj.InfoFields; fieldCtrl];
      %reorder the chilren on the grid since it expects controls to be
      %ordered in descending columns
      obj.InfoGrid.Children = [obj.InfoLabels; obj.InfoFields];
      FieldHeight = 20; %default
      nRows = numel(obj.InfoLabels);
      obj.InfoGrid.RowSizes = repmat(FieldHeight, 1, nRows);
      %specify more space in parent control for infogrid
      obj.MainVBox.Sizes(1) = FieldHeight*nRows;
    end
    
    function commentsChanged(obj, src, evt)
      disp('saving comments');
      obj.LogEntry.comments = get(src, 'String');
      obj.saveLogEntry();
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
      obj.InfoGrid.ColumnSizes = [100, -1];
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
      obj.TrialCountLabel = obj.addInfoField('Trial count', '0');
      
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
    end
  end
  
end

