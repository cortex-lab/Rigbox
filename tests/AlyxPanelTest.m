classdef AlyxPanelTest < matlab.unittest.TestCase
  
  properties
    % Figure visibility setting before running tests
    FigureVisibleDefault
    % AlyxPanel instance
    Panel
    % Parent container for AlyxPanel
    Parent
    % Figure handle for AlyxPanel
    hPanel
    % Figure handle for any extra figures opened during tests
    Figure
    % List of subjects returned by the test database
    Subjects = {'ZM_1085'; 'ZM_1087'; 'ZM_1094'; 'ZM_1098'; 'ZM_335'}
    % bui.Selector for setting the subject list in tests
    SubjectUI
    % Expected Y-axis labels for the viewSubjectHistory plots
    Ylabels = {'water (mL)', 'weight as pct (%)', 'weight (g)'}
    % The table data for the the viewSubjectHistory table
    TableData
    % Cell array of graph data for the the viewSubjectHistory plots.  One
    % cell per plot containing {xData, yData} arrays.
    GraphData
  end
  
  methods (TestClassSetup)
    function killFigures(testCase)
      testCase.FigureVisibleDefault = get(0,'DefaultFigureVisible');
      set(0,'DefaultFigureVisible','off');
    end
    
    function loadData(testCase)
      % Loads validation data
      %  Graph data is a cell array where each element is the graph number
      %  (1:3) and within each element is a cell of X- and Y- axis values
      %  respecively
      load('data/viewSubjectData.mat', 'tableData', 'graphData')
      testCase.TableData = tableData;
      testCase.GraphData = graphData;
    end
    
    function setupPanel(testCase)
      % Check paths file
      assert(endsWith(which('dat.paths'), fullfile('tests','+dat','paths.m')));
      % Create figure for panel
      testCase.hPanel = figure('Name', 'alyx GUI',...
        'MenuBar', 'none',...
        'Toolbar', 'none',...
        'NumberTitle', 'off',...
        'Units', 'normalized',...
        'OuterPosition', [0.1 0.1 0.4 .4]);
      % subject selector
      parent = uiextras.VBox('Parent', testCase.hPanel, 'Visible', 'on');
      sbox = uix.HBox('Parent', parent);
      bui.label('Select subject: ', sbox);
      % Subject dropdown box
      testCase.SubjectUI = bui.Selector(sbox, [{'default'}; testCase.Subjects]);
      % Logging display
      uicontrol('Parent', parent, 'Style', 'listbox',...
        'Enable', 'inactive', 'String', {}, 'Tag', 'Logging Display');
      % Create panel
      testCase.Panel = eui.AlyxPanel(parent);
      testCase.Parent = parent.Children(1);
      % Rearrange
      parent.Children = parent.Children([2,1,3]);
      parent.Sizes = [50 150 150];
      % set a callback on subject selection so that we can show water
      % requirements for new mice as they are selected.  This should
      % be set by any other GUI that instantiates this object (e.g.
      % MControl using this as a panel.
      testCase.SubjectUI.addlistener('SelectionChanged', ...
        @(src, evt)testCase.Panel.dispWaterReq(src, evt));
      
      % Set Alyx Instance and log in
      testCase.Panel.login('test_user', 'TapetesBloc18');
      testCase.fatalAssertTrue(testCase.Panel.AlyxInstance.IsLoggedIn,...
        'Failed to log into Alyx');
    end
  end
  
  methods (TestClassTeardown)
    function restoreFigures(testCase)
      set(0,'DefaultFigureVisible',testCase.FigureVisibleDefault);
      close(testCase.hPanel)
    end
  end
  
  methods (TestMethodTeardown)
    function closeFigure(testCase)
      % Close any figures opened during the test
      if ~isempty(testCase.Figure); close(testCase.Figure); end
    end
  end
  
  methods (Test)
    function test_viewSubjectHistory(testCase)
      % Post some weights for plotting
      
      % Set new subject
      testCase.SubjectUI.Selected = testCase.SubjectUI.Option{3};
      testCase.Panel.viewSubjectHistory
      testCase.Figure = gcf();
      child_handles = testCase.Figure.Children.Children;
      % Verify table data
      testCase.assertTrue(isa(child_handles(1),'matlab.ui.control.Table'));
      tableData = child_handles(1).Data;
      testCase.verifyTrue(isequal(size(tableData), [ceil(now-737146) 9]), ...
        'Unexpected table data');
      expected = testCase.TableData;
       % Remove empty days
      idx = find(strcmp(expected{1,1}, tableData(:,1)),1);
      tableData = tableData(idx:end,:);
      testCase.verifyTrue(isequal(tableData, expected), 'Unexpected table data');
      
      ax_h = child_handles(2).Children;
      testCase.assertTrue(isa(ax_h, 'matlab.graphics.axis.Axes'))
      testCase.assertTrue(length(ax_h)==3, 'Not all axes created')
      
      for i = 1:length(ax_h)
        label = testCase.Ylabels{i};
        testCase.verifyEqual(ax_h(i).YLabel.String, label);
        testCase.verifyEqual(length(ax_h(i).Children), ...
          size(testCase.GraphData{i}{1},1));
        xData = vertcat(ax_h(i).Children(:).XData);
        yData = vertcat(ax_h(i).Children(:).YData);
        testCase.verifyEqual(xData, testCase.GraphData{i}{1});
        testCase.verifyEqual(yData, testCase.GraphData{i}{2});
      end
    end
    
    function test_viewAllSubjects(testCase)
      testCase.Panel.viewAllSubjects;
      testCase.Figure = gcf();
      child_handle = testCase.Figure.Children.Children;
      tableData = child_handle.Data;
      expected = {'algernon', '0.00', '<html><body bgcolor=#FFFFFF>0.00</body></html>'};
      testCase.verifyTrue(isequal(tableData, expected));
    end
    
    function test_dispWaterReq(testCase)
      testCase.Panel;
    end
    
    function test_launchSessionURL(testCase)
      % Test the launch of the session page in the admin Web interface
      testCase.Panel;
      % Set new subject
      testCase.SubjectUI.Selected = testCase.SubjectUI.Option{2};
      testCase.assertEmpty(testCase.Panel.AlyxInstance.SessionURL)
      testCase.Panel.launchSessionURL()
    end
    
    function test_launchSubjectURL(testCase)
      testCase.Panel;
    end
    
    function test_recordWeight(testCase)
      testCase.Panel;
    end
    
    function test_login(testCase)
      % Test panel behaviour when logged in and out
      testCase.assertTrue(testCase.Panel.AlyxInstance.IsLoggedIn);
      % Check log
      logPanel = findobj(testCase.hPanel, 'Tag', 'Logging Display');
      testCase.verifyTrue(endsWith(logPanel.String{1}, 'Logged into Alyx successfully as test_user'))
      labels = findobj(testCase.Parent, 'Style', 'text');
      % Check all components enabled
      testCase.verifyEmpty(findobj(testCase.Parent, 'Enable', 'off'))
      % Check labels
      testCase.verifyEqual(labels(3).String, 'You are logged in as test_user')
      testCase.verifyTrue(~contains(labels(2).String, 'Log in'))
      
      % Log out
      testCase.Panel.login;
      testCase.assertTrue(~testCase.Panel.AlyxInstance.IsLoggedIn);
      % Check log
      testCase.verifyTrue(endsWith(logPanel.String{end}, 'Logged out of Alyx'))
      % Check all components disabled
      testCase.verifyTrue(numel(findobj(testCase.Parent, 'Enable', 'on')) <= 2,...
      'Unexpected number of enabled UI elements')
      % Check labels
      testCase.verifyEqual(labels(3).String, 'Not logged in')
      testCase.verifyEqual(labels(2).String, 'Log in to see water requirements')
    end
    
    function test_updateWeightButton(testCase)
      testCase.Panel;
    end
    
    function test_log(testCase)
      testCase.Panel;
    end
    
    function test_giveWater(testCase)
      testCase.Panel;
    end
    
    function test_giveFutureWater(testCase)
      testCase.Panel;
    end
    
    function test_changeWaterText(testCase)
      testCase.Panel;
    end
    
    function test_round(testCase)
      % Test round up
      testCase.verifyEqual(testCase.Panel.round(0.8437, 'up'), 0.85);
      testCase.verifyEqual(testCase.Panel.round(0.8437, 'up', 3), 0.844);
      testCase.verifyEqual(testCase.Panel.round(12.6, 'up'), 13);
      
      % Test round down
      testCase.verifyEqual(testCase.Panel.round(0.8437, 'down'), 0.84);
      testCase.verifyEqual(testCase.Panel.round(0.78375, 'down', 3), 0.783);
      testCase.verifyEqual(testCase.Panel.round(12.6, 'down'), 12);
      
      % Test default behaviour
      testCase.verifyEqual(testCase.Panel.round(0.8437), 0.84);
      testCase.verifyEqual(testCase.Panel.round(0.855), 0.86);
    end
    
  end
  
end