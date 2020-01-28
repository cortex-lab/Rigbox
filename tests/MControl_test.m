classdef (SharedTestFixtures={ % add 'fixtures' folder as test fixture
    matlab.unittest.fixtures.PathFixture('fixtures'),...
    matlab.unittest.fixtures.PathFixture(['fixtures' filesep 'util'])})... 
  MControl_test < matlab.unittest.TestCase & matlab.mock.TestCase
  % TODO Add test to README and Contents
  properties
    % Figure visibility setting before running tests
    FigureVisibleDefault
    % MControl instance
    MC
    % Figure handle for MControl
    Figure
    % Subject name
    Subject = 'test'
    % String array of stimulus control names
    RigNames string = ["testRig", "testRig2"]
    % Mock Dialog object
    DialogMock
  end
      
  methods (TestClassSetup)
    
    function addHardware(testCase)
      % Add a mock scale object in order to simulate the use of a scale
      [rig, behaviour] = mockRig(testCase);
      scale = rig.scale; scaleBehaviour = behaviour.scale;
      % Add scale behaviours
      import matlab.mock.actions.Invoke
      when(withExactInputs(scaleBehaviour.init),Invoke(@(~)scaleInit(scale)));
      when(withAnyInputs(scaleBehaviour.readGrams), Invoke(@(~)readGrams));
      function scaleInit(obj)
        fprintf('Opened scales on "%s"\n', obj.ComPort);
        fcn = @(~,~)fun.run(@() pause(randi(2)), @() notify(obj, 'NewReading'));
        tmr = timer('Period', 2.5, 'ExecutionMode', 'fixedSpacing',...
          'BusyMode', 'drop', 'StartDelay', 5, 'Name', 'mockScale',...
          'TimerFcn', fcn(true));
        start(tmr);
      end
      
      function g = readGrams()
        range = [20 30];
        g = (range(2)-range(1)).*rand(1,1) + range(1);
      end
    end
        
    function setup(testCase)
      % Hide figures and add teardown function to restore settings
      def = get(0,'DefaultFigureVisible');
%       set(0,'DefaultFigureVisible','off'); % TODO uncomment
      testCase.addTeardown(@set, 0, 'DefaultFigureVisible', def);
      
      % Set INTEST flag to true
      setTestFlag(true);
      testCase.addTeardown(@setTestFlag, false)
      
      % Ensure we're using the correct test paths and add teardowns to
      % remove any folders we create
      testCase.applyFixture(ReposFixture)
      
      % Now create a single subject folder
      mainRepo = dat.reposPath('main', 'master');
      assert(mkdir(fullfile(mainRepo, testCase.Subject)), ...
        'Failed to create subject folder')
            
      % Save a custom path disabling Alyx
      paths.databaseURL = [];
      configDir = getOr(dat.paths, 'rigConfig');
      save(fullfile(configDir, 'paths.mat'), 'paths')
      
      % Set up rig stimulus controllers
      stimulusControllers = ...
        arrayfun(@(n) srv.StimulusControl.create(n), testCase.RigNames);
      configDir = getOr(dat.paths, 'globalConfig');
      save(fullfile(configDir, 'remote.mat'), 'stimulusControllers')
      
      % Setup dialog mocking for user input prompts
      % TODO Add method taredown reset
      testCase.DialogMock = MockDialog.instance('uint32');
      
      % Create stand-alone panel
      testCase.Figure = figure('Name', 'MC',...
        'MenuBar', 'none',...
        'Toolbar', 'none',...
        'NumberTitle', 'off',...
        'Units', 'normalized',...
        'OuterPosition', [0.1 0.1 0.8 0.8]);
      testCase.MC = eui.MControl(testCase.Figure); % TODO Make method setup
      testCase.addTeardown(@delete, testCase.Figure);
      testCase.fatalAssertTrue(isa(testCase.MC, 'eui.MControl'))
    end
    
  end
  
%   methods (TestClassTeardown)
%     function restoreFigures(testCase)
%       set(0,'DefaultFigureVisible',testCase.FigureVisibleDefault);
%       % Remove subject directories
%       rm = @(repo)assert(rmdir(repo, 's'), 'Failed to remove test repo %s', repo);
%       cellfun(@(repo)iff(exist(repo,'dir') == 7, @()rm(repo), @()nop), dat.reposPath('main'));
%       % Remove Alyx queue
%       alyxQ = getOr(dat.paths,'localAlyxQueue', ['fixtures' filesep 'alyxQ']);
%       assert(rmdir(alyxQ, 's'), 'Failed to remove test Alx queue')
%     end
%   end

    
  methods (Test)
    function test_dropdowns(testCase)
      expected = [{'default'}; ensureCell(testCase.Subject)];
      testCase.verifyEqual(testCase.MC.NewExpSubject.Option, expected, ...
        'Unexpected subject list')
      expected = cellstr(testCase.RigNames);
      testCase.verifyEqual({testCase.MC.RemoteRigs.Option.Name}, expected, ...
        'Unexpected rig list')
    end
    
    function test_remoteRigChanged(testCase)
      import matlab.unittest.constraints.EndsWithSubstring 
      % TODO Inject mock sc in setup?
      [sc, behaviour] = createMock(testCase, ?srv.StimulusControl);
      sc.Name = testCase.MC.RemoteRigs.Selected.Name; % Rename
      testCase.MC.RemoteRigs.Option = sc; % Inject mock
      
      % [sc, scBehaviour] = createMock(testCase, ...
      %   'AddedProperties', properties(srv.StimulusControl)', ...
      %   'AddedMethods', methods(srv.StimulusControl)');

%       testCase.assignOutputsWhen(withAnyInputs(behaviour.connect), []);
%       testCase.assignOutputsWhen(withAnyInputs(behaviour.disconnect), []);
%       testCase.assignOutputsWhen(get(behaviour.Status), 'connected');
      
      % Test rig connection error behaviour
      errMsg = 'Failed!';
      testCase.throwExceptionWhen(withAnyInputs(behaviour.connect), ...
        MException('Rigbox:srv:stimulusControl:Fail', errMsg))
      testCase.MC.RemoteRigs.UIControl.Callback() % Selection callback
      expected = sprintf('Could not connect to ''%s'' (%s)', sc.Name, errMsg);
      testCase.verifyThat(...
        testCase.MC.LoggingDisplay.String{end}, ... % Most recent log entry
        EndsWithSubstring(expected), ...
        'Failed to display connection error in log')

      
    end
    
    function test_parameterSets(testCase)
      testCase.MC.NewExpType.UIControl.Callback() % Trigger default param load
      testCase.DialogMock.InTest = true;
      testCase.DialogMock.UseDefaults = false;
      testCase.DialogMock.Dialogs(0) = 'test pars';
      testCase.DialogMock.Dialogs(1) = 'Yes';
      % Test saving a parameter set
      saveBtn = findobj(testCase.Figure, 'String', 'Save...');
      testCase.assertNotEmpty(saveBtn)
      saveBtn.Callback()
    end

% function test_AlyxPanel(testCase)
%   keyboard
% end
    
% function test_rigOptions(testCase)
%   keyboard
% end

%     function test_WeightLog(testCase)
%       disp(':)')
%     end
  end
end