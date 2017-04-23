classdef ParamEditor < handle
    %EUI.PARAMEDITOR UI control for configuring experiment parameters
    %   See also EXP.PARAMETERS.
    %
    % Part of Rigbox
    
    % 2012-11 CB created
    % 2017-03 MW/NS Made global panel scrollable & improved performance of
    % buildGlobalUI.
    
    % Notes/TODO:
    % - reorganize logic of global: 
    %   - one function is told how many new global controls to add, and adds them to any existing
    %   - one function sets heights/etc properly
    %   - one function fills existing controls with names/values
    % - Q: how much faster to change only a small number of control values
    % rather than re-fill them all? May be able to get speed improvements
    % by for instance setting a row's height to zero when conditionalizing
    % rather than re-shifting them all. Should try complete re-populating
    % first and see how fast it is though. 
    
    
    properties
        GlobalVSpacing = 20
        Parameters
    end
    
    properties (Dependent)
        Enable
    end
    
    properties (Access = private)
        Root
        GlobalGrid
        ConditionTable
        TableColumnParamNames = {}
        NewConditionButton
        DeleteConditionButton
        MakeGlobalButton
        SelectedCells %[row, column;...] of each selected cell
        GlobalControls
    end
    
    events
        Changed
    end
    
    methods
        function obj = ParamEditor(params, parent)
            if nargin < 2 % Can call this function to display parameters is new window
                parent = figure('Name', 'Parameters', 'NumberTitle', 'off',...
                    'Toolbar', 'none', 'Menubar', 'none');
            end
            obj.Parameters = params;
            obj.build(parent);
        end
        
        function newParams(obj, params) 
            % This will keep the existing UI elements but completely
            % re-fill everything with the new parameters that are provided
            % here
            
            obj.clearEditor;
            obj.Parameters = params;
            
            % need to make any new global ui elements? 
            globalParamNames = fieldnames(obj.Parameters.assortForExperiment);
            nNew = length(globalParamNames)-size(obj.GlobalControls,1);
            if nNew>0
                obj.newGlobalControls(nNew)
            end                
            
            obj.fillGlobalControls();
            obj.fillConditionTable();
            
        end
        
        function clearEditor(obj)
            % This function hides all the global paramUIs (visible=off) and
            % empties the conditional table
            
            % Performance questions:
            % - Faster to query Visible and set off only if necessary?
            
            arrayfun(@(x)set(x, 'Visible', 'off'), obj.GlobalControls);
            set(obj.ConditionTable, 'ColumnName', 'Load new parameter set to continue', 'Data', [],...
                'ColumnEditable', true);
            
        end
        
        function delete(obj)
            disp('ParamEditor destructor called');
            if obj.Root.isvalid
                obj.Root.delete();
            end
        end
        
        function value = get.Enable(obj)
            value = obj.Root.Enable;
        end
        
        function set.Enable(obj, value)
            obj.Root.Enable = value;
        end
    end
    
    methods %(Access = protected)
        function build(obj, parent) % Build parameters panel
            obj.Root = uiextras.HBox('Parent', parent, 'Padding', 5, 'Spacing', 5); % Add horizontal container for Global and Conditional panels
            
            globPanel = uiextras.Panel('Parent', obj.Root,... % Make 'Global' parameters panel (just to get the title)
                'Title', 'Global', 'Padding', 5);
            obj.globalPanel = uix.ScrollingPanel('Parent', globPanel,... % Make 'Global' scroll panel
                'Padding', 5);
            
            obj.GlobalGrid = uiextras.Grid('Parent', obj.globalPanel, 'Padding', 4); % Make grid for parameter fields
            globalParamNames = fieldnames(obj.Parameters.assortForExperiment);
            obj.newGlobalControls(length(globalParamNames));
            obj.fillGlobalControls();
            
            conditionPanel = uiextras.Panel('Parent', obj.Root,...
                'Title', 'Conditional', 'Padding', 5); % Make 'Conditional' parameters panel
            conditionVBox = uiextras.VBox('Parent', conditionPanel);
            obj.ConditionTable = uitable('Parent', conditionVBox,...
                'FontName', 'Consolas',...
                'RowName', [],...
                'CellEditCallback', @obj.cellEditCallback,...
                'CellSelectionCallback', @obj.cellSelectionCallback);
            obj.fillConditionTable();
            conditionButtonBox = uiextras.HBox('Parent', conditionVBox);
            conditionVBox.Sizes = [-1 25];
            obj.NewConditionButton = uicontrol('Parent', conditionButtonBox,...
                'Style', 'pushbutton',...
                'String', 'New condition',...
                'TooltipString', 'Add a new condition',...
                'Callback', @(~, ~) obj.newCondition());
            obj.DeleteConditionButton = uicontrol('Parent', conditionButtonBox,...
                'Style', 'pushbutton',...
                'String', 'Delete condition',...
                'TooltipString', 'Delete the selected condition',...
                'Enable', 'off',...
                'Callback', @(~, ~) obj.deleteSelectedConditions());
            obj.MakeGlobalButton = uicontrol('Parent', conditionButtonBox,...
                'Style', 'pushbutton',...
                'String', 'Globalise parameter',...
                'TooltipString', sprintf(['Make the selected condition-specific parameter global (i.e. not vary by trial)\n'...
                'This will move it to the global parameters section']),...
                'Enable', 'off',...
                'Callback', @(~, ~) obj.globaliseSelectedParameters());
            
            obj.Root.Sizes = [sum(obj.GlobalGrid.ColumnSizes) + 32, -1];
        end
        
        function newGlobalControls(obj, nNew) 
            % Function to create global controls (but not populate them)
            % TODO: this is not done 
            % - see whether we already have any existing global controls
            % - if not, initilize obj.GlobalControls; if so, resize it
            % - create the elements, populate obj.GlobalControls, re-sort
            % as necessary. Re-sizing isn't necessary here because it'll
            % happen when filling the controls
            
            fprintf(1, 'creating %d global controls\n', nNew)
            
            oldControls = obj.GlobalControls;
            nOld = size(oldControls,1);
            obj.GlobalControls = gobjects(nOld+nNew,3);
            obj.GlobalControls(1:nOld,:) = oldControls;
            
            for i = nOld+1:nOld+nNew
                [obj.GlobalControls(i,1), obj.GlobalControls(i,2), obj.GlobalControls(i,3)]... % [editors, labels, buttons]
                    = obj.addParamUI();
            end                        
            fprintf(1, '  done\n', nNew)
