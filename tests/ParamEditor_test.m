classdef (SharedTestFixtures={matlab.unittest.fixtures.PathFixture(...
[fileparts(mfilename('fullpath')) '\fixtures'])})... % add 'fixtures' folder as test fixture 
  ParamEditor_test < matlab.unittest.TestCase
  
  properties
    % Figure visibility setting before running tests
    FigureVisibleDefault
    % ParamEditor instance
    ParamEditor
    % Figure handle for ParamEditor
    Figure
    % Handle to trial conditions UI Table
    Table
    % Test parameter structure
    Parameters
  end
  
  properties (SetAccess = private)
    % Flag set to true each time the ParamEditor's Changed event is
    % notified
    Changed = false
  end
  
  methods (TestClassSetup)
    function setup(testCase)
      % Hide figures and add teardown function to restore settings
      testCase.FigureVisibleDefault = get(0,'DefaultFigureVisible');
      set(0,'DefaultFigureVisible','off');
      testCase.addTeardown(@set, 0,...
        'DefaultFigureVisible', testCase.FigureVisibleDefault);
      
      % Loads validation data
      %  Graph data is a cell array where each element is the graph number
      %  (1:3) and within each element is a cell of X- and Y- axis values
      %  respectively
      testCase.Parameters = exp.choiceWorldParams;
      
      % Check paths file
      assert(endsWith(which('dat.paths'),...
        fullfile('tests', 'fixtures', '+dat', 'paths.m')));
      % Create stand-alone panel
      testCase.ParamEditor = eui.ParamEditor;
      testCase.Figure = gcf();
      testCase.addTeardown(@close, testCase.Figure);
      testCase.fatalAssertTrue(isa(testCase.ParamEditor, 'eui.ParamEditor'))
      % Find Condition Table
      testCase.Table = findobj(testCase.Figure, '-property', 'ColumnName');
      testCase.fatalAssertTrue(isa(testCase.Table, 'matlab.ui.control.Table'), ...
        'Failed to find handle to condition table')
    end
    
  end
    
  methods (TestMethodSetup)
    function buildParams(testCase)
      % Re-build the parameters before each test so that changes in
      % previous test don't persist
      PE = testCase.ParamEditor;
      pars = exp.Parameters(testCase.Parameters);
      PE.buildUI(pars);
      % Number of global parameters: find all text labels
      nGlobalLabels = numel(findobj(testCase.Figure, 'Style', 'text'));
      nGlobalInput = numel(findobj(testCase.Figure, 'Style', 'checkbox',...
        '-or', 'Style', 'edit'));
      % Ensure all global params have UI input and label
      testCase.fatalAssertTrue(nGlobalLabels == numel(PE.Parameters.GlobalNames))
      testCase.fatalAssertTrue(nGlobalInput == numel(PE.Parameters.GlobalNames))
      % Ensure all conditional params have column in table
      testCase.fatalAssertTrue(isequal(size(testCase.Table.Data), ...
        [PE.Parameters.numTrialConditions, numel(PE.Parameters.TrialSpecificNames)]))
      % Add callback for verifying that Changed event listeners are
      % notified
      callback = @(~,~)testCase.setChanged(true);
      lh = event.listener(testCase.ParamEditor, 'Changed', callback);
      testCase.addTeardown(@delete, lh);
      % Reset the Changed flag
      testCase.Changed = false;
    end
  end
  
  methods (Test)
    function test_makeConditional(testCase)
      % Make some global params trial conditions.  This test checks that
      % the UI elements are re-rendered after making a parameter
      % conditional, and that the underlying Parameters object is also
      % affected
      PE = testCase.ParamEditor;
      testCase.assertTrue(~testCase.Changed, 'Changed flag incorrect')
      % Number of global parameters: find all text labels
      gLabels = @()findobj(testCase.Figure, 'Style', 'text');
      gInputs = @()findobj(testCase.Figure, 'Style', 'checkbox',...
        '-or', 'Style', 'edit');
      nGlobalLabels = numel(gLabels());
      nGlobalInputs = numel(gInputs());
      tableSz = size(testCase.Table.Data);
      
      % Retrieve context menu function handle
      c = findobj(testCase.Figure, 'Text', 'Make Conditional');
      % Set the focused object to one of the parameter labels
      set(testCase.Figure, 'CurrentObject', ...
        findobj(testCase.Figure, 'Tag', 'rewardVolume'))
      testCase.verifyWarningFree(c.MenuSelectedFcn, ...
        'Problem making parameter conditional');
      % Verify Changed event triggered
      testCase.verifyTrue(testCase.Changed, ...
        'Failed to notify listeners of parameter change')
      % Verify change in UI elements
      testCase.verifyTrue(numel(gLabels()) == nGlobalLabels-1, ...
        'Global parameter UI element not removed')
      testCase.verifyTrue(numel(gInputs()) == nGlobalInputs-1, ...
        'Global parameter UI element not removed')
      testCase.verifyTrue(size(testCase.Table.Data,2) == tableSz(2)+1, ...
        'Incorrect condition table')
      % Verify change in Parameters object for global
      testCase.assertTrue(numel(gLabels()) == numel(PE.Parameters.GlobalNames))
      % Verify change in Parameters object for conditional
      testCase.assertTrue(isequal(size(testCase.Table.Data), ...
        [PE.Parameters.numTrialConditions, numel(PE.Parameters.TrialSpecificNames)]))
      % Verify table values are correct
      testCase.verifyTrue(isequal(testCase.Table.Data(:,1), repmat({'3'}, ...
        size(testCase.Table.Data,1), 1)), 'Unexpected table values')
      
      % Test behaviour when all params made conditional
      for param = gLabels()'
        % Set the focused object to one of the parameter labels
        set(testCase.Figure, 'CurrentObject', param)
        testCase.verifyWarningFree(c.MenuSelectedFcn, ...
          'Problem making parameter conditional');
      end
    end
    
    function test_paramValue2Control(testCase)
      % Test paramValue2Control and controlValue2Param
      PE = testCase.ParamEditor;
      % Test function handle
      testCase.verifyEqual(PE.paramValue2Control(@nop), 'nop')
      testCase.verifyEqual(PE.controlValue2Param(@nop, 'identity'),...
        @identity)
      
      % Test logical array
      testCase.verifyEqual(PE.paramValue2Control(true(1,2)), true(1,2))
      testCase.verifyEqual(PE.controlValue2Param(true(1,2), false(1,2)), false(1,2))
      testCase.verifyEqual(PE.controlValue2Param(true(1,2), zeros(1,2)), false(1,2))
      
      % Test char data
      testCase.verifyEqual(PE.paramValue2Control('hello'), 'hello')
      testCase.verifyEqual(PE.controlValue2Param('hello', 'goodbye'), 'goodbye')
      
      % Test type changes
      testCase.verifyEqual(PE.controlValue2Param('hello', 12, true), 12)
      try
        PE.controlValue2Param('hello', 12);
        testCase.verifyTrue(false, 'Failed to throw error on type change')
      catch ex
        testCase.verifyEqual(ex.message, 'Type change from char to double not allowed')
      end
      
      % Test string data 
      % TODO Outcome will change in near future
      testCase.verifyEqual(PE.paramValue2Control("hello"), 'hello')

      % Test numeric data
      testCase.verifyEqual(PE.paramValue2Control(pi), '3.1416')
      testCase.verifyEqual(PE.paramValue2Control([14, 2, 6]), '14, 2, 6')
      testCase.verifyEqual(PE.paramValue2Control([1, 3; 2, 4]), '1, 2, 3, 4')
      testCase.verifyEqual(PE.paramValue2Control({'1', '2', '3'}), '1, 2, 3')
      
      testCase.verifyEqual(PE.controlValue2Param([1 2 3], '4, 5, 6'), [4;5;6])
      testCase.verifyEqual(PE.controlValue2Param([1 2 3], '4, 5, 6', true), [4;5;6])
      testCase.verifyEqual(PE.controlValue2Param([1 2 3], {'4', '5', '6'}, true), {'4', '5', '6'})
      testCase.verifyEqual(PE.controlValue2Param({'1' '2'}, '4,5 6'), {'4'; '5'; '6'})
    end
    
    function test_newCondition(testCase)
      PE = testCase.ParamEditor;
      tableRows = size(testCase.Table.Data, 1);
      
      % Make function handle param conditional to test default value
      % Set the focused object to one of the parameter labels
      set(testCase.Figure, 'CurrentObject', ...
        findobj(testCase.Figure, 'Tag', 'experimentFun'))
      feval(pick(findobj(testCase.Figure, 'Text', 'Make Conditional'),...
        'MenuSelectedFcn'))
      
      % Reset Changed flag
      testCase.Changed = false;
      
      % Retrieve function handle for new condition
      fn = pick(findobj(testCase.Figure, 'String', 'New condition'),...
        'Callback');
      testCase.verifyWarningFree(fn,...
        'Warning encountered adding trial condition')
      
      % Verify change in table data
      testCase.verifyEqual(size(testCase.Table.Data, 1), tableRows+1, ...
        'Unexpected number of trial conditions')
      
      % Verify change in Parameters object for conditional
      testCase.assertEqual(size(testCase.Table.Data), ...
        [PE.Parameters.numTrialConditions, numel(PE.Parameters.TrialSpecificNames)])
      
      % Verify default conditions
      [~, trialParams] = PE.Parameters.assortForExperiment;
      testCase.verifyTrue(isequal(struct2cell(trialParams(end)), ...
        {@nop; zeros(2,1); zeros(3,1); false; 0}))
      
      % Verify listeners WEREN'T notified
      testCase.verifyTrue(~testCase.Changed, ...
        'Shouldn''t have notified listeners of parameter change')
    end
    
    function test_deleteCondition(testCase)
      PE = testCase.ParamEditor;
      testCase.assertTrue(~testCase.Changed, 'Changed flag incorrect')
      tableRows = size(testCase.Table.Data, 1);
      % Select some cells to delete
      event.Indices = [(1:5)' ones(5,1)];
      selection_fn = testCase.Table.CellSelectionCallback;
      selection_fn([],event)
            
      % Retrieve function handle for delete condition
      callback_fn = pick(findobj(testCase.Figure,...
        'String', 'Delete condition'), 'Callback');
      testCase.verifyWarningFree(callback_fn,...
        'Warning encountered deleting trial conditions')
      
      % Verify change in table data
      testCase.verifyEqual(size(testCase.Table.Data, 1), tableRows-5, ...
        'Unexpected number of trial conditions')
      
      % Verify change in Parameters object for conditional
      testCase.assertEqual(size(testCase.Table.Data),...
        [PE.Parameters.numTrialConditions, numel(PE.Parameters.TrialSpecificNames)])
      
      % Verify Changed event triggered
      testCase.verifyTrue(testCase.Changed, ...
        'Failed to notify listeners of parameter change')
      
      % Test behaviour when < 2 conditions remain
      event.Indices = [(1:PE.Parameters.numTrialConditions-1)' ...
        ones(PE.Parameters.numTrialConditions-1,1)];
      selection_fn([],event)
      testCase.verifyWarningFree(callback_fn,...
        'Warning encountered deleting trial conditions')
      
      % Verify change in table data
      testCase.verifyEmpty(testCase.Table.Data, ...
        'Unexpected number of trial conditions')
      % Verify change in Parameters object for conditional
      testCase.verifyEqual(size(testCase.Table.Data), ...
        [PE.Parameters.numTrialConditions, numel(PE.Parameters.TrialSpecificNames)])
    end
    
    function test_setValues(testCase)
      % TODO Add test for the set values button.  For now let's fail this
      testCase.assertTrue(~testCase.Changed, 'Changed flag incorrect')
%       PE = testCase.ParamEditor;
      testCase.assertTrue(false, 'Test not implemented')
    end
    
    function test_globaliseParam(testCase)
      PE = testCase.ParamEditor;
      testCase.assertTrue(~testCase.Changed, 'Changed flag incorrect')
      tableCols = size(testCase.Table.Data, 2);
      % Globalize one param
      event.Indices = [1, 2];
      selection_fn = testCase.Table.CellSelectionCallback;
      selection_fn([],event)

      % Retrieve function handle for new condition
      callback_fn = pick(findobj(testCase.Figure,...
        'String', 'Globalise parameter'), 'Callback');
      testCase.verifyWarningFree(callback_fn,...
        'Warning encountered globalising params')
      
      % Verify change in table data
      testCase.verifyEqual(size(testCase.Table.Data,2), tableCols-1, ...
        'Unexpected number of conditional parameters')
      % Verify change in Parameters object for conditional
      testCase.verifyEqual(size(testCase.Table.Data), ...
        [PE.Parameters.numTrialConditions, numel(PE.Parameters.TrialSpecificNames)])
      
      % Verify Changed event triggered
      testCase.verifyTrue(testCase.Changed, ...
        'Failed to notify listeners of parameter change')
      
      % Test removal of all but numRepeats: numRepeats should automatically
      % globalize
      n = numel(PE.Parameters.TrialSpecificNames)-1;
      event.Indices = [ones(n,1), (1:n)'];
      numRepeatsTotal = sum(PE.Parameters.Struct.numRepeats);
      selection_fn([],event)
      testCase.verifyWarningFree(callback_fn,...
        'Warning encountered globalising params')

      % Verify numRepeats is global
      testCase.verifyTrue(~PE.Parameters.isTrialSpecific('numRepeats'), ...
        'numRepeats not globalized')
      % Verify total number of repeats conserved
      testCase.verifyEqual(PE.Parameters.Struct.numRepeats, numRepeatsTotal,...
        'Unexpected numRepeats value')
      % Verify change in table data
      testCase.verifyEmpty(testCase.Table.Data, 'Unexpected number of trial conditions')
      % Verify change in Parameters object for conditional
      testCase.verifyEqual(size(testCase.Table.Data), ...
        [PE.Parameters.numTrialConditions, numel(PE.Parameters.TrialSpecificNames)])
      
      % Test removal of all but one param that isn't numRepeats
      % Reset table
      PE.buildUI(exp.Parameters(testCase.Parameters))
      % Globalize all but one param
      n = numel(PE.Parameters.TrialSpecificNames);
      event.Indices = [ones(n-1,1), (2:n)'];
      selection_fn([],event)
      testCase.verifyWarningFree(callback_fn,...
        'Warning encountered globalising params')
      
      % Verify change in table data
      testCase.verifyEqual(size(testCase.Table.Data,2), 1, ...
        'Unexpected number of conditional parameters')
      % Verify change in Parameters object for conditional
      testCase.verifyEqual(size(testCase.Table.Data), ...
        [PE.Parameters.numTrialConditions, numel(PE.Parameters.TrialSpecificNames)])
    end
    
    function test_paramEdits(testCase)
      % Test basic edits to Global UI controls and Condition table
      PE = testCase.ParamEditor;
      testCase.assertTrue(~testCase.Changed, 'Changed flag incorrect')

      % Retreive all global parameters labels and input controls
      gLabels = findobj(testCase.Figure, 'Style', 'text');
      gInputs = findobj(testCase.Figure, 'Style', 'checkbox',...
        '-or', 'Style', 'edit');

      % Test editing global param, 'edit' UI
      idx = find(strcmp({gInputs.Style}, 'edit'), 1);
      % Change string
      gInputs(idx).String = '666';
      % Trigger callback
      callback_fcn = gInputs(idx).Callback;
      callback_fcn(gInputs(idx));
      
      % Verify change in ui string
      testCase.verifyEqual(gInputs(idx).String, '666')
      % Verify change in label color
      testCase.verifyEqual(gLabels(idx).ForegroundColor, [1 0 0], ...
        'Unexpected label colour')
      % Verify change in underlying param struct
      par = strcmpi(PE.Parameters.GlobalNames, strrep(gLabels(idx).String, ' ', ''));
      testCase.verifyEqual(PE.Parameters.Struct.(PE.Parameters.GlobalNames{par}), 666, ...
        'UI edit failed to update parameters struct')
      % Verify Changed event triggered
      testCase.verifyTrue(testCase.Changed, ...
        'Failed to notify listeners of parameter change')
      testCase.Changed = false;
      
      % Test editing global param, 'checkbox' UI
      idx = find(strcmp({gInputs.Style}, 'checkbox'), 1);
      % Change value
      gInputs(idx).Value = ~gInputs(idx).Value;
      % Trigger callback
      callback_fcn = gInputs(idx).Callback;
      callback_fcn(gInputs(idx));
      
      % Verify change in label color
      testCase.verifyEqual(gLabels(idx).ForegroundColor, [1 0 0], ...
        'Unexpected label colour')
      % Verify change in underlying param struct
      par = strcmpi(PE.Parameters.GlobalNames, strrep(gLabels(idx).String, ' ', ''));
      testCase.verifyEqual(...
        PE.Parameters.Struct.(PE.Parameters.GlobalNames{par}), gInputs(idx).Value==true, ...
        'UI checkbox failed to update parameters struct')
      % Verify Changed event triggered
      testCase.verifyTrue(testCase.Changed, ...
        'Failed to notify listeners of parameter change')
      testCase.Changed = false;
      
      % Test edits to conditions table
      callback_fcn = testCase.Table.CellEditCallback;
      event.Indices = [1, 1];
      event.NewData = '0,5';
      callback_fcn(testCase.Table, event)

      % Verify change to table value
      testCase.verifyEqual(testCase.Table.Data{1,1}, '0, 5', ...
        'Unexpected table data')
      % Verify change in underlying param struct
      value = PE.Parameters.Struct.(PE.Parameters.TrialSpecificNames{1});
      testCase.verifyEqual(value(:,1), [0;5], ...
        'Table UI failed to update parameters struct')
      % Verify Changed event triggered
      testCase.verifyTrue(testCase.Changed, ...
        'Failed to notify listeners of parameter change')
    end
    
    function test_interactivity(testCase)
      PE = testCase.ParamEditor;
      % Test buttons grey out when nothing selected
      % Deselect table rows
      callback_fcn = testCase.Table.CellSelectionCallback;
      event.Indices = []; % Nothing selected
      callback_fcn([], event) % Run selection callback (onSelect)
      
      % Find all disabled controls
      disabled = findobj(testCase.Figure, 'Enable', 'off');
      % Verify buttons greyed out
      testCase.verifyEqual(numel(disabled), 5, ...
        'Unexpected number of disabled ui elements')
      
      % Re-select something
      event.Indices = [1, 1]; % Nothing selected
      callback_fcn([], event) % Run selection callback (onSelect)
      % Find all disabled controls
      disabled = findobj(testCase.Figure, 'Enable', 'off');
      % Verify buttons greyed out
      testCase.verifyEmpty(disabled,...
        'Unexpected number of disabled ui elements')
      
      % Test disabling param editor altogether
      PE.Enable = false;
      % Find all enabled controls
      enabled = findobj(testCase.Figure, 'Enable', 'on');
      % Verify buttons greyed out
      testCase.verifyEmpty(enabled, 'Not all ui elements disabled')
      
      % Re-enable param editor
      PE.Enable = true;
      % Find all disabled controls
      disabled = findobj(testCase.Figure, 'Enable', 'off');
      % Verify buttons greyed out
      testCase.verifyEmpty(disabled, 'Not all ui elements enabled')
    end
    
  end
  
  methods
    function setChanged(testCase, value)
      testCase.Changed = value;
    end
  end
  
end