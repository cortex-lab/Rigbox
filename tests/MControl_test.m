classdef (SharedTestFixtures={ % add 'fixtures' folder as test fixture
    matlab.unittest.fixtures.PathFixture('fixtures'),...
    matlab.unittest.fixtures.PathFixture(['fixtures' filesep 'util'])})... 
  MControl_test < matlab.unittest.TestCase & matlab.mock.TestCase
  
  properties
    % Figure visibility setting before running tests
    FigureVisibleDefault
    % MControl instance
    MC
    % Figure handle for MControl
    Figure
  end
  
  properties % (Access = private)
    DevMock
  end
    
  methods (TestClassSetup)
    
    function addHardware(testCase)
      % Add a mock scale object in order to simulate the use of a scale
      testCase.DevMock = MockDevices.instance;
      % Add scale
      [scale, scaleBehavior] = createMock(testCase,?hw.WeighingScale);
      import matlab.mock.actions.Invoke
      when(withExactInputs(scaleBehavior.init),Invoke(@(~)scaleInit(scale)));
      when(withAnyInputs(scaleBehavior.readGrams), Invoke(@(~)readGrams));
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
      testCase.DevMock.Devices.scale = scale;
    end
        
    function setup(testCase)
      % Hide figures and add teardown function to restore settings
      testCase.FigureVisibleDefault = get(0,'DefaultFigureVisible');
%       set(0,'DefaultFigureVisible','off'); % TODO uncomment
      testCase.addTeardown(@set, 0,...
        'DefaultFigureVisible', testCase.FigureVisibleDefault);
      
      % Check paths file
      assert(endsWith(which('dat.paths'),...
        fullfile('tests', 'fixtures', '+dat', 'paths.m')));
      
      % Check temp mainRepo folder is empty.  An extra safe measure as we
      % don't won't to delete important folders by accident!
      mainRepo = dat.reposPath('main','master');
      assert(~exist(mainRepo, 'dir') || isempty(file.list(mainRepo)),...
        'Test experiment repo not empty.  Please set another path or manual empty folder');

      % Create stand-alone panel
      testCase.Figure = figure('Name', 'MC',...
        'MenuBar', 'none',...
        'Toolbar', 'none',...
        'NumberTitle', 'off',...
        'Units', 'normalized',...
        'OuterPosition', [0.1 0.1 0.8 0.8]);
      testCase.MC = eui.MControl(testCase.Figure);
      testCase.addTeardown(@close, testCase.Figure);
      testCase.fatalAssertTrue(isa(testCase.MC, 'eui.MControl'))
    end
    
  end
  
  methods (TestClassTeardown)
    function restoreFigures(testCase)
      set(0,'DefaultFigureVisible',testCase.FigureVisibleDefault);
      % Remove subject directories
      rm = @(repo)assert(rmdir(repo, 's'), 'Failed to remove test repo %s', repo);
      cellfun(@(repo)iff(exist(repo,'dir') == 7, @()rm(repo), @()nop), dat.reposPath('main'));
      % Remove Alyx queue
      alyxQ = getOr(dat.paths,'localAlyxQueue', ['fixtures' filesep 'alyxQ']);
      assert(rmdir(alyxQ, 's'), 'Failed to remove test Alx queue')
    end
  end

    
  methods (Test)
    function test_WeightLog(testCase)
      disp(':)')
    end
  end
end