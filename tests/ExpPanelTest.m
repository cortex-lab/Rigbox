classdef (SharedTestFixtures={ % add 'fixtures' folder as test fixture
    matlab.unittest.fixtures.PathFixture('fixtures'),...
    matlab.unittest.fixtures.PathFixture(['fixtures' filesep 'expDefinitions'])})...
    ExpPanelTest < matlab.unittest.TestCase
  
  properties (SetAccess = protected)
    % The figure that contains the ExpPanel
    Parent
    % Handle for ExpPanel
    Panel eui.ExpPanel
    % Remote Rig object
    Remote srv.StimulusControl
    % A parameters structure
    Parameters
    % An experiment reference string
    Ref
  end
  
  properties (TestParameter)
    % Experiment type under test
    ExpType = {'Base', 'Signals'} % TODO Add tests for ChoiceWorld, etc.
  end
      
  methods (TestClassSetup)
    function setup(testCase)
      % SETUP Set up test case
      %   The following occurs during setup:
      %   1. Creating parent figure, turn off figure visability and delete
      %   on taredown.
      %   2. Set test flag to true to avoid path in test assertion error.
      %   3. Applies repos fixture and create a test subject and expRef.
      %   4. Instantiates a StimulusControl object for event listeners.
      
      % Hide figures and add teardown function to restore settings
      def = get(0,'DefaultFigureVisible');
      set(0,'DefaultFigureVisible','off');
      testCase.addTeardown(@set, 0, 'DefaultFigureVisible', def);

      % Create figure for panel
      testCase.Parent = figure();
      testCase.addTeardown(@delete, testCase.Parent)
      
      % Set INTEST flag to true
      setTestFlag(true);
      testCase.addTeardown(@setTestFlag, false)
      
      % Ensure we're using the correct test paths and add teardowns to
      % remove any folders we create
      testCase.applyFixture(ReposFixture)
      
      % Now create a single subject folder for testing the log
      subject = 'test';
      mainRepo = dat.reposPath('main', 'master');
      assert(mkdir(fullfile(mainRepo, subject)), ...
        'Failed to create subject folder')
      testCase.Ref = dat.constructExpRef(subject, now, 1);
      
      % Set up a StimulusControl object for simulating rig events
      testCase.Remote = srv.StimulusControl.create('testRig');
    end
  end
  
  methods
    function setupParams(testCase, ExpType)
      % SETUPPARAMS Set up parameters struct
      %   Create a parameters structure depending on the ExpType.
      
      switch lower(ExpType)
        case 'signals'
          % A Signals experiment without the custom ExpPanel.  Instantiates
          % the eui.SignalsExpPanel class
          testCase.Parameters = struct('type', 'custom', 'defFunction', @nop);
        case 'choiceworld'
          % ChoiceWorld experiment params.  Instantiates the
          % eui.ChoiceExpPanel class
          testCase.Parameters = exp.choiceWorldParams;
        case 'custom'
          % Signals experiment params with the expPanelFun parameter.
          % Calls the function defined in that parameter
          testCase.Parameters = exp.inferParameters(@advancedChoiceWorld);
        case 'base'
          % Instantiates the eui.ExpPanel base class
          testCase.Parameters = struct(...
            'experimentFun', @(pars, rig) nop, ...
            'type', 'unknown');
        case 'barmapping'
          % Instantiates the eui.MappingExpPanel class
          testCase.Parameters = exp.barMappingParams;
        otherwise
          testCase.Parameters = [];
      end
    end
  end
  
  methods (TestMethodTeardown)
    function clearFigure(testCase)
      % Completely reset the figure on taredown
      testCase.Parent = clf(testCase.Parent, 'reset');
    end
  end
  
  methods (Test)
    function test_live(testCase, ExpType)
      % Test the live constructor method for various experiment types.  The
      % following things are tested:
      %   1. Default update labels
      %   2. ActivateLog parameter functionality
      %   3. Comments box context menu functionality
      %   4. TODO Test comments changed callback
      %   5. TODO Check params button function
      setupParams(testCase, ExpType)
      inputs = {
        testCase.Parent;
        testCase.Ref;
        testCase.Remote;
        testCase.Parameters};
      testCase.Panel = eui.ExpPanel.live(inputs{:}, 'ActivateLog', false);
      
      testCase.fatalAssertTrue(isvalid(testCase.Panel))
      % Test the default labels have been created
      % Find all labels
      labels = findall(testCase.Parent, 'Style', 'text');
      expected = {'0', '-:--', 'Pending', 'Trial count', 'Elapsed', 'Status'};
      testCase.verifyEqual({labels.String}, expected, 'Default labels incorrect')
      comments = findall(testCase.Parent, 'Style', 'edit');
      testCase.assertEmpty(comments, 'Unexpected comments box');
      
      % Test build with log activated
      delete(testCase.Panel) % Delete previous panel
      testCase.Panel = eui.ExpPanel.live(inputs{:}, 'ActivateLog', true);
      % Check Comments label exists
      labels = findall(testCase.Parent, 'Style', 'text');
      commentsLabel = labels(strcmp({labels.String}, 'Comments'));
      testCase.assertNotEmpty(commentsLabel)
      % Check comments box exits
      comments = findall(testCase.Parent, 'Style', 'edit');
      testCase.assertNotEmpty(comments, 'Failed to create comments box');
      % Test comments box hiding
      testCase.assertTrue(strcmp(comments.Visible, 'on'))
      menuOption = commentsLabel.UIContextMenu.Children(1);
      menuOption.MenuSelectedFcn(menuOption) % Trigger menu callback
      testCase.assertTrue(strcmp(comments.Visible, 'off'), 'Failed to hide comments')
      menuOption.MenuSelectedFcn(menuOption) % Trigger menu callback
      testCase.assertTrue(strcmp(comments.Visible, 'on'), 'Failed to show comments')
    end
    
    function test_formatLabels(testCase)
      % Test the formatting of InfoField labels in eui.SignalsExpPanel when
      % the FormatLabels property is set to true.
      
      % Parameters for instantiation of eui.SignalsExpPanel class
      setupParams(testCase, 'signals')
      inputs = {
        testCase.Parent;
        testCase.Ref;
        testCase.Remote;
        testCase.Parameters};
      
      % Some events to trigger for the panel to accept signals updates
      initEvent = srv.ExpEvent('started', testCase.Ref);
      startedEvent = srv.ExpEvent('update', testCase.Ref, ...
        {'event', 'experimentStarted', clock});
      testCase.Panel = eui.ExpPanel.live(inputs{:}, 'ActivateLog', false);
      notify(testCase.Remote, 'ExpStarted', initEvent)
      notify(testCase.Remote, 'ExpUpdate', startedEvent)
      
      % Initialize the signals update event data
      data = struct(...
        'name', '', ...
        'value', 'true', ...
        'timestamp', clock);
      
      % For both states, test the label format
      for formatLabels = [false true]
        name = toStr(formatLabels);
        name(1) = upper(name(1));
        data.name = ['events.testEvent', name]; % A unique event name
        testCase.Panel.FormatLabels = formatLabels; % Set flag
        % Notify the panel of a new signals update event
        signalsEvent = srv.ExpEvent('signals', [], data);
        notify(testCase.Remote, 'ExpUpdate', signalsEvent)
        testCase.Panel.update % Process the update
        % Find the new label and verify its formatting
        labels = findobj(testCase.Parent, 'Style', 'text');
        i = (numel(labels)/2) + 1; % Controls returned as [values; labels]
        expected = iff(formatLabels, 'Test event true', data.name);
        testCase.verifyEqual(labels(i).String, expected, ...
          sprintf('Failed to format labels correctly when FormatLabels == %d', formatLabels) )
      end
    end
    
%     function test_starttime(testCase)
%       % TODO Test Start time input as input (i.e. for reconnect)
%     end
    
  end
  
end