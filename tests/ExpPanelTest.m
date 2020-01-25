classdef (SharedTestFixtures={ % add 'fixtures' folder as test fixture
    matlab.unittest.fixtures.PathFixture('fixtures'),...
    matlab.unittest.fixtures.PathFixture(['fixtures' filesep 'util'])})...
    ExpPanelTest < matlab.mock.TestCase
  
  properties (SetAccess = protected)
    % The figure that contains the ExpPanel
    Parent
    % Handle for ExpPanel
    Panel eui.ExpPanel
  end
    
  methods (TestClassSetup)
    function setup(testCase)
      % SETUP TODO Document
      
      % Hide figures and add teardown function to restore settings
      def = get(0,'DefaultFigureVisible');
      set(0,'DefaultFigureVisible','off');
      testCase.addTeardown(@set, 0, 'DefaultFigureVisible', def);

      % Create figure for panel
      testCase.Parent = figure();
      
      % Set INTEST flag to true
      setTestFlag(true);
      testCase.addTeardown(@setTestFlag, false)
    end
  end
  
  methods (TestMethodSetup)
    function setupPanel(testCase)
%       testCase.ExpPanel = eui.ExpPanel.live();
    end
  end
  
  methods (Test)
    function test_panel(testCase)
      % TODO Write tests for ExpPanel
    end
    
  end
  
end