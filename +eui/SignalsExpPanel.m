classdef SignalsExpPanel < eui.ExpPanel
  %EUI.SIGNALSEXPPANEL Basic UI control for monitoring a Signals experiment
  %   Displays all values of events, inputs and outputs signals as they
  %   arrive from the remote stimulus server.  These events arrive as
  %   'signals' ExpEvents which are added to the SignalUpdates queue by
  %   expUpdate and processed by processUpdates upon calling the update
  %   method.
  %
  %
  % Part of Rigbox
  
  % 2015-03 CB created
  
  properties
    % Structure of signals event updates from SignalExp.  As new updates
    % come in, previous updates in the list are overwritten
    SignalUpdates = struct('name', cell(500,1), 'value', cell(500,1), 'timestamp', cell(500,1))
    % List of updates to exclude (when Exclude == true) or to exclusively
    % show (Exclude == false) in the InfoGrid.
    UpdatesFilter = ["inputs.wheel", "pars"]
    % Flag for excluding updates in UpdatesFilter list from InfoGrid.  When
    % false only those in the list are shown, when false those in the list
    % are hidden
    Exclude = true
    % Flag for formating Signals updates in the InfoField Labels
    FormatLabels = false
    % The total number of 
    NumSignalUpdates = 0
    % containers.Map of InfoGrid ui labels mapped to their corresponding
    % Signal name
    LabelsMap
    % The colour of recently updated Signals update events in the InfoGrid
    RecentColour = [0 1 0]
  end
  
  
  methods
    function obj = SignalsExpPanel(parent, ref, params, logEntry)
      % Subclasses must chain a call to this.
      obj = obj@eui.ExpPanel(parent, ref, params, logEntry);
      obj.LabelsMap = containers.Map(); % Initialize labels map
    end
    
    function update(obj)
      % UPDATE Update the panel
      %  Processes any new updates via a call to the processUpdates method
      %  and changes colours of info field labels based on how recently
      %  they updated.  This method is the callback to the RefreshTimer in
      %  MC.  Subclasses must chain a call to this.
      %
      % See also eui.ExpPanel/update
      update@eui.ExpPanel(obj); % Elapsed timer updated by superclass
      processUpdates(obj); % Update labels with latest signal values
      labelsMapVals = values(obj.LabelsMap)';
      labels = deal([labelsMapVals{:}]);
      if ~isempty(labels) % Colour decay by recency on labels
        dt = cellfun(@(t)etime(clock,t),...
          ensureCell(get(labels, 'UserData')));
        c = num2cell(exp(-dt/1.5)*obj.RecentColour, 2);
        set(labels, {'ForegroundColor'}, c);
      end
    end
  end
  
  methods (Access = protected)
    function newTrial(obj, num, condition)
      % NEWTRIAL Process new trial conditions
      %  Do nothing, this is for subclasses to override and react to, e.g.
      %  to update plots, etc. based on a new trial's conditional
      %  parameters.  For a SignalsExp experiment, this may be called by
      %  the processUpdates method upon an events.newTrial signal update.
      %  In the future SignalsExp may send newTrial events (i.e.
      %  independant of the 'signals' event updates)
      %  
      %  Inputs:
      %    num (int) : The new trial number.  May be used to index into
      %                Block property
      %    condition (struct) : Condition data for the new trial
      %
      % See also processUpdates, expUpdate, trialCompleted
    end
    
    function trialCompleted(obj, num, data)
      % TRIALCOMPLETED Process completed trial data
      %  Do nothing, this is for subclasses to override and react to, e.g.
      %  to update plots, etc. based on a complete trial's data.  Called by
      %  expUpdate method upon 'trialData' event (currently not used by
      %  exp.SignalsExp).
      %  
      %  Inputs:
      %    num (int) : The new trial number.  May be used to index into
      %                Block property
      %    data (struct) : Completed trial data
      %
      % See also expUpdate, processUpdates, trialCompleted
    end
    
    function event(obj, name, t)
      % EVENT Process none-signals experiment event
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
    
    function fieldCtrl = addInfoField(obj, name, value)
      % ADDINFOFIELD Add new event info field to InfoGrid
      %  Adds a given field to the grid and adjusts the total height of the
      %  grid to accomodate all current fields.  If the FormatLabels
      %  property is true, the updates are formatted with a space beween
      %  capital letters.
      %
      %  Example:
      %    obj.FormatLabels = true;
      %    obj.addInfoField('events.newTrial', 0)
      %    obj.InfoLabels(1).String % Formatted as 'New trial'
      %
      % See also eui.ExpPanel/addInfoField
      if any(name=='.') && obj.FormatLabels == true
        name = extractAfter(name, '.'); % Take substring after dot
        name = lower(regexprep(name, '([a-z])([A-Z])', '$1 $2')); % Spaces
        name(1) = upper(name(1)); % Capitalize first letter
      end
      fieldCtrl = addInfoField@eui.ExpPanel(obj, name, value);
    end
    
    function processUpdates(obj)
      % PROCESSUPDATES Process all accumulated signals event updates
      %  Process the signals events that have occured since the method was
      %  last called.  Any new field labels are created and all fields are
      %  updated with the most recent signal values.
      %
      %  This function is downstream of the update method, which is 
      %
      % See also expUpdate, update
      updates = obj.SignalUpdates(1:obj.NumSignalUpdates);
      obj.NumSignalUpdates = 0;
      %       fprintf('processing %i signal updates\n', length(updates));
      for ui = 1:length(updates)
        signame = updates(ui).name;
        switch signame
          case 'events.trialNum'
            set(obj.TrialCountLabel, ...
              'String', num2str(updates(ui).value));
          otherwise
            % Check whether to display update using UpdatesFilter
            onList = any(ismember(signame, obj.UpdatesFilter));
            if (obj.Exclude && ~onList) || (~obj.Exclude && onList)
              if ~isKey(obj.LabelsMap, signame) % If new update, add field
                obj.LabelsMap(signame) = obj.addInfoField(signame, '');
              end
              str = toStr(updates(ui).value); % Convert the value to string
              set(obj.LabelsMap(signame), 'String', str, 'UserData', clock,...
                'ForegroundColor', obj.RecentColour); % Update value
            end
        end
      end
    end
    
    function expUpdate(obj, rig, evt)
      % EXPUPDATE Callback to the remote rig ExpUpdate event
      %  Processes a new experiment event.  Signals events are added to the
      %  SignalUpdates queue for processing by the processUpdates method.
      %
      %   Inputs:
      %     rig (srv.StimulusControl) : The source of the event
      %     evt (srv.ExpEvent) : The experiment event object
      %
      % See also live, event, srv.StimulusControl, srv.ExpEvent
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
          catch % see github.com/cortex-lab/Rigbox/issues/72
            id  = 'Rigbox:eui:SignalsExpPanel:signalsUpdateMismatch';
            msg = 'Error caught in signals updates: length of updates = %g, length newNUpdates = %g';
            warning(id, msg, length(updates), newNUpdates-(obj.NumSignalUpdates+1))
          end
          obj.NumSignalUpdates = newNUpdates;
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
    
  end
  
end

