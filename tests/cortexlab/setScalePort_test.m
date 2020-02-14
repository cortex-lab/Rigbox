classdef (SharedTestFixtures={ % add 'fixtures' folder as test fixture
    matlab.unittest.fixtures.PathFixture(['..' filesep 'fixtures'])})...
    setScalePort_test < matlab.unittest.TestCase
    
  methods (TestClassSetup)
    function setupFolder(testCase)
      % SETUPFOLDER Set up hardware scale objects
      %  Creates a few folders for saving hardware.  Adds teardowns for
      %  deletion of these folders via ReposFixture.
      
      % Set INTEST flag to true
      setTestFlag(true);
      testCase.addTeardown(@setTestFlag, false)
      
      % Ensure we're using the correct test paths and add teardowns to
      % remove any folders we create
      testCase.applyFixture(ReposFixture)
      
      % Now create a couple of hardware files (the rigConfig folder is
      % already created in the ReposFixture setup)
      scale = hw.WeighingScale;
      hwPaths = pick(dat.paths, {'rigConfig', 'globalConfig'});
      hwPaths{2} = [hwPaths{2} filesep hostname];
      assert(mkdir(hwPaths{2}), 'Failed to create extra config path')
      
      for i = 1:length(hwPaths) % Save scale object into hardware files
        save(fullfile(hwPaths{i}, 'hardware'), 'scale');
      end
      
      addTeardown(testCase, @ClearTestCache) % Remove folders on teardown
    end
  end
  
  methods (Test)
    function test_setPort(testCase)
      % Test setting the COM port of the current rig with various input
      % types.
      
      % Test as full string
      port = 'COM3';
      s = hw.setScalePort(port);
      scale = testCase.loadScale(hostname);
      testCase.verifyEqual(s, scale, 'Failed to return saved scale obj')
      testCase.verifyEqual(scale.ComPort, port, ...
        'Failed to set COM port as full string')
      
      % Test as single char
      port = 'COM4';
      hw.setScalePort(port(end));
      scale = testCase.loadScale(hostname);
      testCase.verifyEqual(scale.ComPort, port, ...
        'Failed to set COM port as single char')
      
      % Test as numerical
      port = 'COM6';
      hw.setScalePort(str2double(port(end)));
      scale = testCase.loadScale(hostname);
      testCase.verifyEqual(scale.ComPort, port, ...
        'Failed to set COM port as double')
    end
    
    function test_rigNameInput(testCase)
      % Test setting the COM port of a specific rig with lower case COM
      % port char array
      port = 'COM6';
      [~, name] = fileparts(getOr(dat.paths, 'rigConfig'));
      hw.setScalePort(lower(port), name);
      scale = testCase.loadScale(name);
      testCase.verifyEqual(scale.ComPort, port, ...
        'Failed to set COM port as double')
    end
  end
  
  methods (Static)
    function scale = loadScale(rigName)
      % LOADSCALE Load the scale object from the hardware file for rigName
      if nargin == 0, rigName = hostname; end
      hwPath = fullfile(getOr(dat.paths, 'globalConfig'), rigName, 'hardware');
      scale = pick(load(hwPath), 'scale');
    end
  end
end