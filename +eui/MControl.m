classdef MControl < handle
  %EUI.MCONTROL Master Control
  %   Whatever it is, take control of your experiments from this GUI
  %   This code is a bit messy and undocumented. 
  %   TODO: 
  %     - improve it.
  %     - ensure all Parent objects specified explicitly (See GUI Layout
  %     Toolbox 2.3.1/layoutdoc/Getting_Started2.html)
  %   See also MC.
  %
  % Part of Rigbox
  
  % 2013-03 CB created
  % 2017-02 MW Updated to work with new GUILayoutToolbox
  % 2017-02 MW Changed expFactory to allow loading of last params for the
  % specific expDef that was selected
    
  properties (SetAccess = private)
    LogSubject %subject selector control
    NewExpSubject
    NewExpType
    WeighingScale
    Log %log control
    RemoteRigs
    TabPanel
    LastExpPanel
  end
  
  properties (Access = private)
    LoggingDisplay %control for showing log output
    ParamEditor
    ParamPanel
    BeginExpButton
    NewExpFactory
    RootContainer
    Parameters
    WeightAxes
    WeightReadingPlot
    NewExpParamProfile
    LogTabs
    ExpTabs
    ActiveExpsGrid
    Listeners
    %handles to pre (i=1) and post (i=2) experiment delay edit text controls
    PrePostExpDelayEdits
    RecordWeightButton
    ParamProfileLabel
    RefreshTimer
  end
  
  events
    Refresh
  end
  
  methods
    function obj = MControl(parent) % Parent here is the MC window
      obj.Parameters = exp.Parameters;
      obj.NewExpFactory = struct(...
        'label',...
        {'ChoiceWorld' '<custom...>'},...
        'matchTypes', {{'ChoiceWorld' 'SingleTargetChoiceWorld'},...
        {'custom' ''}},...
        'defaultParamsFun',...
        {@exp.choiceWorldParams,...
        @exp.inferParameters}); % in signals/ this function returns a struct of parameters
      obj.buildUI(parent);
      set(obj.RootContainer, 'Visible', 'on');
      %obj.LogSubject.Selected = '';
      obj.NewExpSubject.Selected = 'default'; % Make default selected subject 'default'
      %obj.expTypeChanged();
      rig = hw.devices([], false);
      obj.RefreshTimer = timer('Period', 0.1, 'ExecutionMode', 'fixedSpacing',...
        'TimerFcn', @(~,~)notify(obj, 'Refresh'));
      start(obj.RefreshTimer);
      try
        if isfield(rig, 'scale') && ~isempty(rig.scale)
          obj.WeighingScale = fieldOrDefault(rig, 'scale');
          init(obj.WeighingScale);
          obj.Listeners = [obj.Listeners,...
            {event.listener(obj.WeighingScale, 'NewReading', @obj.newScalesReading)}];
        end
      catch ex
        obj.log('Warning: could not connect to weighing scales');
      end      
      
    end
    
    function delete(obj)
      disp('MControl destructor called');
      obj.cleanup();
      if obj.RootContainer.isvalid
        delete(obj.RootContainer);
      end
    end
