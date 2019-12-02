classdef (SharedTestFixtures={matlab.unittest.fixtures.PathFixture(...
fullfile(getOr(dat.paths,'rigbox'), 'tests', 'fixtures'))})... % add 'fixtures' folder as test fixture
ParamEditor_perfTest < matlab.perftest.TestCase
  
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
      assert(isa(testCase.ParamEditor, 'eui.ParamEditor'))
      % Find Condition Table
      testCase.Table = findobj(testCase.Figure, '-property', 'ColumnName');
      assert(isa(testCase.Table, 'matlab.ui.control.Table'), ...
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
      nGlobalInput = numel(findobj(testCase.Figure,...
        'Style', 'checkbox', '-or', 'Style', 'edit'));
      % Ensure all global params have UI input and label
      assert(nGlobalLabels == numel(PE.Parameters.GlobalNames))
      assert(nGlobalInput == numel(PE.Parameters.GlobalNames))
      % Ensure all conditional params have column in table
      assert(isequal(size(testCase.Table.Data), ...
        [PE.Parameters.numTrialConditions, numel(PE.Parameters.TrialSpecificNames)]))
    end
  end
  
  methods (Test)
    function test_newParamEditor(testCase)
      % Test instantiate new param editor from scratch
      pars = exp.Parameters(testCase.Parameters);
      testCase.startMeasuring();
      PE = eui.ParamEditor(pars);
      testCase.stopMeasuring();
      close(gcf)
      delete(PE)
    end
    
    function test_buildUI(testCase)
      % Test clear and rebuild params
      pars = exp.Parameters(testCase.Parameters);
      testCase.startMeasuring();
      testCase.ParamEditor.buildUI(pars);
      testCase.stopMeasuring();
    end
        
    function test_makeConditional(testCase)
      % Make some global params trial conditions.  This test checks that
      % the UI elements are re-rendered after making a parameter
      % conditional, and that the underlying Parameters object is also
      % affected
      PE = testCase.ParamEditor;
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
      
      %%% Make conditional %%%
      testCase.startMeasuring();
      c.MenuSelectedFcn()
      testCase.stopMeasuring();
      
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
            
      % Retrieve function handle for new condition
      fn = pick(findobj(testCase.Figure, 'String', 'New condition'),...
        'Callback');
      testCase.startMeasuring();
      fn()
      testCase.stopMeasuring();

      % Verify change in table data
      testCase.verifyEqual(size(testCase.Table.Data, 1), tableRows+1, ...
        'Unexpected number of trial conditions')
      
      % Verify change in Parameters object for conditional
      testCase.assertEqual(size(testCase.Table.Data), ...
        [PE.Parameters.numTrialConditions, numel(PE.Parameters.TrialSpecificNames)])
    end
    
    function test_deleteCondition(testCase)
      PE = testCase.ParamEditor;
      tableRows = size(testCase.Table.Data, 1);
      % Select some cells to delete
      event.Indices = [(1:5)' ones(5,1)];
      selection_fn = testCase.Table.CellSelectionCallback;
      selection_fn([],event)
            
      % Retrieve function handle for delete condition
      callback_fn = pick(findobj(testCase.Figure,...
        'String', 'Delete condition'), 'Callback');
      testCase.startMeasuring();
      callback_fn()
      testCase.stopMeasuring();

      % Verify change in table data
      testCase.verifyEqual(size(testCase.Table.Data, 1), tableRows-5, ...
        'Unexpected number of trial conditions')
      
      % Verify change in Parameters object for conditional
      testCase.assertEqual(size(testCase.Table.Data), ...
        [PE.Parameters.numTrialConditions, numel(PE.Parameters.TrialSpecificNames)])
    end
    
    function test_globaliseParam(testCase)
      PE = testCase.ParamEditor;
      tableCols = size(testCase.Table.Data, 2);
      % Globalize one param
      event.Indices = [1, 2];
      selection_fn = testCase.Table.CellSelectionCallback;
      selection_fn([],event)

      % Retrieve function handle for new condition
      callback_fn = pick(findobj(testCase.Figure, 'String',...
        'Globalise parameter'), 'Callback');
      testCase.startMeasuring();
      callback_fn()
      testCase.stopMeasuring();
      
      % Verify change in table data
      testCase.verifyEqual(size(testCase.Table.Data,2), tableCols-1, ...
        'Unexpected number of conditional parameters')
      % Verify change in Parameters object for conditional
      testCase.verifyEqual(size(testCase.Table.Data), ...
        [PE.Parameters.numTrialConditions, numel(PE.Parameters.TrialSpecificNames)])
    end
    
    function test_paramEdits(testCase)
      % Test basic edits to Global UI controls and Condition table
      PE = testCase.ParamEditor;

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
      testCase.startMeasuring();
      callback_fcn(gInputs(idx));
      testCase.stopMeasuring();
      
      % Verify change in ui string
      testCase.verifyEqual(gInputs(idx).String, '666')
      % Verify change in label color
      testCase.verifyEqual(gLabels(idx).ForegroundColor, [1 0 0], ...
        'Unexpected label colour')
      % Verify change in underlying param struct
      par = strcmpi(PE.Parameters.GlobalNames,...
        strrep(gLabels(idx).String, ' ', ''));
      testCase.verifyEqual(PE.Parameters.Struct.(PE.Parameters.GlobalNames{par}), 666, ...
        'UI edit failed to update parameters struct')
            
      % Test edits to conditions table
      callback_fcn = testCase.Table.CellEditCallback;
      event.Indices = [1, 1];
      event.NewData = '0,5';
      testCase.startMeasuring();
      callback_fcn(testCase.Table, event)
      testCase.stopMeasuring();
      
      % Verify change to table value
      testCase.verifyEqual(testCase.Table.Data{1,1}, '0, 5', ...
        'Unexpected table data')
      % Verify change in underlying param struct
      value = PE.Parameters.Struct.(PE.Parameters.TrialSpecificNames{1});
      testCase.verifyEqual(value(:,1), [0;5], ...
        'Table UI failed to update parameters struct')
    end
    
  end
    
end