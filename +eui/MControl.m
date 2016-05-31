classdef MControl < handle
  %EUI.MCONTROL (Mission/Mouse/Matteo??) Control
  %   Whatever it is, take control of your experiments from this GUI
  %   This code is a bit messy and undocumented. TODO: improve it.
  %   See also MC.
  %
  % Part of Rigbox
  
  % 2013-03 CB created
  
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
    function obj = MControl(parent)
      obj.Parameters = exp.Parameters;
      obj.NewExpFactory = struct(...
        'label',...
        {'ChoiceWorld' 'DiscWorld' 'GaborMapping' ...
        'BarMapping' 'SurroundChoiceWorld' '<custom...>'},...
        'matchTypes', {{'ChoiceWorld' 'SingleTargetChoiceWorld'},...
        {'DiscWorld'},...
        {'GaborMapping'},...
        {'BarMapping'},...
        {'SurroundChoiceWorld'},...
        {'custom'}},...
        'defaultParamsFun',...
        {@exp.choiceWorldParams, @exp.discWorldParams,...
        @exp.gaborMappingParams,...
        @exp.barMappingParams, @()exp.choiceWorldParams('Surround'),...
        @exp.inferParameters});
      obj.buildUI(parent);
      obj.NewExpSubject.Selected = 'test';
      set(obj.RootContainer, 'Visible', 'on');
      %obj.LogSubject.Selected = '';
      %obj.NewExpSubject.Selected = '';
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
  end
  
  methods (Access = protected)
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
        defdir = fullfile(pick(dat.paths, 'rigbox'), 'ExpDefinitions');
        [mfile, fpath] = uigetfile(...
          '*.m', 'Select the experiment definition function', defdir);
        if ~mfile
          obj.NewExpType.SelectedIdx = 1;
          return
        end
        custidx = strcmp({obj.NewExpFactory.label},'<custom...>');
        obj.NewExpFactory(custidx).defaultParamsFun = ...
          @()exp.inferParameters(fullfile(fpath, mfile));
      end
      stdProfiles = {'<last for subject>'; '<defaults>'};
      
      if strcmp(obj.NewExpType.Selected, '<custom...>')
        type = 'custom';
      else
        type = obj.NewExpType.Selected;
      end
      
      savedProfiles = fieldnames(dat.loadParamProfiles(type));
      obj.NewExpParamProfile.Option = [stdProfiles; savedProfiles];
      obj.loadParamProfile('<last for subject>');
    end
    
    function delParamProfile(obj)

      profile = obj.NewExpParamProfile.Selected;
      assert(profile(1) ~= '<', 'Special case profile %s cannot be deleted', profile);
      q = sprintf('Are you sure you want to delete parameters profile ''%s''', profile);
      doDelete = strcmp(questdlg(q, 'Delete', 'Yes', 'No', 'No'),  'Yes');
      if doDelete
        if strcmp(obj.NewExpType.Selected, '<custom...>')
          type = 'custom';
        else
          type = obj.NewExpType.Selected;
        end
        dat.delParamProfile(type, profile);
        %remove the profile from the control options
        profiles = obj.NewExpParamProfile.Option;
        obj.NewExpParamProfile.Option = profiles(~strcmp(profiles, profile));
        %log the parameters as being deleted
        obj.log('Deleted parameters as ''%s''', profile);
      end
    end
    
    function saveParamProfile(obj)
      selProfile = obj.NewExpParamProfile.Selected;
      if selProfile(1) ~= '<'
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
        name = ipt{1};
      end
      doSave = true;
      validName = genvarname(name);
      if ~strcmp(name, validName)
        q = sprintf('''%s'' is not valid (names must be alphanumeric with no spaces)\n', name);
        q = [q sprintf('Do you want to use ''%s'' instead?', validName)];
        doSave = strcmp(questdlg(q, 'Name', 'Yes', 'No', 'No'),  'Yes');
      end
      if doSave
        if strcmp(obj.NewExpType.Selected, '<custom...>')
          type = 'custom';
        else
          type = obj.NewExpType.Selected;
        end
        dat.saveParamProfile(type, validName, obj.Parameters.Struct);
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
        set(obj.ParamProfileLabel, 'String', 'loading...', 'ForegroundColor', [1 0 0]);
      end
      
      factory = obj.NewExpFactory;
      typeName = obj.NewExpType.Selected;
      if strcmp(typeName, '<custom...>')
        typeNameFinal = 'custom';
      else
        typeNameFinal = typeName;
      end
      matchTypes = factory(strcmp({factory.label}, typeName)).matchTypes();
      subject = obj.NewExpSubject.Selected;
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
          matching = @(pars) any(strcmp(pick(pars, 'type', 'def', ''), matchTypes));
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
      if ~isempty(paramStruct)
        obj.ParamEditor = eui.ParamEditor(obj.Parameters, obj.ParamPanel);
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
    
    function rigExpStarted(obj, rig, evt)
      obj.log('''%s'' on ''%s'' started', evt.Ref, rig.Name);
    end
    
    function rigExpStopped(obj, rig, evt)
      obj.log('''%s'' on ''%s'' stopped', evt.Ref, rig.Name);
      if rig == obj.RemoteRigs.Selected
        set(obj.BeginExpButton, 'Enable', 'on');
      end
    end
    
    function rigConnected(obj, rig, evt)
      obj.log('Connected to ''%s''', rig.Name);
      if rig == obj.RemoteRigs.Selected
        set(obj.BeginExpButton, 'Enable', 'on');
        set(obj.PrePostExpDelayEdits, 'Enable', 'on');
      end
    end
    
    function rigDisconnected(obj, rig, evt)
      obj.log('Disconnected from ''%s''', rig.Name);
      if rig == obj.RemoteRigs.Selected
        set(obj.BeginExpButton, 'enable', 'off');
        set(obj.PrePostExpDelayEdits, 'Enable', 'off');
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
          rig.connect();
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
      set(obj.BeginExpButton, 'enable', 'off');
      rig = obj.RemoteRigs.Selected;
      obj.Parameters.set('services', rig.Services(:),...
        'List of experiment services to use during the experiment');
      expRef = dat.newExp(obj.NewExpSubject.Selected, now, obj.Parameters.Struct);
      panel = eui.ExpPanel.live(obj.ActiveExpsGrid, expRef, rig, obj.Parameters.Struct);
      obj.LastExpPanel = panel;
      panel.Listeners = [panel.Listeners
        event.listener(obj, 'Refresh', @(~,~)panel.update())];
      obj.ExpTabs.SelectedChild = 2; % switch to the active exps tab
      rig.startExperiment(expRef);
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
    
    function buildUI(obj, parent)
      obj.RootContainer = uiextras.VBox('Parent', parent,...
        'DeleteFcn', @(~,~) obj.cleanup(), 'Visible', 'on');
      %       drawnow;
      
      % tabs for doing different things with the selected subject
      obj.TabPanel = uiextras.TabPanel('Parent', obj.RootContainer, 'Padding', 5);
      obj.LoggingDisplay = uicontrol('Parent', obj.RootContainer, 'Style', 'listbox',...
        'Enable', 'inactive', 'String', {});
      obj.RootContainer.Sizes = [-1 72];
      
      %% Log tab
      logbox = uiextras.VBox('Parent', obj.TabPanel, 'Padding', 5);
      %entries
      
      hbox = uiextras.HBox('Parent', logbox, 'Padding', 5);
      bui.label('Subject', hbox);
      obj.LogSubject = bui.Selector(hbox, dat.listSubjects);
      hbox.Sizes = [50 100];
      obj.LogTabs = uiextras.TabPanel('Parent', logbox, 'Padding', 5);
      obj.Log = eui.Log(obj.LogTabs);
      obj.LogSubject.addlistener('SelectionChanged',...
        @(~, ~) obj.logSubjectChanged());
      logbox.Sizes = [34 -1];
      %weights
      %% weight tab
      weightBox = uiextras.VBox('Parent', obj.LogTabs, 'Padding', 5);
      obj.WeightAxes = bui.Axes(weightBox);
      obj.WeightAxes.NextPlot = 'add';
      hbox = uiextras.HBox('Parent', weightBox, 'Padding', 5);
      uiextras.Empty('Parent', hbox);
      uicontrol('Parent', hbox, 'Style', 'pushbutton',...
        'String', 'Tare scales',...
        'TooltipString', 'Tare the scales',...
        'Callback', @(~,~) obj.WeighingScale.tare(),...
        'Enable', 'on');
      obj.RecordWeightButton = uicontrol('Parent', hbox, 'Style', 'pushbutton',...
        'String', 'Record',...
        'TooltipString', 'Record the current weight reading (star symbol)',...
        'Callback', @(~,~) obj.recordWeight(),...
        'Enable', 'off');
      hbox.Sizes = [-1 80 100];
      weightBox.Sizes = [-1 36];
      obj.LogTabs.TabNames = {'Entries' 'Weight'};
      
      %% Experiment tab
      obj.ExpTabs = uiextras.TabPanel('Parent', obj.TabPanel);
      
      % a box on the first tab for new experiments
      newExpBox = uiextras.VBox('Parent', obj.ExpTabs, 'Padding', 5);
      
      % controls for subject, exp type
      topgrid = uiextras.Grid('Parent', newExpBox);
      subjectLabel = bui.label('Subject', topgrid);
      bui.label('Type', topgrid);
      obj.NewExpSubject = bui.Selector(topgrid, dat.listSubjects);
      set(subjectLabel, 'FontSize', 12);
      set(obj.NewExpSubject.UIControl, 'FontSize', 12);
      obj.NewExpSubject.addlistener('SelectionChanged', @(~,~) obj.expSubjectChanged());
      obj.NewExpType = bui.Selector(topgrid, {obj.NewExpFactory.label});
      obj.NewExpType.addlistener('SelectionChanged', @(~,~) obj.expTypeChanged());
      
      topgrid.ColumnSizes = [80, 200];
      topgrid.RowSizes = [34, 24];
      
      %configure new exp control box
      controlbox = uiextras.HBox('Parent', newExpBox);
      bui.label('Rig', controlbox);
      obj.RemoteRigs = bui.Selector(controlbox, srv.stimulusControllers);
      obj.RemoteRigs.addlistener('SelectionChanged', @(src,~) obj.remoteRigChanged);
      obj.Listeners = arrayfun(@obj.listenToRig, obj.RemoteRigs.Option, 'Uni', false);
      bui.label('Delays: Pre', controlbox);
      pre = uicontrol('Parent', controlbox,...
        'Style', 'edit',...
        'BackgroundColor', [1 1 1],...
        'HorizontalAlignment', 'left',...
        'Enable', 'off',...
        'Callback', @(src, evt) put(obj.RemoteRigs.Selected,...
        'ExpPreDelay', str2double(get(src, 'String'))));
      bui.label('Post', controlbox);
      post = uicontrol('Parent', controlbox,...
        'Style', 'edit',...
        'BackgroundColor', [1 1 1],...
        'HorizontalAlignment', 'left',...
        'Enable', 'off',...
        'Callback', @(src, evt) put(obj.RemoteRigs.Selected,...
        'ExpPostDelay', str2double(get(src, 'String'))));
      obj.PrePostExpDelayEdits = [pre post];
      obj.BeginExpButton = uicontrol('Parent', controlbox, 'Style', 'pushbutton',...
        'String', 'Start',...
        'TooltipString', 'Start an experiment using the parameters',...
        'Callback', @(~,~) obj.beginExp(),...
        'Enable', 'off');
      controlbox.Sizes = [80 200 60 50 30 50 80];
      
      % a titled panel for the parameters editor
      param = uiextras.Panel('Parent', newExpBox, 'Title', 'Parameters', 'Padding', 5);
      obj.ParamPanel = uiextras.VBox('Parent', param, 'Padding', 5);
      hbox = uiextras.HBox('Parent', obj.ParamPanel);
      bui.label('Current set:', hbox);
      obj.ParamProfileLabel = bui.label('none', hbox, 'FontWeight', 'bold');
      hbox.Sizes = [60 400];
      hbox = uiextras.HBox('Parent', obj.ParamPanel, 'Spacing', 2);
      bui.label('Saved sets:', hbox);
      obj.NewExpParamProfile = bui.Selector(hbox, {'none'});
      uicontrol('Parent', hbox,...
        'Style', 'pushbutton',...
        'String', 'Load',...
        'Callback', @(~,~) obj.loadParamProfile(obj.NewExpParamProfile.Selected));
      uicontrol('Parent', hbox,...
        'Style', 'pushbutton',...
        'String', 'Save...',...
        'Callback', @(~,~) obj.saveParamProfile(),...
        'Enable', 'on');
      uicontrol('Parent', hbox,...
        'Style', 'pushbutton',...
        'String', 'Delete...',...
        'Callback', @(~,~) obj.delParamProfile(),...
        'Enable', 'on');
      hbox.Sizes = [60 200 60 60 60];
      obj.ParamPanel.Sizes = [22 22];
      
      newExpBox.Sizes = [58 22 -1];
      
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

