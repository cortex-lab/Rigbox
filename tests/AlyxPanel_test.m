classdef (SharedTestFixtures={ % add 'fixtures' folder as test fixture
    matlab.unittest.fixtures.PathFixture('fixtures'),...
    matlab.unittest.fixtures.PathFixture(['fixtures' filesep 'util'])})... 
    AlyxPanel_test < matlab.unittest.TestCase
  
  properties
    % Figure visibility setting before running tests
    FigureVisibleDefault
    % Instance of MockDialog object
    Mock
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
      testdata = fullfile('fixtures', 'data', 'viewSubjectData.mat');
      load(testdata, 'tableData', 'graphData')
      testCase.TableData = tableData;
      testCase.GraphData = graphData;
    end
    
    function setupPanel(testCase)
      % Check paths file
      assert(endsWith(which('dat.paths'), fullfile('fixtures','+dat','paths.m')));
      % Check temp mainRepo folder is empty.  An extra safe measure as we
      % don't won't to delete important folders by accident!
      mainRepo = getOr(dat.paths, 'mainRepository');
      assert(~exist(mainRepo, 'dir') || isempty(setdiff(getOr(dir(mainRepo),'name'),{'.','..'})),...
        'Test experiment repo not empty.  Please set another path or manual empty folder');
      
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
      
      % Verify subject folders created
      present = ismember([{'default'}; testCase.Subjects], dat.listSubjects);
      testCase.verifyTrue(all(present), 'Failed to create missing subject folders')
      
      % Ensure local Alyx queue set up
      alyxQ = getOr(dat.paths,'localAlyxQueue', ['fixtures' filesep 'alyxQ']);
      testCase.resetQueue(alyxQ);
      
      % Setup dialog mocking
      testCase.Mock = MockDialog.instance('char');
    end
  end
  
  methods (TestClassTeardown)
    function restoreFigures(testCase)
      set(0,'DefaultFigureVisible',testCase.FigureVisibleDefault);
      close(testCase.hPanel)
      delete(testCase.Panel)
      % Remove subject directories
      dataRepo = getOr(dat.paths, 'mainRepository');
      assert(rmdir(dataRepo, 's'), 'Failed to remove test data directory')
      % Remove Alyx queue
      alyxQ = getOr(dat.paths,'localAlyxQueue', ['fixtures' filesep 'alyxQ']);
      assert(rmdir(alyxQ, 's'), 'Failed to remove test Alx queue')
    end
  end
  
  methods (TestMethodTeardown)
    function methodTaredown(testCase)
      % Ensure local Alyx queue set up
      alyxQ = getOr(dat.paths,'localAlyxQueue', ['fixtures' filesep 'alyxQ']);
      testCase.resetQueue(alyxQ);
      % Close any figures opened during the test
      if ~isempty(testCase.Figure); close(testCase.Figure); end
      % Reset state of dialog mock
      testCase.Mock.reset;
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
      p = testCase.Panel;
      % Set new subject
      testCase.SubjectUI.Selected = testCase.SubjectUI.Option{2};
      todaySession = p.AlyxInstance.getSessions(testCase.SubjectUI.Selected, now);
      testCase.assertEmpty(todaySession)
      
      % Add mock user response
      mockDialog = MockDialog.instance;
      mockDialog.UseDefaults = false;
      mockDialog.Dialogs(0) = 'No';
      mockDialog.Dialogs(1) = 'Yes';
      
      testCase.Panel.launchSessionURL()
    end
    
    function test_launchSubjectURL(testCase)
      % Test the launch of the subject page in the admin Web interface
      p = testCase.Panel;
      % Set new subject
      testCase.SubjectUI.Selected = testCase.SubjectUI.Option{2};
      [failed, url] = p.launchSubjectURL;
      testCase.verifyTrue(~failed, 'Failed to launch subject page in browser')
      expected = ['https:\\test.alyx.internationalbrainlab.org\admin\'...
        'subjects\subject\bcefd268-68c2-4ea8-9b60-588ee4e99ebb\change'];
      testCase.verifyEqual(url, expected, 'unexpected subject page url')
    end
    
    function test_recordWeight(testCase)
      testCase.Panel;
      testCase.Mock.InTest = true;
      testCase.Mock.UseDefaults = false;
      % Set subject on water restriction
      testCase.SubjectUI.Option{end+1} = 'algernon';
      testCase.SubjectUI.Selected = testCase.SubjectUI.Option{end};
      % Find label for weight
      labels = findall(testCase.Parent, 'Style', 'text');
      weight_text = labels(cellfun(@(ch)size(ch,1)==2,{labels.String}));
      
      % Post weight < 70 
      weight = randi(13) + rand;
      testCase.Panel.recordWeight(weight)
      expected = sprintf('Weight today: %.2f (< 70%%)', weight);
      testCase.verifyTrue(startsWith(strip(weight_text.String(2,:)), expected),...
        'Failed to update weight label value')
      testCase.verifyEqual(weight_text.ForegroundColor, [1 0 0],...
        'Failed to update weight label color')
      
      % Post weight < 80 
      weight = 16 + rand;
      testCase.Panel.recordWeight(weight)
      expected = sprintf('Weight today: %.2f (< 80%%)', weight);
      testCase.verifyTrue(startsWith(strip(weight_text.String(2,:)), expected),...
        'Failed to update weight label value')
      testCase.verifyEqual(weight_text.ForegroundColor, [.91 .41 .17],...
        'Failed to update weight label color')
      
      % Check log
      logPanel = findobj(testCase.hPanel, 'Tag', 'Logging Display');
      expected = sprintf('Alyx weight posting succeeded: %.2f for algernon', weight);
      testCase.verifyTrue(endsWith(logPanel.String{end}, expected))
      
      % Test manual weight dialog
      weight = 25 + rand;
      button = findobj(testCase.Parent, 'String', 'Manual weighing');
      testCase.assertTrue(~isempty(button), 'Unable to find button object')
      testCase.Mock.Dialogs('Manual weight logging') = num2str(weight);
      button.Callback()
      
      expected = sprintf('Alyx weight posting succeeded: %.2f for algernon', weight);
      testCase.verifyTrue(endsWith(logPanel.String{end}, expected))
      testCase.verifyEqual(weight_text.ForegroundColor, zeros(1,3),...
        'Failed to update weight label color')
      
      % Test button with weighing scale listener
      src.readGrams = randi(35) + rand;
      testCase.Panel.updateWeightButton(src,[])
      button.Callback()
      expected = sprintf('Weight today: %.2f', src.readGrams);
      testCase.verifyTrue(startsWith(strip(weight_text.String(2,:)), expected),...
        'Failed to update weight label value')
      
      % Test weight post when logged out
      testCase.Panel.login
      testCase.Panel.recordWeight()
      
      expected = 'Warning: Weight not posted to Alyx; will be posted upon login.';
      testCase.verifyTrue(endsWith(logPanel.String{end}, expected))
      
      % Check post was saved
      savedPost = dir([getOr(dat.paths, 'localAlyxQueue') filesep '*.post']);
      testCase.assertNotEmpty(savedPost, 'Post not saved')
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
      % Find the weight button
      button = findobj(testCase.Parent, 'String', 'Manual weighing');
      testCase.assertTrue(~isempty(button), 'Unable to find button object')
      callbk_fn = button.Callback;
      src.readGrams = randi(35) + rand;
      testCase.Panel.updateWeightButton(src,[])
      % Check button updated
      testCase.verifyEqual(button.String, sprintf('Record %.1fg',src.readGrams))
      testCase.verifyTrue(~isequal(button.Callback, callbk_fn), 'Callback unchanged')
      callbk_fn = button.Callback;
      
      % Check button resets
      pause(10)
      testCase.verifyEqual(button.String, 'Manual weighing', 'Button failed to reset')
      testCase.verifyTrue(~isequal(button.Callback, callbk_fn), 'Callback unchanged')
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
  
  methods (Static)    
    function resetQueue(alyxQ)
      % Create test directory if it doesn't exist
      if exist(alyxQ, 'dir') ~= 7
        mkdir(alyxQ);
      else % Delete any queued posts
        files = dir(alyxQ);
        files = {files(endsWith({files.name},{'put', 'patch', 'post'})).name};
        cellfun(@delete, fullfile(alyxQ, files))
      end
    end
  end
end