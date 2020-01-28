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
  %   SIGNALSEXPPANEL for Signals experiments.  
  %
  %
  % See also SIGNALSEXPPANEL, CHOICEEXPPANEL, MCONTROL, MC
  %
  % Part of Rigbox
  
  % 2013-06 CB created
  % 2017-05 MW added Alyx compatibility
  
  properties
    % A structure to hold update information relevant for the plotting of
    % psychometics and performance calculations.  This is updated as new
    % ExpUpdate events occur.  See also mergeTrialData
    Block = struct('numCompletedTrials', 0, 'trial', struct([]))
    % Log entry pertaining to this experiment
    LogEntry
    % An array of listener handles for the remote rig, added by the live
    % static constructor method
    Listeners
  end
  
  properties (Access = protected)
    % A flag indicating whether the experiment is still running
    ExpRunning = false
    % A list of active experiment phases
    ActivePhases = {}
    % The root BoxPanel container
    Root
    % The experimental reference string (expRef)
    Ref
    % A string representing the subject's name
    SubjectRef
    % Handle to the UIX.GRID UI object that holds contains the InfoFields
    % and InfoLabels
    InfoGrid
    % Label text controls for each info field
    InfoLabels
    % Field UI controls for each info field
    InfoFields
    % A text field displaying the status of the experiment, i.e. the
    % current phase of the experiment
    StatusLabel
    % A counter displaying the current trial number
    TrialCountLabel
    % A condition index counter.  Only used if the parameters contains a
    % conditionId parameter
    ConditionLabel
    % A counter for the experiment duration
    DurationLabel
    % Handles to the End and Abort buttons, used to terminate an experiment
    % through the UI
    StopButtons
    % The datetime when the ExpPanel was instantiated
    StartedDateTime
    % The little x at the top right of the panel.  Deletes the object
    CloseButton
    % A handle to text box.  Text inputed to this box is saved in the
    % subject's LogEntry
    CommentsBox
    % Handle to a UI box where any number of platting axes my be placed by
    % subclasses
    CustomPanel
    % Handle to the main box containing all labels, buttons and UI boxes
    % for this panel
    MainVBox
    % A structure of experimental parameters used by this experiment
    Parameters exp.Parameters
    % Holds a context menu for show/hide options for info fields
    UIContextMenu
  end
  
  methods (Static)
    function p = live(parent, ref, remoteRig, paramsStruct, varargin)
      % LIVE Constuct a new ExpPanel based on experiment parameter provided
      %  Create a new ExpPanel for monitoring an experiment.  Depending on
      %  the `type` and, in the case of a Signals Experiment, `expPanelFun`
      %  parameters, a different subclass may be invoked.
      %
      %  Inputs:
      %    parent : the parent figure or container for the panel.
      %    ref (char) : an experiment reference.
      %    remoteRig (srv.StimulusControl) : the remote rig communicator
      %      object for receiving experiment events.
      %    paramsStruct (struct) : the experiment parameters structure.
      %      The type parameter is used to determine which subclass is to
      %      be instantiated.  For type 'custom' the default panel may be
      %      overridden via the `expPanelFun` parameter.
      %
      %  Optional Name-Value pairs:
      %    ActivateLog (logical) : flag indicating whether to save a new
      %      log entry for the experiment (default true).  For test
      %      experiments this flag may be set to false.
      %    StartedTime (double) : If the experiment has already started,
      %      the datetime of the experiment start (default []).
      %
      %  Outputs:
      %    p (eui.ExpPanel) : handle to the panel object.
      % 
      in = inputParser;
      addRequired(in, 'parent');
      addRequired(in, 'ref');
      addRequired(in, 'remoteRig');
      addRequired(in, 'paramsStruct');
      % Activate log
      addOptional(in, 'activateLog', true);
      % Resume experiment listening (experiment had alread started)
      addOptional(in, 'startedTime', []);
      in.parse(parent, ref, remoteRig, paramsStruct, varargin{:})
      
      in = in.Results; % Final parameters
      if in.activateLog
        subject = dat.parseExpRef(ref); % Extract subject, date and seq from experiment ref
        try
          logEntry = dat.addLogEntry(... % Add new entry to log
            subject, now, 'experiment-info', struct('ref', ref), '', remoteRig.AlyxInstance);
        catch ex
          logEntry.comments = '';
          warning(ex.getReport());
        end
      else
        logEntry = [];
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
          case 'BarMapping'
            p = eui.MappingExpPanel(parent, ref, params, logEntry);
          case 'custom'
            p = eui.SignalsExpPanel(parent, ref, params, logEntry);
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
      
      if ~isempty(in.startedTime)
        % If the experiment has all ready started, trigger all dependent
        % events.
        p.expStarted(remoteRig, srv.ExpEvent('started', ref, p.startedTime));
        p.event('experimentStarted', p.startedTime)
      end
        
      p.Listeners = [...
        ...event.listener(remoteRig, 'Connected', @p.expStarted)
        ...event.listener(remoteRig, 'Disconnected', @p.expStopped)
        event.listener(remoteRig, 'ExpStarted', @p.expStarted)
        event.listener(remoteRig, 'ExpStopped', @p.expStopped)
        event.listener(remoteRig, 'ExpUpdate', @p.expUpdate)];
    end
  end
  
  methods
    function obj = ExpPanel(parent, ref, params, logEntry)
      % Subclasses must chain a call to this.
      obj.Ref = ref;
      obj.SubjectRef = dat.parseExpRef(ref);
      obj.LogEntry = logEntry;
      obj.Parameters = params;
      obj.build(parent);
    end
    
    function cleanup(obj)
      % CLEANUP Cleanup panel For subclasses to implement.  Use this method
      % to release listener handles and clear any accumulated data that is
      % no longer required after the experiment has ended.
    end
    
    function delete(obj)
      disp('ExpPanel destructor called');
      if obj.Root.isvalid
        obj.Root.delete();
      end
    end
    
    function update(obj)
      % UPDATE Update the panel
      %  Updates the duration label counter.  This method is the callback
      %  to the RefreshTimer in MC.  Subclasses must chain a call to this.
      %
      % See also eui.ExpPanel/update
      if obj.ExpRunning
        elapsed = round(etime(datevec(now), datevec(obj.StartedDateTime)));
        set(obj.DurationLabel, 'String',...
          sprintf('%i:%02.0f', floor(elapsed/60), rem(elapsed, 60)));
      end
    end
  end
  
  methods (Access = protected)
    
    function closeRequest(obj, src, evt)
      % CLOSEREQUEST Callback to the close button
      %  Callback to the little 'x' in the corner of the panel.  Deletes
      %  the panel.
      obj.delete();
    end
    
    function newTrial(obj, num, condition)
      % NEWTRIAL Process new trial conditions
      %  Do nothing, this is for subclasses to override and react to, e.g.
      %  to update plots, etc. based on a new trial's conditional
      %  parameters.  Called by expUpdate method upon 'newTrial' event.
      %  
      %  Inputs:
      %    num (int) : The new trial number.  May be used to index into
      %                Block property
      %    condition (struct) : Condition data for the new trial
      %
      % See also expUpdate, trialCompleted
    end
    
    function trialCompleted(obj, num, data)
      % TRIALCOMPLETED Process completed trial data
      %  Do nothing, this is for subclasses to override and react to, e.g.
      %  to update plots, etc. based on a complete trial's data.  Called by
      %  expUpdate method upon 'trialData' event.
      %  
      %  Inputs:
      %    num (int) : The new trial number.  May be used to index into
      %                Block property
      %    data (struct) : Completed trial data
      %
      % See also expUpdate, trialCompleted
    end
    
    function event(obj, name, t)
      % EVENT Called when an experiment event occurs
      %  Called by expUpdate callback to process all miscellaneous events,
      %  i.e. experiment phases.  This method is downstream of srv.ExpEvent
      %  events.  Updates ActivePhases list as well as the panel title
      %  colour and, upon phase changes, the Status info field.
      %
      %  Inputs:
      %    name (char) : The event name
      %    t (date vec) : The time the event occured
      %
      %  Example:
      %    if strcmp(evt.Data{1}, 'event') % srv.ExpEvent object
      %      % Pass event info to be processed
      %      obj.event(evt.Data{2}, evt.Data{3})
      %    end
      
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
      %   Inputs:
      %     rig (srv.StimulusControl) : The source of the event
      %     evt (srv.ExpEvent) : The experiment event object
      %   
      % See also EXPSTOPPED
      if strcmp(evt.Ref, obj.Ref) || isempty([evt.Ref, obj.Ref])
        set(obj.StatusLabel, 'String', 'Running'); %staus to running
        set(obj.StopButtons, 'Enable', 'on', 'Visible', 'on'); %enable stop buttons
        % Take note of the experiment start time
        obj.StartedDateTime = iff(isempty(evt.Data), now, evt.Data); 
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
      %   Inputs:
      %     rig (srv.StimulusControl) : The source of the event
      %     evt (srv.ExpEvent) : The experiment event object
      %   
      % See also EXPSTARTED, ALYX.POSTWATER
      set(obj.StatusLabel, 'String', 'Completed'); %staus to completed
      obj.ExpRunning = false;
      set(obj.StopButtons, 'Enable', 'off'); %disable stop buttons
      %stop listening to further rig events
      obj.Listeners = [];
      obj.Root.TitleColor = [1 0.3 0.22]; % red title area
    end
    
    function expUpdate(obj, rig, evt)
      % EXPUPDATE Callback to the remote rig ExpUpdate event
      %  Processes a new experiment event.  Events include 'newTrial',
      %  'trialData', 'signals', 'event'.
      %
      %   Inputs:
      %     rig (srv.StimulusControl) : The source of the event
      %     evt (srv.ExpEvent) : The experiment event object
      %
      % See also live, event, srv.StimulusControl, srv.ExpEvent
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
      % ADDINFOFIELD Add new event info field to InfoGrid
      %  Adds a given field to the grid and adjusts the total height of the
      %  grid to accomodate all current fields.
      %
      % FIXME Fields with large values, e.g. arrays or chars are cut off
      rowH = 20; % default height of each field
      obj.InfoLabels = [bui.label(label, obj.InfoGrid); obj.InfoLabels];
      fieldCtrl = bui.label(field, obj.InfoGrid);
      obj.InfoFields = [fieldCtrl; obj.InfoFields];
      if isempty(obj.UIContextMenu)
        obj.UIContextMenu = uicontextmenu(ancestor(obj.Root, 'Figure'));
        uimenu(obj.UIContextMenu, 'Label', 'Hide field',...
          'MenuSelectedFcn', @(~,~) obj.hideInfoField);
        uimenu(obj.UIContextMenu, 'Label', 'Reset hidden',...
          'MenuSelectedFcn', @(~,~) obj.showAllFields);
      end
      set([obj.InfoLabels(1), fieldCtrl], 'UIContextMenu', obj.UIContextMenu)
      % reorder the chilren on the grid since it expects controls to be
      % ordered in descending columns
      obj.InfoGrid.Children = [obj.InfoFields; obj.InfoLabels];
      fieldHeights = fliplr(strcmp({obj.InfoFields.Visible},'on') * rowH);
      obj.InfoGrid.RowSizes = fieldHeights;
      % specify more space in parent control for infogrid
      obj.MainVBox.Sizes(1) = sum(fieldHeights);
    end
    
    function showAllFields(obj)
      % SHOWALLFIELDS Show all hidden info fields
      %  Callback for the 'Reset hidden' ui menu item.  Sets all fields to
      %  visible and resets row sizes to default height.
      %
      % See also HIDEINFOFIELD, ADDINFOFIELD
      rowHeight = 20;
      set([obj.InfoGrid.Children], 'Visible', 'on');
      obj.InfoGrid.RowSizes(obj.InfoGrid.RowSizes == 0) = rowHeight;
      obj.MainVBox.Sizes(1) = sum(obj.InfoGrid.RowSizes);
    end
    
    function hideInfoField(obj)
      % HIDEINFOFIELD Hides the currently selected field row
      %  Callback for the 'Hide field' ui menu item.  Turns off the
      %  visiblity of the currently selected field and sets its row height
      %  to 0.
      %  
      % See also SHOWALLFIELDS, ADDINFOFIELD
      selected = get(ancestor(obj.Root, 'Figure'), 'CurrentObject');
      [row, ~] = find([obj.InfoFields, obj.InfoLabels] == selected, 1);
      set([obj.InfoFields(row), obj.InfoLabels(row)], 'Visible', 'off')
      invisible = fliplr(strcmp({obj.InfoFields.Visible}, 'off'));
      obj.InfoGrid.RowSizes(invisible) = 0;
      obj.MainVBox.Sizes(1) = obj.MainVBox.Sizes(1)-20;
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
    
    function toggleCommentsBox(obj, src, ~)
      % TOGGLECOMMENTSBOX Show/hide the comments box
      %  Callback for the comments uimenu.  If 'Hide Comments' uimenu
      %  selected, set the height of obj.CommentsBox to 0 and change menu
      %  option to 'Show Comments'.  The previous height of the box is
      %  stored in the object's UserData field.
      
      % Find the position of the CommentsBox within its parent container
      idx = flipud(obj.CommentsBox.Parent.Children == obj.CommentsBox);
      if strcmp(src.Text, 'Show comments')
        src.Text = 'Hide Comments';
        obj.CommentsBox.Visible = 'on';
        % Get previous height from UserData field, otherwise choose 80
        boxHeight = pick(obj.CommentsBox, 'UserData', 'def', 80);
        obj.CommentsBox.Parent.Heights(idx) = boxHeight;
        set(findobj('String', 'Comments [...]'), 'String', 'Comments')
      else % Hide comments
        src.Text = 'Show comments';
        obj.CommentsBox.Visible = 'off';
        % Save the previous height in UserData
        obj.CommentsBox.UserData = obj.CommentsBox.Parent.Heights(idx);
        obj.CommentsBox.Parent.Heights(idx) = 0;
        set(findobj('String', 'Comments'), 'String', 'Comments [...]')
      end
    end
    
    function build(obj, parent)
      % BUILD Build the panel UI
      %  Creates the BoxPanel and within it a container for info fields
      %  (InfoGrid), a container for subclasses to add custom plots
      %  (CustomPanel) and the buttons and comments box.  If the LogEntry
      %  is empty, the comments box is skipped. Subclasses must chain a
      %  call to this.
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
      
      if ~isempty(obj.LogEntry)
        c = uicontextmenu(ancestor(obj.Root, 'Figure'));
        uimenu(c, 'Label', 'Hide comments',...
          'MenuSelectedFcn', @obj.toggleCommentsBox);
        bui.label('Comments', obj.MainVBox, 'UIContextMenu', c);
        
        obj.CommentsBox = uicontrol('Parent', obj.MainVBox,...
          'Style', 'edit',... %text editor
          'String', obj.LogEntry.comments,...
          'Max', 2,... %make it multiline
          'HorizontalAlignment', 'left',... %make it align to the left
          'BackgroundColor', [1 1 1],...%background to white
          'UIContextMenu', c,...
          'Callback', @obj.commentsChanged); %update comment in log
        h = [15 80];
      else
        h = [];
      end
      
      buttonpanel = uiextras.HBox('Parent', obj.MainVBox);
      %info grid size will be updated as fields are added, the other
      %default panels get reasonable space, and the custom panel gets
      %whatever's left
      obj.MainVBox.Sizes = [0 -1 h 24];
      
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