%   end
%   
%   methods (Access = protected) % test by NS - remove protection of these
%   methods, so that alyxPanel can access them... not sure what is the
%   tradeoff/danger
    function newScalesReading(obj, ~, ~)
      if obj.TabPanel.SelectedChild == 1 && obj.LogTabs.SelectedChild == 2
        obj.plotWeightReading(); %refresh weighing scale reading
      end
    end
    
    function expSubjectChanged(obj)
      obj.expTypeChanged();
    end
    
    function expTypeChanged(obj)
      if strcmp(obj.NewExpType.Selected, '<custom...>')
        defdir = fullfile(pick(dat.paths, 'expDefinitions'));
        [mfile, fpath] = uigetfile(...
          '*.m', 'Select the experiment definition function', defdir);
        if ~mfile
          obj.NewExpType.SelectedIdx = 1; % If no file selected, default back to ChoiceWorld
          return
        end
        custidx = strcmp({obj.NewExpFactory.label},'<custom...>');
        obj.NewExpFactory(custidx).defaultParamsFun = ...
          @()exp.inferParameters(fullfile(fpath, mfile)); % change default paramters function handle to infer params for this specific expDef
        obj.NewExpFactory(custidx).matchTypes{2} = fullfile(fpath, mfile); % add specific expDef to NewExpFactory
      end
      stdProfiles = {'<last for subject>'; '<defaults>'};
      
      if strcmp(obj.NewExpType.Selected, '<custom...>')
        type = 'custom';
      else
        type = obj.NewExpType.Selected;
      end
      
      savedProfiles = fieldnames(dat.loadParamProfiles(type));
      obj.NewExpParamProfile.Option = [stdProfiles; savedProfiles];
      str = iff(strcmp('default', obj.NewExpSubject.Selected) &...
          ~strcmp(obj.NewExpType.Selected, '<custom...>'),...
          '<defaults>','<last for subject>');
      obj.loadParamProfile(str);
    end
    
    function delParamProfile(obj) % Called when 'Delete...' button is pressed next to saved sets
      profile = obj.NewExpParamProfile.Selected; % Get param profile that was selected from the dropdown?
      assert(profile(1) ~= '<', 'Special case profile %s cannot be deleted', profile); % If '<last for subject>' or '<defaults>' is selected give error
      q = sprintf('Are you sure you want to delete parameters profile ''%s''', profile);
      doDelete = strcmp(questdlg(q, 'Delete', 'Yes', 'No', 'No'),  'Yes'); % Find out whether they confirmed delete
      if doDelete % They pressed 'Yes'
        if strcmp(obj.NewExpType.Selected, '<custom...>') % Was it a signals parameter?
          type = 'custom';
        else
          type = obj.NewExpType.Selected;
        end
        dat.delParamProfile(type, profile); 
        %remove the profile from the control options
        profiles = obj.NewExpParamProfile.Option; % Get parameter profile
        obj.NewExpParamProfile.Option = profiles(~strcmp(profiles, profile)); % Set new list without deleted profile
        %log the parameters as being deleted
        obj.log('Deleted parameters as ''%s''', profile);
      end
    end
    
    function saveParamProfile(obj) % Called by 'Save...' button press, save a new parameter profile
      selProfile = obj.NewExpParamProfile.Selected; % Find which set is currently selected
      if selProfile(1) ~= '<' % This statement is for autofilling the save as input dialog
        %default value is currently selected profile name
        def = selProfile;
      else
        %begins with left bracket: a special case profile is selected
        %no default value
        def = '';
      end
      ipt = inputdlg('Enter a name for the parameters profile', 'Name', 1, {def});
      if isempty(ipt)
        return
      else
        name = ipt{1}; % Get the name they entered into the dialog
      end
      doSave = true;
      validName = matlab.lang.makeValidName(name); % 2017-02-13 MW changed from genvarname for future compatibility
      if ~strcmp(name, validName) % If the name they entered is non-alphanumeric...
        q = sprintf('''%s'' is not valid (names must be alphanumeric with no spaces)\n', name);
        q = [q sprintf('Do you want to use ''%s'' instead?', validName)];
        doSave = strcmp(questdlg(q, 'Name', 'Yes', 'No', 'No'),  'Yes'); % Do they still want to save with suggested name?
      end
      if doSave % Going ahead with save
        if strcmp(obj.NewExpType.Selected, '<custom...>') % Is parameter set for signals?
          type = 'custom';
        else
          type = obj.NewExpType.Selected; % Which world is this set for?
        end
        dat.saveParamProfile(type, validName, obj.Parameters.Struct); % Save
        %add the profile to the control options
        profiles = obj.NewExpParamProfile.Option;
        if ~any(strcmp(obj.NewExpParamProfile.Option, validName))
          obj.NewExpParamProfile.Option = [profiles; validName];
        end
        %set label for loaded profile
        set(obj.ParamProfileLabel, 'String', validName, 'ForegroundColor', [0 0 0]);
        obj.log('Saved parameters as ''%s''', validName);
      end
    end
    
    function loadParamProfile(obj, profile)
      if ~isempty(obj.ParamEditor)
        %delete existing parameters control
        delete(obj.ParamEditor);
        set(obj.ParamProfileLabel, 'String', 'loading...', 'ForegroundColor', [1 0 0]); % Red 'Loading...' while new set loads
      end
      
      factory = obj.NewExpFactory; % Find which 'world' we are in
      typeName = obj.NewExpType.Selected; 
      if strcmp(typeName, '<custom...>')
        typeNameFinal = 'custom';
      else
        typeNameFinal = typeName;
      end
      matchTypes = factory(strcmp({factory.label}, typeName)).matchTypes();
      subject = obj.NewExpSubject.Selected; % Find which subject is selected
      label = 'none';
      switch lower(profile)
        case '<defaults>'
          %           if strcmp(obj.NewExpType.Selected, '<custom...>')
          %             paramStruct = factory(strcmp({factory.label}, typeName)).defaultParamsFun();
          %             label = 'inferred';
          %           else
          paramStruct = factory(strcmp({factory.label}, typeName)).defaultParamsFun();
          label = 'defaults';
          %           end
        case '<last for subject>'
          %% find the most recent experiment with parameters of selected type
          % list of all subject's experiments, with most recent first
          refs = flipud(dat.listExps(subject));
          % function takes parameters and returns true if of selected type
          if any(strcmp(matchTypes, 'custom')) % If custom, find last parameter set for specific expDef
            matching = @(pars) iff(isfield(pars, 'defFunction'),...
                @()any(strcmpi(pick(pars, 'defFunction'), matchTypes)), false);
          else
            matching = @(pars) any(strcmp(pick(pars, 'type', 'def', ''), matchTypes));
          end
          % create a sequence of the parameters of each experiment
          paramsSeq = sequence(refs, @dat.expParams);
          % get the first (most recent) parameters whose type matches
          [paramStruct, ref] = paramsSeq.filter(matching).first;
          if ~isempty(paramStruct) % found one
            paramStruct.type = typeNameFinal; % override type name with preferred
            label = sprintf('from last experiment of %s (%s)', subject, ref);
          end
        otherwise
          label = profile;
          saved = dat.loadParamProfiles(typeNameFinal);
          paramStruct = saved.(profile);
          paramStruct.type = typeNameFinal; % override type name with preferred
      end
      set(obj.ParamProfileLabel, 'String', label, 'ForegroundColor', [0 0 0]);
      if isfield(paramStruct, 'services')
        %remove the services field since this application will specifically
        %set that field
        paramStruct = rmfield(paramStruct, 'services');
      end
      obj.Parameters.Struct = paramStruct;
      if ~isempty(paramStruct) % Now parameters are loaded, pass to ParamEditor for display, etc.
        obj.ParamEditor = eui.ParamEditor(obj.Parameters, obj.ParamPanel); % Build parameter list in Global panel by calling eui.ParamEditor
        obj.ParamEditor.addlistener('Changed', @(src,~) obj.paramChanged);
      end
    end
    
    function paramChanged(obj)
      s = get(obj.ParamProfileLabel, 'String');
      if ~strEndsWith(s, '[EDITED]')
        set(obj.ParamProfileLabel, 'String', [s ' ' '[EDITED]'], 'ForegroundColor', [1 0 0]);
      end
    end
    
    function l = listenToRig(obj, rig)
      l = [event.listener(rig, 'Connected', @obj.rigConnected)...
        event.listener(rig, 'Disconnected', @obj.rigDisconnected)...
        event.listener(rig, 'ExpStopped', @obj.rigExpStopped)...
        event.listener(rig, 'ExpStarted', @obj.rigExpStarted)];
    end
    
    function rigExpStarted(obj, rig, evt) % Announce that the experiment has started in the log box
      obj.log('''%s'' on ''%s'' started', evt.Ref, rig.Name);
    end
    
    function rigExpStopped(obj, rig, evt) % Announce that the experiment has stopped in the log box
      obj.log('''%s'' on ''%s'' stopped', evt.Ref, rig.Name);
      if rig == obj.RemoteRigs.Selected
        set(obj.BeginExpButton, 'Enable', 'on'); % Re-enable 'Start' button so a new experiment can be started on that rig
      end
    end
          
    function rigConnected(obj, rig, evt) % If rig is connected...
      obj.log('Connected to ''%s''', rig.Name); % Say so in the log box
      if rig == obj.RemoteRigs.Selected
        set(obj.BeginExpButton, 'Enable', 'on'); % Enable 'Start' button
        set(obj.PrePostExpDelayEdits, 'Enable', 'on'); % % Enable 'Delays' boxes
      end
    end
    
    function rigDisconnected(obj, rig, evt) % If rig is disconnected...
      obj.log('Disconnected from ''%s''', rig.Name); % Say so in the log box
      if rig == obj.RemoteRigs.Selected 
        set(obj.BeginExpButton, 'enable', 'off'); % Grey out 'Start' button
        set(obj.PrePostExpDelayEdits, 'Enable', 'off'); % Grey out 'Delays' boxes
      end
    end
    
    function log(obj, varargin)
      message = sprintf(varargin{:});
      timestamp = datestr(now, 'dd-mm-yyyy HH:MM:SS');
      str = sprintf('[%s] %s', timestamp, message);
      current = get(obj.LoggingDisplay, 'String');
      set(obj.LoggingDisplay, 'String', [current; str], 'Value', numel(current) + 1);
    end
    
    function remoteRigChanged(obj)
      set([obj.BeginExpButton obj.PrePostExpDelayEdits], 'enable', 'off');
      rig = obj.RemoteRigs.Selected;
      if ~isempty(rig) && strcmp(rig.Status, 'disconnected')
        %attempt to connect to rig
        try
          rig.connect(); % srv.StimulusControl/connect
        catch ex
          errmsg = ex.message;
          croplen = 200;
          if length(errmsg) > croplen
            %crop overly long messages
            errmsg = [errmsg(1:croplen) '...'];
          end
          obj.log('Could not connect to ''%s'' (%s)', rig.Name, errmsg);
        end
      elseif strcmp(rig.Status, 'idle')
        set([obj.BeginExpButton obj.PrePostExpDelayEdits], 'enable', 'on');
      end
      set(obj.PrePostExpDelayEdits(1), 'String', num2str(rig.ExpPreDelay));
      set(obj.PrePostExpDelayEdits(2), 'String', num2str(rig.ExpPostDelay));
    end
    
    function beginExp(obj)
      set(obj.BeginExpButton, 'enable', 'off'); % Grey out 'Start' button
      rig = obj.RemoteRigs.Selected; % Find which rig is selected
      obj.Parameters.set('services', rig.Services(:),...
        'List of experiment services to use during the experiment');
      expRef = dat.newExp(obj.NewExpSubject.Selected, now, obj.Parameters.Struct); % Create new experiment reference
      panel = eui.ExpPanel.live(obj.ActiveExpsGrid, expRef, rig, obj.Parameters.Struct);
      obj.LastExpPanel = panel;
      panel.Listeners = [panel.Listeners
        event.listener(obj, 'Refresh', @(~,~)panel.update())];
      obj.ExpTabs.SelectedChild = 2; % switch to the active exps tab
      rig.startExperiment(expRef); % Tell rig to start experiment
      %update the parameter set label to indicate used for this experiment
      subject = dat.parseExpRef(expRef);
      parLabel = sprintf('from last experiment of %s (%s)', subject, expRef);
      set(obj.ParamProfileLabel, 'String', parLabel, 'ForegroundColor', [0 0 0]);
    end
    
    function updateWeightPlot(obj)
      entries = obj.Log.entriesByType('weight-grams');
      datenums = floor([entries.date]);
      obj.WeightAxes.clear();
      if numel(datenums) > 0
        obj.WeightAxes.plot(datenums, [entries.value], '-o');
        dateticks = min(datenums):floor(now);
        set(obj.WeightAxes.Handle, 'XTick', dateticks);
        obj.WeightAxes.XTickLabel = datestr(dateticks, 'dd-mm');
        obj.WeightAxes.yLabel('Weight (g)');
        xl = [min(datenums) floor(now)];
        if diff(xl) <= 0
          xl(1) = xl(2) - 0.5;
          xl(2) = xl(2) + 0.5;
        end
        obj.WeightAxes.XLim = xl;
        rotateticklabel(obj.WeightAxes.Handle, 45);
      end
    end
    
    function plotWeightReading(obj)
      %plots the current reading if any from the scales
      if ishandle(obj.WeightReadingPlot)
        set(obj.RecordWeightButton, 'Enable', 'off', 'String', 'Record');
        delete(obj.WeightReadingPlot);
        obj.WeightReadingPlot = [];
      end
      if ~isempty(obj.WeighingScale)
        %scales are attached and initialised so take a reading
        g = obj.WeighingScale.readGrams;
        MinSignificantWeight = 5; %grams
        if g >= MinSignificantWeight
          obj.WeightReadingPlot = obj.WeightAxes.scatter(floor(now), g, 20^2, 'p', 'filled');
          set(obj.RecordWeightButton, 'Enable', 'on', 'String', sprintf('Record %.1fg', g));
        end
      end
    end
    
    function cleanup(obj)
      % delete the rig listeners
      cellfun(@delete, obj.Listeners);
      obj.Listeners = {};
      if ~isempty(obj.RefreshTimer)
        stop(obj.RefreshTimer);
        delete(obj.RefreshTimer);
        obj.RefreshTimer = [];
      end
      %close connectiong to weighing scales
      if ~isempty(obj.WeighingScale)
        obj.WeighingScale.cleanup();
      end
      % disconnect all connected rigs
      arrayfun(@(r) r.disconnect(), obj.RemoteRigs.Option);
    end
    
    function logSubjectChanged(obj)
      obj.Log.setSubject(obj.LogSubject.Selected);
      obj.updateWeightPlot();
    end
    
    function recordWeight(obj)
      subject = obj.LogSubject.Selected;
      grams = get(obj.WeightReadingPlot, 'YData');
      dat.addLogEntry(subject, now, 'weight-grams', grams, '');            
      
      obj.log('Logged weight of %.1fg for ''%s''', grams, subject);
                  
      %refresh log entries so new weight reading is plotted
      obj.Log.setSubject(obj.LogSubject.Selected);
      obj.updateWeightPlot();
    end
    
    function buildUI(obj, parent) % Parent here is the MC window (figure)
      obj.RootContainer = uiextras.VBox('Parent', parent,...
        'DeleteFcn', @(~,~) obj.cleanup(), 'Visible', 'on');
      %       drawnow;
      
      % tabs for doing different things with the selected subject
      obj.TabPanel = uiextras.TabPanel('Parent', obj.RootContainer, 'Padding', 5);
      obj.LoggingDisplay = uicontrol('Parent', obj.RootContainer, 'Style', 'listbox',...
        'Enable', 'inactive', 'String', {}); % This is the messege area at the bottom of mc
      obj.RootContainer.Sizes = [-1 72]; % TabPanel variable size with wieght 1; LoggingDisplay fixed height of 72px
      
      %% Log tab
      logbox = uiextras.VBox('Parent', obj.TabPanel, 'Padding', 5); % The entire log tab
      
      hbox = uiextras.HBox('Parent', logbox, 'Padding', 5); % container for 'Subject' text and dropdown box
      bui.label('Subject', hbox); % 'Subject' text next to dropdown box, Child of hbox
      obj.LogSubject = bui.Selector(hbox, dat.listSubjects); % Subject dropdown box, Child of hbox
      hbox.Sizes = [50 100]; % resize label and dropdown to be 50px and 100px respectively
      obj.LogTabs = uiextras.TabPanel('Parent', logbox, 'Padding', 5); % Container for 'Entries' and 'Weights' tab in log
      obj.Log = eui.Log(obj.LogTabs); % Entries window, all delt with by +eui/Log.m
      obj.LogSubject.addlistener('SelectionChanged',...
        @(~, ~) obj.logSubjectChanged()); % Listener for Subject dropdown, sets obj.Log.setSubject to obj.LogSubject.Selected
      logbox.Sizes = [34 -1];
      %weights
      %% weight tab
      weightBox = uiextras.VBox('Parent', obj.LogTabs, 'Padding', 5);
      obj.WeightAxes = bui.Axes(weightBox); % Mouse weight plot axes
      obj.WeightAxes.NextPlot = 'add';
      hbox = uiextras.HBox('Parent', weightBox, 'Padding', 5); % container below weight plot for buttons
      uiextras.Empty('Parent', hbox); % empty space for padding (to right-align buttons)
      uicontrol('Parent', hbox, 'Style', 'pushbutton',... % Tare button
        'String', 'Tare scales',...
        'TooltipString', 'Tare the scales',...
        'Callback', @(~,~) obj.WeighingScale.tare(),...
        'Enable', 'on');
      obj.RecordWeightButton = uicontrol('Parent', hbox, 'Style', 'pushbutton',... % Record button
        'String', 'Record',...
        'TooltipString', 'Record the current weight reading (star symbol)',...
        'Callback', @(~,~) obj.recordWeight(),...
        'Enable', 'off');
      hbox.Sizes = [-1 80 100]; % resize buttons to be 80 and 100px respectively
      weightBox.Sizes = [-1 36]; % make hbox size 36px high
      obj.LogTabs.TabNames = {'Entries' 'Weight'}; % Label tabs
      
      %% Experiment tab
      obj.ExpTabs = uiextras.TabPanel('Parent', obj.TabPanel);
      
      % a box on the first tab for new experiments
      newExpBox = uiextras.VBox('Parent', obj.ExpTabs, 'Padding', 5);
      
      headerBox = uix.HBox('Parent', newExpBox); % new container to allow alyx to go to the right of the rest of the header
      leftSideBox = uix.VBox('Parent', headerBox);      
      
      % controls for subject, exp type
      topgrid = uiextras.Grid('Parent', leftSideBox); % grid for containing everything within the tab
      subjectLabel = bui.label('Subject', topgrid); % 'Subject' label
      bui.label('Type', topgrid); % 'Type' label
      obj.NewExpSubject = bui.Selector(topgrid, dat.listSubjects); % Subject dropdown box
      set(subjectLabel, 'FontSize', 12); % Make 'Subject' label larger
      set(obj.NewExpSubject.UIControl, 'FontSize', 12); % Make dropdown box text larger
      obj.NewExpSubject.addlistener('SelectionChanged', @(~,~) obj.expSubjectChanged()); % Add listener for subject selection
      obj.NewExpType = bui.Selector(topgrid, {obj.NewExpFactory.label}); % Make experiment type dropdown box
      obj.NewExpType.addlistener('SelectionChanged', @(~,~) obj.expTypeChanged()); % Add listener for experiment type change
      
      topgrid.ColumnSizes = [80, 200]; % Set size of topgrig (containing Subject and Type dropdowns)
      topgrid.RowSizes = [34, 24]; % " 
      
      %configure new exp control box
      controlbox = uiextras.HBox('Parent', leftSideBox);
      bui.label('Rig', controlbox); % 'Rig' label
      obj.RemoteRigs = bui.Selector(controlbox, srv.stimulusControllers); % Rig dropdown box
      obj.RemoteRigs.addlistener('SelectionChanged', @(src,~) obj.remoteRigChanged); % Add listener for rig selection change
      obj.Listeners = arrayfun(@obj.listenToRig, obj.RemoteRigs.Option, 'Uni', false); % Add listeners for each rig (keep track of whether they're connected, running, etc.)
      bui.label('Delays: Pre', controlbox); % Add 'Delyas' label next to rig dropdown
      pre = uicontrol('Parent', controlbox,... % Add 'Pre' textbox
        'Style', 'edit',...
        'BackgroundColor', [1 1 1],...
        'HorizontalAlignment', 'left',...
        'Enable', 'off',...
        'Callback', @(src, evt) put(obj.RemoteRigs.Selected,... % SetField 'ExpPreDelay' in obj.RemoteRigs.Selected to what ever was enetered
        'ExpPreDelay', str2double(get(src, 'String'))));
      bui.label('Post', controlbox); % Add 'Post' label
      post = uicontrol('Parent', controlbox,... % Add 'Post' textbox
        'Style', 'edit',...
        'BackgroundColor', [1 1 1],...
        'HorizontalAlignment', 'left',...
        'Enable', 'off',...
        'Callback', @(src, evt) put(obj.RemoteRigs.Selected,...  % SetField 'ExpPostDelay' in obj.RemoteRigs.Selected to what ever was enetered
        'ExpPostDelay', str2double(get(src, 'String'))));
      obj.PrePostExpDelayEdits = [pre post]; % Store Pre and Post values in obj
      obj.BeginExpButton = uicontrol('Parent', controlbox, 'Style', 'pushbutton',... % Add 'Start' button
        'String', 'Start',...
        'TooltipString', 'Start an experiment using the parameters',...
        'Callback', @(~,~) obj.beginExp(),... % When pressed run 'beginExp' function
        'Enable', 'off');
      controlbox.Sizes = [80 200 60 50 30 50 80]; % Resize the Rig and Delay boxes
      
      leftSideBox.Heights = [55 22];
            
      % a titled panel for the parameters editor
      param = uiextras.Panel('Parent', newExpBox, 'Title', 'Parameters', 'Padding', 5);
      obj.ParamPanel = uiextras.VBox('Parent', param, 'Padding', 5); % Make verticle container for parameters
      hbox = uiextras.HBox('Parent', obj.ParamPanel); % Make container for 'sets' dropdown boxes
      bui.label('Current set:', hbox); % Add 'Current set' label
      obj.ParamProfileLabel = bui.label('none', hbox, 'FontWeight', 'bold'); % Current parameter label
      hbox.Sizes = [60 400]; % Set size of Current set labels
      hbox = uiextras.HBox('Parent', obj.ParamPanel, 'Spacing', 2); % Make new HBox for saved sets
      bui.label('Saved sets:', hbox);  % Add 'Saved sets' label
      obj.NewExpParamProfile = bui.Selector(hbox, {'none'}); % Make parameter sets dropdown box with default 'none' entry
      uicontrol('Parent', hbox,... % Make 'Load' button
        'Style', 'pushbutton',...
        'String', 'Load',...
        'Callback', @(~,~) obj.loadParamProfile(obj.NewExpParamProfile.Selected)); % Pass selected param profile to loadParamProfile() when pressed
      uicontrol('Parent', hbox,... % Make 'Save' button
        'Style', 'pushbutton',...
        'String', 'Save...',...
        'Callback', @(~,~) obj.saveParamProfile(),... % When pressed run saveParamProfile() function
        'Enable', 'on');
      uicontrol('Parent', hbox,... % Make 'Delete' button
        'Style', 'pushbutton',...
        'String', 'Delete...',...
        'Callback', @(~,~) obj.delParamProfile(),...% When pressed run delParamProfile() function
        'Enable', 'on');
      hbox.Sizes = [60 200 60 60 60]; % Set horizontal sizes for Sets dropdowns and buttons
      obj.ParamPanel.Sizes = [22 22]; % Set vertical size by changing obj.ParamPanel VBox size
      
      newExpBox.Sizes = [58+22 -1]; % Set fixed pixel sizes for parameters panel, -1 = fill rest of space with 'Global' and 'Conditional' Panels
      
      %a box on the second tab for running experiments
      runningExpBox = uiextras.VBox('Parent', obj.ExpTabs, 'Padding', 5);
      obj.ActiveExpsGrid = uiextras.Grid('Parent', runningExpBox, 'Spacing', 5);
      
      % setup the tab names/sizes
      obj.TabPanel.TabSize = 80;
      obj.TabPanel.TabNames = {'Log' 'Experiments'};
      obj.TabPanel.SelectedChild = 2;
      obj.ExpTabs.TabNames = {'New' 'Current'};
      obj.ExpTabs.SelectedChild = 1;
    end
 end
end

