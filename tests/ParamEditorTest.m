classdef ParamEditorTest < matlab.unittest.TestCase
  
  properties
    % Figure visibility setting before running tests
    FigureVisibleDefault
    % ParamEditor instance
    ParamEditor
    % Figure handle for ParamEditor
    Figure
  end
  
  properties %(MethodSetupParameter)
    Parameters
  end
  
  methods (TestClassSetup)
    function killFigures(testCase)
      testCase.FigureVisibleDefault = get(0,'DefaultFigureVisible');
%       set(0,'DefaultFigureVisible','off');
    end
    
    function loadData(testCase)
      % Loads validation data
      %  Graph data is a cell array where each element is the graph number
      %  (1:3) and within each element is a cell of X- and Y- axis values
      %  respecively
%       load('data/parameters.mat', 'parameters')
      testCase.Parameters = exp.choiceWorldParams;
    end
    
    function setupEditor(testCase)
      % Check paths file
      assert(endsWith(which('dat.paths'), fullfile('tests','+dat','paths.m')));
      % Create stand-alone panel
      testCase.ParamEditor = eui.ParamEditor;
      testCase.Figure = gcf();
      testCase.fatalAssertTrue(isa(testCase.ParamEditor, 'eui.ParamEditor'))
    end
  end
  
  methods (TestClassTeardown)
    function restoreFigures(testCase)
      set(0,'DefaultFigureVisible',testCase.FigureVisibleDefault);
      close(testCase.Figure)
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
      nGlobalInput = numel(findobj(testCase.Figure, 'Style', 'checkbox', '-or', 'Style', 'edit'));
      % Find Condition Table
      conditionTable = findobj(testCase.Figure, '-property', 'ColumnName');
      % Ensure all global params have UI input and label
      testCase.fatalAssertTrue(nGlobalLabels == numel(PE.Parameters.GlobalNames))
      testCase.fatalAssertTrue(nGlobalInput == numel(PE.Parameters.GlobalNames))
      % Ensure all conditional params have column in table
      testCase.fatalAssertTrue(isequal(size(conditionTable.Data), ...
        [PE.Parameters.numTrialConditions, numel(PE.Parameters.TrialSpecificNames)]))
    end
  end
  
  methods (Test)
    function test_makeConditional(testCase)
      % Make some global params trial conditions.  This test checks that
      % the UI elements are re-rendered after making a parameter
      % conditional, and that the underlying Parameters object is also
      % affected
      PE = testCase.ParamEditor;
      % Number of global parameters: find all text labels
      gLabels = @()findobj(testCase.Figure, 'Style', 'text');
      gInputs = @()findobj(testCase.Figure, 'Style', 'checkbox', '-or', 'Style', 'edit');
      nGlobalLabels = numel(gLabels());
      nGlobalInputs = numel(gInputs());
      % Find Condition Table
      conditionTable = findobj(testCase.Figure, '-property', 'ColumnName');
      tableSz = size(conditionTable.Data);
      
      % Retrieve context menu function handle
      c = findobj(testCase.Figure, 'Text', 'Make Conditional');
      % Set the focused object to one of the parameter labels
      set(testCase.Figure, 'CurrentObject', ...
        findobj(testCase.Figure, 'String', 'rewardVolume'))
      testCase.verifyWarningFree(c.MenuSelectedFcn, ...
        'Problem making parameter conditional');
      % Verify change in UI elements
      testCase.verifyTrue(numel(gLabels()) == nGlobalLabels-1, ...
        'Global parameter UI element not removed')
      testCase.verifyTrue(numel(gInputs()) == nGlobalInputs-1, ...
        'Global parameter UI element not removed')
      testCase.verifyTrue(size(conditionTable.Data,2) == tableSz(2)+1, ...
        'Incorrect condition table')
      % Verify change in Parameters object for global
      testCase.assertTrue(numel(gLabels()) == numel(PE.Parameters.GlobalNames))
      % Verify change in Parameters object for conditional
      testCase.assertTrue(isequal(size(conditionTable.Data), ...
        [PE.Parameters.numTrialConditions, numel(PE.Parameters.TrialSpecificNames)]))
      % Verify table values are correct
      testCase.verifyTrue(isequal(conditionTable.Data(:,1), repmat({'3'}, ...
        size(conditionTable.Data,1), 1)), 'Unexpected table values')
      
      % Test behaviour when all params made conditional
      for param = gLabels()'
        % Set the focused object to one of the parameter labels
        set(testCase.Figure, 'CurrentObject', param)
        testCase.verifyWarningFree(c.MenuSelectedFcn, ...
          'Problem making parameter conditional');
      end
    end
    
    function test_paramValue2Control(testCase)
    end
    
    function test_newCondition(testCase)
    end
    
    function test_deleteCondition(testCase)
    end
    
    function test_setValues(testCase)
    end
    
    function test_globaliseParam(testCase)
    end
    
    function test_paramEdits(testCase)
    end
    
  end
  
end