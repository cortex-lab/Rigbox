classdef (SharedTestFixtures={matlab.unittest.fixtures.PathFixture(...
[fileparts(mfilename('fullpath')) '\fixtures'])})... % add 'fixtures' folder as test fixture
  Parameters_test < matlab.unittest.TestCase
  
  properties
    % Parameters object
    Parameters
    % Number of trial conditions (rows in table)
    nConditional = 6
    % Parameters structure
    ParamStruct
  end
  
  methods (TestClassSetup)
    
    function loadData(testCase)
      % Sets a test parameter structure
      % testCase.ParamStruct = exp.choiceWorldParams;
      n = testCase.nConditional;
      testCase.ParamStruct = struct(...
        'numRepeats', repmat(100,1,n),...
        'numRepeatsUnits', '#',...
        'numRepeatsDescription', 'No. of repeats of each condition',...
        'charParam', 'test',...
        'charParamUnits', 'normalised',...
        'charParamDescription', 'test char array parameter',...
        'strParam', "testStr",...
        'arrayParam', magic(n),...
        'arrayParamUnits', 'mW',...
        'logicalArrayParam', true(1,n),...
        'logicalParam', false,...
        'logicalParamUnits', 'logical',...
        'doubleParam', 3,...
        'functionParam', @(pars,rig)exp.configureChoiceExperiment(exp.ChoiceWorld,pars,rig));
    end
    
    function setupClass(testCase)     
      % Check paths file
      assert(endsWith(which('dat.paths'), fullfile('tests', 'fixtures',...
        '+dat', 'paths.m')));
      % Create stand-alone panel
      testCase.Parameters = exp.Parameters();
      testCase.fatalAssertTrue(isa(testCase.Parameters, 'exp.Parameters'))
    end
  end
    
  methods (TestMethodSetup)
    function buildParams(testCase)
      % Re-load the param structure before each test so that changes in
      % previous test don't persist
      testCase.Parameters.Struct = testCase.ParamStruct;
      testCase.fatalAssertTrue(length(testCase.Parameters.TrialSpecificNames) == 3)
      testCase.fatalAssertTrue(length(testCase.Parameters.GlobalNames) == 5)
      testCase.fatalAssertTrue(length(testCase.Parameters.Names) == 8)
    end
  end
  
  methods (Test)
    
    function test_isTrialSpecific(testCase)
      p = testCase.Parameters;
      % Verfy that array with n columns > 1 is trial specific
      testCase.verifyTrue(p.isTrialSpecific('numRepeats'))
      % Verify that array with n columns == 1 is not trial specific
      testCase.verifyTrue(~p.isTrialSpecific('doubleParam'))
      testCase.verifyTrue(~p.isTrialSpecific('charParam'))
    end
    
    function test_numTrialConditions(testCase)
      p = testCase.Parameters;
      testCase.verifyTrue(p.numTrialConditions == testCase.nConditional)
      testCase.verifyTrue(p.numTrialConditions == size(p.Struct.numRepeats,2))
    end
    
    function test_title(testCase)
      p = testCase.Parameters;
      % Test single param title
      testCase.verifyEqual(p.title('numRepeats'), 'Num repeats')
      % Test array of param titles, including those with units
      str = p.title({'numRepeats', 'charParam', 'arrayParam', 'logicalParam'});
      expected = {'Num repeats', 'Char param', 'Array param (mW)', 'Logical param'};
      testCase.verifyTrue(isequal(str, expected))
    end
    
    function test_assortForExperiment(testCase)
      p = testCase.Parameters;
      [globalParams, trialParams] = testCase.verifyWarningFree(@()p.assortForExperiment);
      testCase.verifyTrue(isstruct(globalParams))
      testCase.verifyTrue(isequal(fieldnames(globalParams), p.GlobalNames))
      testCase.verifyTrue(isequal(size(trialParams), [1 testCase.nConditional]))
      testCase.verifyTrue(isequal(fieldnames(trialParams), p.TrialSpecificNames))
    end
    
    function test_makeGlobal(testCase)
      p = testCase.Parameters;
      p.makeGlobal('numRepeats')
      testCase.verifyTrue(~p.isTrialSpecific('numRepeats'))
      testCase.verifyTrue(numel(p.Struct.numRepeats)==1)
      p.makeGlobal('arrayParam')
      expected = magic(testCase.nConditional);
      expected = expected(:,1);
      testCase.verifyTrue(isequal(p.Struct.arrayParam, expected))
      p.makeGlobal('logicalArrayParam', false)
      testCase.verifyEqual(p.Struct.logicalArrayParam, false)
      try
        p.makeGlobal('numRepeats')
        testCase.verifyTrue(false, 'Failed to throw error')
      catch ex
        testCase.verifyEqual(ex.message, '''numRepeats'' is already global')
      end
    end
    
    function test_removeConditions(testCase)
      p = testCase.Parameters;
      p.removeConditions([2,4,6]);
      % Expected result for arrayParam
      expected = magic(testCase.nConditional);
      expected = expected(:,[1,3,5]);
      
      testCase.verifyTrue(p.numTrialConditions == 3)
      testCase.verifyTrue(isequal(p.Struct.arrayParam, expected))
    end
    
    function test_description(testCase)
      p = testCase.Parameters;
      testCase.verifyEqual(p.description('numRepeats'), 'No. of repeats of each condition')
      testCase.verifyEmpty(p.description('arrayParam'))
      testCase.verifyTrue(numel(p.description({'numRepeats', 'charParam'}))==2)
    end
    
    function test_toConditionServer(testCase)
      % Test behaviour when numRepeats is conditional
      p = testCase.Parameters;
      [cs, globalParams, trialParams] = p.toConditionServer;
      testCase.verifyTrue(isa(cs, 'exp.PresetConditionServer'))
      testCase.verifyTrue(isstruct(globalParams))
      testCase.verifyTrue(isequal(fieldnames(globalParams), p.GlobalNames))
      testCase.verifyTrue(isequal(size(trialParams), [1 sum(p.Struct.numRepeats)]))
      % Verify randomised
      noneRandom = magic(testCase.nConditional);
      noneRandom = [repmat(noneRandom(:,1),1,p.Struct.numRepeats(1)) ...
        repmat(noneRandom(:,2),1,p.Struct.numRepeats(2))];
      result = [trialParams.arrayParam];
      testCase.verifyTrue(~isequal(result(:,1:size(noneRandom,2)), noneRandom), ...
        'Trial conditions likely not randomised by default')
      % Verify that numRepeats was removed
      testCase.verifyTrue(strcmp('numRepeats', setdiff(p.TrialSpecificNames,fieldnames(trialParams))))
      
      % Test behaviour when numRepeats is global
      p.makeGlobal('numRepeats', 20)
      [~, globalParams, trialParams] = p.toConditionServer;
      testCase.verifyTrue(isequal(size(trialParams), [1 20*testCase.nConditional]))
      testCase.verifyTrue(strcmp('numRepeats', setdiff(p.GlobalNames,fieldnames(globalParams))))

      % Test behaviour when randomiseConditions is set
      p.set('randomiseConditions', false, ...
        'Flag for whether to randomise trial conditions', 'logical')
      [~, ~, trialParams] = p.toConditionServer;
      result = [trialParams.arrayParam];
      noneRandom = repmat(magic(testCase.nConditional), 1, 20);
      testCase.verifyTrue(isequal(result, noneRandom), ...
        'Trial conditions randomised')
      % Test param overide
      [~, ~, trialParams] = p.toConditionServer(true);
      result = [trialParams.arrayParam];
      testCase.verifyTrue(~isequal(result, noneRandom), ...
        'Expected trial conditions to be randomised')
      
      % Test behaviour when trialParams is empty
      names = p.TrialSpecificNames;
      for i = 1:length(names); p.makeGlobal(names{i}); end
      [~, ~, trialParams] = p.toConditionServer(true);
      testCase.assertEmpty(fieldnames(trialParams))
      testCase.verifyNotEmpty(trialParams, 'Trial conditions empty')
    end
    
    function test_makeTrialSpecific(testCase)
      p = testCase.Parameters;
      % Test making simply numerical param trial specific
      p.makeTrialSpecific('doubleParam')
      testCase.verifyTrue(p.isTrialSpecific('doubleParam'))
      testCase.verifyTrue(isequal(p.Struct.doubleParam, repmat(3,1,testCase.nConditional)))
      testCase.verifyTrue(ismember('doubleParam', p.TrialSpecificNames))
      % Test making char array trial specific
      p.makeTrialSpecific('charParam')
      testCase.verifyTrue(p.isTrialSpecific('charParam'))
      testCase.verifyEqual(numel(p.Struct.charParam), testCase.nConditional)
      testCase.verifyTrue(iscell(p.Struct.charParam))
      % Test making string trial specific
      p.makeTrialSpecific('strParam')
      testCase.verifyTrue(p.isTrialSpecific('strParam'))
      testCase.verifyTrue(isequal(size(p.Struct.strParam), [1 6]))
      testCase.verifyTrue(isstring(p.Struct.strParam))
      try
        p.makeTrialSpecific('numRepeats')
        testCase.verifyTrue(false, 'Failed to throw error')
      catch ex
        testCase.verifyEqual(ex.message, '''numRepeats'' is already trial-specific')
      end
    end
    
    function test_set(testCase)
      p = testCase.Parameters;
      % Test setting simple param with units and description
      p.set('randomiseConditions', true, ...
        'Flag for whether to randomise trial conditions', 'logical')
      testCase.verifyTrue(ismember('randomiseConditions', p.GlobalNames))
      testCase.verifyTrue(p.Struct.randomiseConditions == true)
      testCase.verifyTrue(isfield(p.Struct, 'randomiseConditionsDescription'))
      testCase.verifyTrue(isfield(p.Struct, 'randomiseConditionsUnits'))
      
      % Test setting a conditional parameter
      p.set('conditionPar', eye(testCase.nConditional))
      testCase.verifyTrue(ismember('conditionPar', p.TrialSpecificNames))
      testCase.verifyTrue(isfield(p.Struct, 'conditionParDescription') ...
        && isempty(p.Struct.conditionParDescription))
      testCase.verifyTrue(~isfield(p.Struct, 'conditionParUnits'))
      
      % Test setting various arrays
      p.set('globalPar', true(testCase.nConditional, 1))
      testCase.verifyTrue(ismember('globalPar', p.GlobalNames))
      p.set('globalPar', false(1, testCase.nConditional+1))
      testCase.verifyTrue(ismember('globalPar', p.TrialSpecificNames))
    end
  end
  
end