%             child_handles = allchild(obj.GlobalGrid); % Get child handles for GlobalGrid
%             child_handles = [child_handles(end-1:-3:1); child_handles(end:-3:1); child_handles(end-2:-3:1)]; % Reorder them so all labels come first, then ctrls, then buttons
%             obj.GlobalGrid.Contents = child_handles; % Set children to new order
                        
        end
        
        
        function addEmptyConditionToParam(obj, name)
            assert(obj.Parameters.isTrialSpecific(name),...
                'Tried to add a new condition to global parameter ''%s''', name);
            % work out what the right 'empty' is for the parameter
            currValue = obj.Parameters.Struct.(name);
            if isnumeric(currValue)
                newValue = zeros(size(currValue, 1), 1, class(currValue));
            elseif islogical(currValue)
                newValue = false(size(currValue, 1), 1);
            elseif iscell(currValue)
                if numel(currValue) > 0
                    if iscellstr(currValue)
                        % if all elements are strings, default to a blank string
                        newValue = {''};
                    elseif isa(currValue{1}, 'function_handle')
                        % first element is a function handle, so create with a @nop
                        % handle
                        newValue = {@nop};
                    else
                        % misc cell case - default to empty element
                        newValue = {[]};
                    end
                else
                    % misc case - default to empty element
                    newValue = {[]};
                end
            else
                error('Adding empty condition for ''%s'' type not implemented', class(currValue));
            end
            obj.Parameters.Struct.(name) = cat(2, obj.Parameters.Struct.(name), newValue);
        end
        
        function cellSelectionCallback(obj, src, eventData)
            obj.SelectedCells = eventData.Indices;
            if size(eventData.Indices, 1) > 0
                %cells selected, enable buttons
                set(obj.MakeGlobalButton, 'Enable', 'on');
                set(obj.DeleteConditionButton, 'Enable', 'on');
            else
                %nothing selected, disable buttons
                set(obj.MakeGlobalButton, 'Enable', 'off');
                set(obj.DeleteConditionButton, 'Enable', 'off');
            end
        end
        
        function newCondition(obj)
            disp('adding new condition row');
            cellfun(@obj.addEmptyConditionToParam, obj.Parameters.TrialSpecificNames);
            obj.fillConditionTable();
        end
        
        function deleteSelectedConditions(obj)
            rows = unique(obj.SelectedCells(:,1));
            obj.Parameters.removeConditions(rows);
            obj.fillConditionTable(); %refresh the table of conditions
        end
        
        function globaliseSelectedParameters(obj)
            [cols, iu] = unique(obj.SelectedCells(:,2));
            names = obj.TableColumnParamNames(cols);
            rows = obj.SelectedCells(iu,1); %get rows of unique selected cols
            arrayfun(@obj.globaliseParamAtCell, rows, cols);
            obj.fillConditionTable(); %refresh the table of conditions
            
            %now add global controls for parameters
            % TODO: change this instead to simply populate the existing
            % controls
            newGlobals = gobjects(length(names),3); % Initialize object array (faster than assigning to end of array which results in two calls to constructor)
            for i=length(names):-1:1 % using for loop (sorry Chris!) to initialize and populate object array 2017-02-15 MW
                [newGlobals(i,1), newGlobals(i,2), newGlobals(i,3)]... % [editors, labels, buttons]
                    = obj.addParamUI(names{i});
            end
            
            %       [editors, labels, buttons] = arrayfun(@obj.addParamUI, names); %
            %       2017-02-15 MW can no longer use arrayfun with object outputs
            idx = size(obj.GlobalControls, 1); % Calculate number of current Global params
            new = numel(newGlobals);
            obj.GlobalControls = [obj.GlobalControls; newGlobals]; % Add new globals to object
            ggHandles = obj.GlobalGrid.Contents;
            ggHandles = [ggHandles(1:idx); ggHandles((end-new+2):3:end);...
                ggHandles(idx+1:idx*2); ggHandles((end-new+1):3:end);...
                ggHandles(idx*2+1:idx*3); ggHandles((end-new+3):3:end)]; % Reorder them so all labels come first, then ctrls, then buttons
            obj.GlobalGrid.Contents = ggHandles; % Set children to new order
            
            % Reset sizes
            obj.GlobalGrid.RowSizes = repmat(obj.GlobalVSpacing, 1, size(obj.GlobalControls, 1));
            set(get(obj.GlobalGrid, 'Parent'),...
                'Heights', sum(obj.GlobalGrid.RowSizes)+45); % Reset height of globalPanel
            obj.GlobalGrid.ColumnSizes = [180, 200, 40];
            obj.GlobalGrid.Spacing = 1;
        end
        
        function globaliseParamAtCell(obj, row, col)
            name = obj.TableColumnParamNames{col};
            value = obj.Parameters.Struct.(name)(:,row);
            obj.Parameters.makeGlobal(name, value);
        end
        
        function cellEditCallback(obj, src, eventData)            
            row = eventData.Indices(1);
            col = eventData.Indices(2);
            paramName = obj.TableColumnParamNames{col};
            currValue = obj.Parameters.Struct.(paramName)(:,row);
            if iscell(currValue)
                % cell holders are allowed to be different types of value
                newParam = obj.controlValue2Param(currValue{1}, eventData.NewData, true);
                obj.Parameters.Struct.(paramName){:,row} = newParam;
            else
                newParam = obj.controlValue2Param(currValue, eventData.NewData);
                obj.Parameters.Struct.(paramName)(:,row) = newParam;
            end
            % if successful update the cell with default formatting
            data = get(src, 'Data');
            reformed = obj.paramValue2Control(newParam);
            if iscell(reformed)
                % the reformed data type is a cell, this should be a one element
                % wrapping cell
                if numel(reformed) == 1
                    reformed = reformed{1};
                else
                    error('Cannot handle data reformatted data type');
                end
            end
            data{row,col} = reformed;
            set(src, 'Data', data);
            %notify listeners of change
            notify(obj, 'Changed');
        end
        
        function updateGlobal(obj, param, src)
            % callback for when the value of a global parameter has been
            % modified by the user
            
            currParamValue = obj.Parameters.Struct.(param);
            switch get(src, 'style')
                case 'checkbox'
                    newValue = logical(get(src, 'value'));
                    obj.Parameters.Struct.(param) = newValue;
                case 'edit'
                    newValue = obj.controlValue2Param(currParamValue, get(src, 'string'));
                    obj.Parameters.Struct.(param) = newValue;
                    % if successful update the control with default formatting and
                    % modified colour
                    set(src, 'String', obj.paramValue2Control(newValue),...
                        'ForegroundColor', [1 0 0]); %red indicating it has changed
                    %notify listeners of change
                    notify(obj, 'Changed');
            end
        end
        
        function [data, paramNames, titles] = tableData(obj)
            [~, trialParams] = obj.Parameters.assortForExperiment;
            paramNames = fieldnames(trialParams);
            titles = obj.Parameters.title(paramNames);
            data = reshape(struct2cell(trialParams), numel(paramNames), [])';
            data = mapToCell(@(e) obj.paramValue2Control(e), data);
        end
        
        function data = controlValue2Param(obj, currParam, data, allowTypeChange)
            if nargin < 4
                allowTypeChange = false;
            end
            % convert from control value to parameter value
            switch class(currParam)
                case 'function_handle'
                    data = str2func(data);
                case 'logical'
                    data = data ~= 0;
                case 'char'
                    % do nothing - strings stay as strings
                otherwise
                    if isnumeric(currParam)
                        % parse string as numeric vector
                        try
                            C = textscan(data, '%f',...
                                'ReturnOnError', false,...
                                'delimiter', {' ', ','}, 'MultipleDelimsAsOne', 1);
                            data = C{1};
                        catch ex
                            % if a type change is allowed, then a numeric can become a
                            % string, otherwise rethrow the parse error
                            if ~allowTypeChange
                                rethrow(ex);
                            end
                        end
                    elseif iscellstr(currParam)
                        C = textscan(data, '%s',...
                            'ReturnOnError', false,...
                            'delimiter', {' ', ','}, 'MultipleDelimsAsOne', 1);
                        data = C{1};%deblank(num2cell(data, 2));
                    else
                        error('Cannot update unimplemented type ''%s''', class(currParam));
                    end
            end
        end
        
        function data = paramValue2Control(obj, data)
            % convert from parameter value to control value
            switch class(data)
                case 'function_handle'
                    % convert a function handle to it's string name
                    data = func2str(data);
                case 'logical'
                    data = data ~= 0; % If logical do nothing, basically.
                otherwise
                    if isnumeric(data)
                        % format numeric types as string number list
                        strlist = mapToCell(@num2str, data);
                        data = strJoin(strlist, ', ');
                    elseif iscellstr(data)
                        data = strJoin(data, ', ');
                    end
            end
            % all other data types stay as they are, including e.g. strings
        end
        
        function fillConditionTable(obj)
            [data, params, titles] = obj.tableData;
            set(obj.ConditionTable, 'ColumnName', titles, 'Data', data,...
                'ColumnEditable', true(1, numel(titles)));
            obj.TableColumnParamNames = params;
        end
        
        function makeTrialSpecific(obj, paramName, ctrls)
            % TODO: just hide the global control. However, need also to
            % either re-order the rows, then, or else shift all the labels
            % up. Could probably re-set all the paramUIs "from scratch"
            % without it being too slow - to test.                         
            
            [uirow, ~] = find(obj.GlobalControls == ctrls{1});
            assert(numel(uirow) == 1, 'Unexpected number of matching global controls');
            
            obj.Parameters.makeTrialSpecific(paramName);
            obj.fillConditionTable();
            obj.fillGlobalControls();
            
