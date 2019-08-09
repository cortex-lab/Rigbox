classdef ExpPanel < handle
  %EUI.EXPPANEL Basic UI control for monitoring an experiment
  %   The EXPPANEL superclass is instantiated by MCONTROL when an
  %   experiment is started through MC.  The object adds listeners for
  %   updates broadcast by the rig (defined in the _rig_ object) and
  %   updates plots and text as the experiment progresses.  Additionally
  %   there are buttons to end or abort the experiment and to view the
  %   experimental parameters (the _paramStruct_).  
  %   EXPPANEL is not stand-alone and thus requires a handle to a parent
  %   window.  This class has a number of subclasses, one for each
  %   experiment type, for example CHOICEEXPPANEL for ChoiceWorld and
  %   SQUEAKEXPPANEL for Signals experiments.  
  %
  %
  % See also SQUEAKEXPPANEL, CHOICEEXPPANEL, MCONTROL, MC
  %
  % Part of Rigbox
  
  % 2013-06 CB created
  % 2017-05 MW added Alyx compatibility
  
  properties
    Block = struct('numCompletedTrials', 0, 'trial', struct([])) % A structure to hold update information relevant for the plotting of psychometics and performance calculations
    %log entry pertaining to this experiment
    LogEntry
    Listeners
  end
  
  properties (Access = protected)
    ExpRunning = false % A flag indicating whether the experiment is still running
    ActivePhases = {}
    Root
    Ref % The experimental reference (expRef).  
    SubjectRef % A string representing the subject's name
    InfoGrid % Handle to the UIX.GRID UI object that holds contains the InfoFields and InfoLabels
    InfoLabels %label text controls for each info field
    InfoFields %field controls for each info field
    StatusLabel % A text field displaying the status of the experiment, i.e. the current phase of the experiment
    TrialCountLabel % A counter displaying the current trial number
    ConditionLabel
    DurationLabel
    StopButtons % Handles to the End and Abort buttons, used to terminate an experiment through the UI
    StartedDateTime
%     ElapsedTimer
    CloseButton % The little x at the top right of the panel.  Deletes the object.
    CommentsBox % A handle to text box.  Text inputed to this box is saved in the subject's LogEntry
    CustomPanel % Handle to a UI box where any number of platting axes my be placed by subclasses
    MainVBox % Handle to the main box containing all labels, buttons and UI boxes for this panel
    Parameters % A structure of experimental parameters used by this experiment
  end
  
  methods (Static)
    function p = live(parent, ref, remoteRig, paramsStruct)
      subject = dat.parseExpRef(ref); % Extract subject, date and seq from experiment ref
      try
        logEntry = dat.addLogEntry(... % Add new entry to log
          subject, now, 'experiment-info', struct('ref', ref), '', remoteRig.AlyxInstance);
      catch ex
        logEntry.comments = '';
        warning(ex.getReport());
      end
      params = exp.Parameters(paramsStruct); % Get parameters
      % Can define your own experiment panel
      if isfield(params.Struct, 'expPanelFun')&&~isempty(params.Struct.expPanelFun)
        % FIXME This should be done with fileFunction and this use of which
        % may not work on newer versions of MATLAB
        if isempty(which(params.Struct.expPanelFun)); addpath(fileparts(params.Struct.defFunction)); end
        p = feval(params.Struct.expPanelFun, parent, ref, params, logEntry);
      else % otherwise use the default
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
      p.Root.Title = sprintf('%s on ''%s''', p.Ref, remoteRig.Name); % Set experiment panel title
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
      % EXPSTARTED Callback for the ExpStarted event.
      %   Updates the ExpRunning flag, the panel title and status label to
      %   show that the experiment has officially begun.
      %   
      % See also EXPSTOPPED
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
    
    function expStopped(obj, rig, ~)
      % EXPSTOPPED Callback for the ExpStopped event.
      %   expStopped(obj, rig, event) Updates the ExpRunning flag, the
      %   panel title and status label to show that the experiment has
      %   ended.  This function also records to Alyx the amount of water,
      %   if any, that the subject received during the task.
      %   
      %   TODO: Move water to save data functions
      % See also EXPSTARTED, ALYX.POSTWATER
      set(obj.StatusLabel, 'String', 'Completed'); %staus to completed
      obj.ExpRunning = false;
      set(obj.StopButtons, 'Enable', 'off'); %disable stop buttons
      %stop listening to further rig events
      obj.Listeners = [];
      obj.Root.TitleColor = [1 0.3 0.22]; % red title area
      %post water to Alyx
