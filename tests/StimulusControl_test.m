%STIMULUSCONTROL_TEST Tests for srv.StimulusControl and
%srv.stimulusControllers
%  TODO Create tests for remaining methods
classdef (SharedTestFixtures={ % add 'fixtures' folder as test fixture
    matlab.unittest.fixtures.PathFixture('fixtures'),...
    matlab.unittest.fixtures.PathFixture(['fixtures' filesep 'util'])})...
    StimulusControl_test < matlab.unittest.TestCase & matlab.mock.TestCase
  
  properties (SetAccess = protected)
    % An experiment reference for the test
    Ref
    % A list of StimulusControl names for testing the remote file
    RemoteNames = {'Rig1', 'Sevvan', 'Reet'}
  end
  
  methods (TestClassSetup)
    function setupFolder(testCase)
      % SETUPFOLDER Set up subject, queue and config folders for test
      %  Creates a few folders for saving parameters and hardware.  Adds
      %  teardowns for deletion of these folders.  Also creates a custom
      %  paths file to deactivate Alyx.
      %
      % TODO Make into shared fixture
      
      assert(endsWith(which('dat.paths'),...
        fullfile('tests', 'fixtures', '+dat', 'paths.m')));
      
      % Set INTEST flag to true
      testCase.setTestFlag(true)
      testCase.addTeardown(@testCase.setTestFlag, false)

      % Create a rig config folder
      configDir = getOr(dat.paths, 'rigConfig');
      assert(mkdir(configDir), 'Failed to create config directory')
      
      % Clear loadVar cache
      addTeardown(testCase, @clearCBToolsCache)
      
      % Create a remote file for one of the tests
      globalConfigDir = getOr(dat.paths, 'globalConfig');
      stimulusControllers = cellfun(@srv.StimulusControl.create, testCase.RemoteNames);
      save(fullfile(globalConfigDir, 'remote'), 'stimulusControllers')
      assert(file.exists(fullfile(globalConfigDir, 'remote.mat')))
      
      % Add teardown to remove folders
      rmFcn = @()assert(rmdir(globalConfigDir, 's'), ...
        'Failed to remove test config folder');
      addTeardown(testCase, rmFcn)
      
      % Set some default behaviours for some of the objects; create a ref
      testCase.Ref = dat.constructExpRef('test', now, randi(10000));
    end
    
  end
    
  methods (Test)
    
    function test_create(testCase)
      % Test for constructor defaults
      name = testCase.RemoteNames{1};
      sc = srv.StimulusControl.create(name);
      testCase.verifyMatches(sc.Name, name, 'Failed to set Name')
      testCase.verifyMatches(sc.Uri, ['.*',name,':',num2str(sc.DefaultPort)])
      
      uri = 'ws://rig:1428';
      sc = srv.StimulusControl.create(name, uri);
      testCase.verifyMatches(sc.Name, name, 'Failed to set Name')
      testCase.verifyEqual(sc.Uri, uri, 'Failed to set provided uri')
    end
    
    function test_errorOnFail(testCase)
      % A message array to test
      id = 'test:error:failSent';
      msg = 'Fail message';
      r = {'success', testCase.Ref, id, msg};
      
      srv.StimulusControl.errorOnFail('This is no error') % Test char input
      srv.StimulusControl.errorOnFail(r) % Test array input without fail
      r{1} = 'fail'; % Change message to fail state
      testCase.verifyError(@()srv.StimulusControl.errorOnFail(r), id, ...
        'Failed to throw error with ID')
      ex.message = [];
      r(3) = []; % Remove ID
      try srv.StimulusControl.errorOnFail(r), catch ex, end
      testCase.verifyMatches(ex.message, msg, 'Failed to throw error without ID')
    end
    
    function test_stimulusControllers(testCase)
      % Test the loading of saved StimulusControl objects via dat.paths
      sc = srv.stimulusControllers;
      testCase.verifyLength(sc, length(testCase.RemoteNames))
      testCase.verifyTrue(isa(sc, 'srv.StimulusControl'))
      testCase.verifyEqual({sc.Name}, sort(testCase.RemoteNames), ...
        'Failed to return array sorted by Name')
    end
  end
  
  methods (Static)
    function setTestFlag(TF)
      % SETTESTFLAG Set global INTEST flag
      %   Allows setting of test flag via callback function
      global INTEST
      INTEST = TF;
    end
  end
end
