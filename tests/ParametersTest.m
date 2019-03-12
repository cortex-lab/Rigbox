classdef ParametersTest < matlab.unittest.TestCase
  
  properties
    % Parameters object
    Parameters
  end
  
  properties %(MethodSetupParameter)
    % Parameters structure
    ParamStruct
  end
  
  methods (TestClassSetup)
    
    function loadData(testCase)
      % Loads validation data
      %  Graph data is a cell array where each element is the graph number
      %  (1:3) and within each element is a cell of X- and Y- axis values
      %  respecively
%       load('data/parameters.mat', 'parameters')
      testCase.ParamStruct = exp.choiceWorldParams;
    end
    
    function setupClass(testCase)
      % Check paths file
      assert(endsWith(which('dat.paths'), fullfile('tests','+dat','paths.m')));
      % Create stand-alone panel
      testCase.Parameters = exp.Parameters();
      testCase.fatalAssertTrue(isa(testCase.ParamEditor, 'exp.Parameters'))
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
    
    function test_isTrialSpecific(testCase)
    end
    
    function test_numTrialConditions(testCase)
    end
    
    function test_title(testCase)
    end
    
    function test_assortForExperiment(testCase)
    end
    
    function test_makeGlobal(testCase)
    end
    
    function test_removeConditions(testCase)
    end
    
    function test_description(testCase)
    end
    
    function test_toConditionServer(testCase)
    end
    
    function test_makeTrialSpecific(testCase)
    end
    
    function test_set(testCase)
    end
    
    function test_ui(testCase)
    end
    
  end
  
end