%             cellfun(@(c) delete(c), ctrls);
%             obj.GlobalControls(uirow,:) = [];
%             obj.GlobalGrid.RowSizes(uirow) = [];
%             
%             set(get(obj.GlobalGrid, 'Parent'),...
%                 'Heights', sum(obj.GlobalGrid.RowSizes)+45); % Reset height of globalPanel
        end
        
        function [ctrl, label, buttons] = addParamUI(obj)
            % This function now creates an empty and invisible param UI, that
            % will be updated with appropriate values later.
            
            parent = obj.GlobalGrid; % Made by build function above
            ctrl = uicontrol('Parent', parent,...
                'Style', 'edit', ...
                'Tag', 'ctrl', ... % will use this for proper ordering later
                'TooltipString', '',...
                'Value', [],...
                'Visible', 'off', ...
                'HorizontalAlignment', 'left',...
                'Callback', @(src, e) obj.updateGlobal('', src));
            
            label = uicontrol('Parent', parent,...
                'Style', 'text', ...
                'Tag', 'label', ...
                'String', '', ...
                'HorizontalAlignment', 'left',...
                'Visible', 'off', ...
                'TooltipString', '');
            
            % 'Make parameter conditional' button
            buttons = uicontrol('Parent', parent, 'Style', 'pushbutton',...
                'String', '[...]',...
                'Tag', 'button', ...
                'TooltipString', sprintf(['Make this a condition parameter (i.e. vary by trial).\n'...
                'This will move it to the trial conditions table.']),...
                'FontSize', 7,...
                'Visible', 'off', ...
                'Callback', @(~,~) obj.makeTrialSpecific('', {ctrl, label, bbox}));
        end
        
        function fillGlobalControls(obj)
            % Go through all the global parameters in order, turn on and
            % fill the corresponding UI elements, and set the grid sizing
            % appropriately
        
            globalParamNames = fieldnames(obj.Parameters.assortForExperiment);
            ctrls = obj.GlobalControls(strcmp(get(obj.GlobalControls, 'Tag'), 'ctrl'));
            labels = obj.GlobalControls(strcmp(get(obj.GlobalControls, 'Tag'), 'label'));
            buttons = obj.GlobalControls(strcmp(get(obj.GlobalControls, 'Tag'), 'button'));
            
            assert(length(globalParamNames)<=length(ctrls), 'Should have made enough controls by here\n');
            
            for p = 1:length(globalParamNames)
                % STOPPED HERE: pass buttons also to updateParamUI, set
                % callbacks properly there
                obj.updateParamUI(globalParamNames{p}, ctrls(p), labels(p));
                
            end
            
            obj.GlobalGrid.ColumnSizes = [180, 200, 40]; % Set column sizes
            obj.GlobalGrid.Spacing = 1;
            obj.GlobalGrid.RowSizes = repmat(obj.GlobalVSpacing, 1, size(obj.GlobalControls, 1));
            obj.globalPanel.Heights = sum(obj.GlobalGrid.RowSizes)+45;

        end
            
        function didSet = updateParamUI(obj, name, ctrl, label) % Updates ui element for each parameter
            % Now we need to update the paramUI with the correct information.
            % The ctrl and label have already been created and are now provided
            % to this function
            if iscell(name)
                name = name{1,1};
            end
            value = obj.paramValue2Control(obj.Parameters.Struct.(name));  % convert from parameter value to control value (everything but logical values become strings)
            title = obj.Parameters.title(name);
            description = obj.Parameters.description(name);
            didSet = false;
            
            if islogical(value) % If parameter is logical, make checkbox
                set(ctrl, 'Style', 'checkbox', ...
                    'TooltipString', description,...
                    'Value', value,...
                    'UserData', name,...
                    'Visible', 'on',...
                    'Callback', @(src, e) obj.updateGlobal(name, src));
                didSet = true;
            elseif ischar(value)
                set(ctrl, 'Style', 'edit', ...
                    'TooltipString', description,...
                    'String', value,...
                    'UserData', name,...
                    'Visible', 'on');
                didSet = true;
            end
            
            if didSet
                set(label, 'String', title, ...
                    'TooltipString', description, ...
                    'Visible', 'on');
            end
            
            
        end
        
        
        
    end
        