%       ai = rig.AlyxInstance;
%       subject = obj.SubjectRef;
%       if ~isempty(ai)&&~strcmp(subject,'default')
%           switch class(obj)
%               case 'eui.ChoiceExpPanel'
%                   if ~isfield(obj.Block.trial,'feedbackType'); return; end % No completed trials
%                   if any(strcmp(obj.Parameters.TrialSpecificNames,'rewardVolume')) % Reward is trial specific 
%                       condition = [obj.Block.trial.condition];
%                       reward = [condition.rewardVolume];
%                       amount = sum(reward(:,[obj.Block.trial.feedbackType]==1), 2);
%                   else % Global reward x positive feedback
%                       amount = obj.Parameters.Struct.rewardVolume(1)*...
%                           sum([obj.Block.trial.feedbackType]==1);
%                   end
%                   if numel(amount)>1; amount = amount(1); end % Take first element (second being laser)
%             otherwise
%                 % Done in exp.SignalsExp/saveData
%                   %infoFields = {obj.InfoFields.String};
%                   %inc = cellfun(@(x) any(strfind(x(:)','µl')), {obj.InfoFields.String}); % Find event values ending with 'ul'.
%                   %reward = cell2mat(cellfun(@str2num,strsplit(infoFields{find(inc,1)},'µl'),'UniformOutput',0));
%                   %amount = iff(isempty(reward),0,@()reward);
%           end
%           if ~any(amount); return; end % Return if no water was given
%           try
%             ai.postWater(subject, amount*0.001, now, 'Water', ai.SessionURL);
%           catch
%             warning('Failed to post the %.2fml %s recieved during the experiment to Alyx', amount*0.001, subject);
%           end
%       end
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
      % MERGETRIALDATA Update the local block structure with data from the
      % last trial
      %   This is only used by CHOICEEXPPANEL, etc. where trial data we
      %   constant and had a predefined structure.  This is not used by the
      %   SQEUEAKEXPPANEL sub-class.
      %
      % See also EXPUPDATE
      fields = fieldnames(data);
      for i = 1:numel(fields)
        f = fields{i};
        obj.Block.trial(idx).(f) = data.(f);
      end
    end
    
    function saveLogEntry(obj)
      % SAVELOGENTRY Saves the obj.LogEntry to disk and to Alyx
      %  As the log entry has been updated throughout the experiment with
      %  comments and experiment end times, it must be saved to disk.  In
      %  addition if an Alyx Instance is set, the comments are saved to the
      %  subsession's narrative field.
      % 
      % See also DAT.UPDATELOGENTRY, COMMENTSCHANGED
      dat.updateLogEntry(obj.SubjectRef, obj.LogEntry.id, obj.LogEntry);
    end
    
    function viewParams(obj)
      % VIEWPARAMS The callback for the Parameters button.
      %   Creates a new figure to display the current experimental
      %   parameters (the sructure in obj.Parameters).  
      %
      %   See also EUI.PARAMEDITOR
      f = figure('Name', sprintf('%s Parameters', obj.Ref),...
        'MenuBar', 'none',...
        'Toolbar', 'none',...
        'NumberTitle', 'off',...
        'Units', 'normalized');%...
      %         'OuterPosition', [0.1 0.2 0.8 0.7]);
      params = obj.Parameters;
      editor = eui.ParamEditor(params, f);
      editor.Enable = 'off'; % The parameter field should not be editable as the experiment has already started
    end
    
    function [fieldCtrl] = addInfoField(obj, label, field)
      obj.InfoLabels = [bui.label(label, obj.InfoGrid); obj.InfoLabels];
      fieldCtrl = bui.label(field, obj.InfoGrid);
      obj.InfoFields = [fieldCtrl; obj.InfoFields];
      %reorder the chilren on the grid since it expects controls to be
      %ordered in descending columns
      obj.InfoGrid.Children = [obj.InfoFields; obj.InfoLabels];
      FieldHeight = 20; %default
      nRows = numel(obj.InfoLabels);
      obj.InfoGrid.RowSizes = repmat(FieldHeight, 1, nRows);
      %specify more space in parent control for infogrid
      obj.MainVBox.Sizes(1) = FieldHeight*nRows;
    end
    
    function commentsChanged(obj, src, ~)
      % COMMENTSCHANGED Callback for saving comments to server and Alyx
      %  This function is called when text in the comments box is changed
      %  and reports this in the command window
      %
      %  See also SAVELOGENTRY, LIVE
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
%       obj.InfoGrid.ColumnSizes = [100, -1]; % Error: Size of property 'Widths' must be no larger than size of contents.

      %panel for subclasses to add their own controls to
      obj.CustomPanel = uiextras.VBox('Parent', obj.MainVBox); % Custom Panel is where the live plots will go
      
      bui.label('Comments', obj.MainVBox); % Comments label at bottom of experiment panel
      
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
        'String', 'End',...
        'TooltipString', 'End experiment'),...
        uicontrol('Parent', buttonpanel,...
        'Style', 'pushbutton',...
        'String', 'Abort',...
        'TooltipString', 'Abort experiment without posting water to Alyx')];
      set(obj.StopButtons, 'Enable', 'off', 'Visible', 'off');
      uicontrol('Parent', buttonpanel,...
        'Style', 'pushbutton',...
        'String', 'Parameters...',...
        'Callback', @(~, ~) obj.viewParams());
    end
  end
  
end

