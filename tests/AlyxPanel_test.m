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
    Subjects = {'ZM_1085'; 'ZM_1087'; 'ZM_1094'; 'ZM_1098'; 'ZM_335'; 'algernon'}
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
  
  properties (ClassSetupParameter)
    % Alyx base URL.  test is for the main branch, testDev is for the dev
    % code
    BaseURL = cellsprintf('https://%s.alyx.internationalbrainlab.org', {'test', 'testDev'});
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
    
    function setupPanel(testCase, BaseURL)
      % Check paths file
      assert(endsWith(which('dat.paths'), fullfile('fixtures','+dat','paths.m')));
      % Check temp mainRepo folder is empty.  An extra safe measure as we
      % don't won't to delete important folders by accident!
      mainRepo = dat.reposPath('main','master');
      assert(~exist(mainRepo, 'dir') || isempty(file.list(mainRepo)),...
        'Test experiment repo not empty.  Please set another path or manual empty folder');
      
      % Create local directory
      localRepo = dat.reposPath('main','local');
      if exist(localRepo, 'dir') == 0; mkdir(localRepo); end
      
      % Create config directory
      assert(mkdir(getOr(dat.paths,'rigConfig')), 'Failed to create config directory')
      
      % Set the database url
      paths.databaseURL = BaseURL;
      save(fullfile(getOr(dat.paths,'rigConfig'), 'paths'), 'paths')
      clearCBToolsCache
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
      testCase.fatalAssertEqual(testCase.Panel.AlyxInstance.BaseURL, BaseURL,...
        'Failed to correctly set database url');
      
      % Verify subject folders created
      present = ismember([{'default'}; testCase.Subjects(1:end-1)], dat.listSubjects);
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
      % Double check no figures left
      figHandles = findobj('Type', 'figure');
      if ~isempty(figHandles)
        idx = cellfun(@(n)any(strcmp(n, testCase.Subjects)),{figHandles.Name});
        close(figHandles(idx))
      end
      % Remove directories
      repos = [{getOr(dat.paths,'localAlyxQueue', ['fixtures' filesep 'alyxQ'])};...
          dat.reposPath('main'); {getOr(dat.paths, 'globalConfig')}];
      rm = @(repo)assert(rmdir(repo, 's'), 'Failed to remove test repo %s', repo);
      cellfun(@(repo)iff(exist(repo,'dir') == 7, @()rm(repo), @()nop), repos);
    end
  end
  
  methods (TestMethodTeardown)
    function methodTaredown(testCase)
      % Ensure still logged in
      if ~testCase.Panel.AlyxInstance.IsLoggedIn
        testCase.Panel.login('test_user', 'TapetesBloc18');
        testCase.fatalAssertTrue(testCase.Panel.AlyxInstance.IsLoggedIn,...
          'Failed to log into Alyx');
      end
      % Ensure local Alyx queue set up
      alyxQ = getOr(dat.paths,'localAlyxQueue', ['fixtures' filesep 'alyxQ']);
      testCase.resetQueue(alyxQ);
      % Close any figures opened during the test
      if ~isempty(testCase.Figure) && isvalid(testCase.Figure)
        close(testCase.Figure)
      end
      % Close any open file ids
      fclose('all');
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
        expected = testCase.GraphData{i};
        testCase.verifyEqual(xData(:,1:size(expected{1},2)), expected{1});
        testCase.verifyEqual(yData(:,1:size(expected{2},2)), expected{2});
      end
    end
    
    function test_viewAllSubjects(testCase)
      testCase.Panel.viewAllSubjects;
      testCase.Figure = gcf();
      child_handle = testCase.Figure.Children.Children;
      tableData = child_handle.Data;
      testCase.verifyEqual(size(tableData), [1 3], 'Unexpected number of table entries')
    end
    
    function test_dispWaterReq(testCase)
      % Set subject on water restriction
      testCase.SubjectUI.Selected = 'algernon';
      % Find label for weight
      labels = findall(testCase.Parent, 'Style', 'text');
      weight_text = labels(cellfun(@(ch)size(ch,1)==2,{labels.String}));
      button = findobj(testCase.Parent, 'String', 'Refresh');
      testCase.assertTrue(numel([weight_text button])==2, ...
        'Unable to retrieve all required UI elements');
      
      % Update weight outside of Panel
      w = testCase.Panel.AlyxInstance.postWeight(randi(35)+rand, 'algernon');
      testCase.assertNotEmpty(w, 'Failed to update Alyx')
      
      prev = weight_text.String(2,:);
      button.Callback(); % Hit refresh
      new = weight_text.String(2,:);
      
      testCase.verifyTrue(~strcmp(prev, new), 'Failed to retrieve new data')
      
      % Test non-existent subject string
      testCase.SubjectUI.Selected = testCase.SubjectUI.Option{1}; % default
      testCase.verifyEqual(weight_text.String, 'Subject default not on water restriction', ...
        'Failed to update string for mice not on water restriction')
    end
    
    function test_launchSessionURL(testCase)
      % Test the launch of the session page in the admin Web interface
      % TODO Use DELETE to test both creating new session and viewing
      % existing
      p = testCase.Panel;
      baseURL = p.AlyxInstance.BaseURL;
      testCase.Mock.InTest = true;
      testCase.Mock.UseDefaults = false;
      % Set new subject
      testCase.SubjectUI.Selected = testCase.SubjectUI.Option{2};
      todaySession = p.AlyxInstance.getSessions(...
        'subject', testCase.SubjectUI.Selected, 'date', now);
      
      % Add mock user response
      key = 'Would you like to create a new base session?';
      noSub = isempty(todaySession)||~isempty(todaySession.number);
      testCase.Mock.Dialogs(key) = iff(noSub, 'Yes', 'No');
      
      [status, url] = testCase.assertWarningFree(@()p.launchSessionURL);
      testCase.verifyTrue(status > -1, 'Failed to launch subject page in browser')
      if isempty(todaySession)
        expected = url;
      else
        uuid = todaySession.url(find(todaySession.url=='/', 1, 'last')+1:end);
        expected = [baseURL '/admin/actions/session/', uuid, '/change'];
      end
      
      testCase.verifyEqual(url, expected, 'Unexpected url')
      
      % todo: close tab after opening? (for `test_launchSubjectURL` as well)
    end
    
    function test_launchSubjectURL(testCase)
      % Test the launch of the subject page in the admin Web interface
      p = testCase.Panel;
      baseURL = p.AlyxInstance.BaseURL;
      % Set new subject
      testCase.SubjectUI.Selected = testCase.SubjectUI.Option{2};
      [failed, url] = p.launchSubjectURL;
      testCase.verifyTrue(~failed, 'Failed to launch subject page in browser')
      expected = [baseURL '/admin/subjects/subject/'...
        'bcefd268-68c2-4ea8-9b60-588ee4e99ebb/change'];
      testCase.verifyEqual(url, expected, 'unexpected subject page url')
    end
    
    function test_recordWeight(testCase)
      testCase.Mock.InTest = true;
      testCase.Mock.UseDefaults = false;
      % Set subject on water restriction
      testCase.SubjectUI.Selected = 'algernon';
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
      weight = 32 + rand;
      button = findobj(testCase.Parent, 'String', 'Manual weighing');
      testCase.assertNotEmpty(button, 'Unable to find button object')
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
      tic
      expected = sprintf('Weight today: %.2f', src.readGrams);
      testCase.verifyTrue(startsWith(strip(weight_text.String(2,:)), expected),...
        'Failed to update weight label value')
      
      % Test weight post when logged out
      testCase.Panel.login % log out
      testCase.Panel.recordWeight()
      
      expected = 'Warning: Weight not posted to Alyx; will be posted upon login.';
      testCase.verifyTrue(endsWith(logPanel.String{end}, expected))
      
      % Check post was saved
      savedPost = dir([getOr(dat.paths, 'localAlyxQueue') filesep '*.post']);
      testCase.assertNotEmpty(savedPost, 'Post not saved')
      
      % Ensure button reset
      while toc < 10 && ~strcmp(button.String, 'Manual weighing'); end
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
      testCase.verifyTrue(~contains(labels(2).String(1,:), 'Log in'))
            
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
      testCase.verifyEqual(labels(2).String(1,:), 'Log in to see water requirements')
    end
    
    function test_updateWeightButton(testCase)
      % As this test takes at least 10 seconds and doesn't require database
      % interaction, we will skip it unless the current panel instance is
      % using the first database URL set in the BaseURL property.
      if ~strcmp(testCase.Panel.AlyxInstance.BaseURL, testCase.BaseURL{1})
        disp('Skipping test')
        return
      end
      % Find the weight button
      button = findobj(testCase.Parent, 'String', 'Manual weighing');
      testCase.assertNotEmpty(button, 'Unable to find button object')
      callbk_fn = button.Callback;
      src.readGrams = randi(35) + rand;
      testCase.Panel.updateWeightButton(src,[])
      tic
      % Check button updated
      testCase.verifyEqual(button.String, sprintf('Record %.1fg',src.readGrams))
      testCase.verifyTrue(~isequal(button.Callback, callbk_fn), 'Callback unchanged')
      callbk_fn = button.Callback;
      
      % Check button resets
      t = 10; % Button should reset after this many seconds
      while toc <= t && ~strcmp(button.String, 'Manual weighing'); pause(0.01); end
      testCase.verifyEqual(button.String, 'Manual weighing', 'Button failed to reset')
      testCase.verifyTrue(~isequal(button.Callback, callbk_fn), 'Callback unchanged')
    end
    
    function test_giveWater(testCase)
      testCase.Panel;
      % Tolerance for water verifications, required due to rounding
      tol2dp = 0.01; % rounding to 2 d.p.
      tol1dp = 0.1; % rounding to 1 d.p.
      % Set subject on water restriction
      testCase.SubjectUI.Selected = 'algernon';
      % Ensure there's a weight for today
      testCase.Panel.recordWeight(20)
      % Find input for water
      input = findall(testCase.Parent, 'Style', 'edit');
      % Find labels
      labels = findall(testCase.Parent, 'Style', 'text');
      wtr_text = labels(cellfun(@(ch)size(ch,1)==2,{labels.String}));
      remaining = labels(cellfun(@(ch)all(size(ch)==[1 2]),{labels.String}));
      % Find Give water button
      button = findall(testCase.Parent, 'String', 'Give water');
      testCase.assertTrue(numel([input wtr_text remaining button])==4, ...
        'Unable to retrieve all required UI elements');
      
      % Test return callback
      amount = rand;
      input.String = num2str(amount);
      input.Callback(input, []);
      % Get record from Alyx
      endpnt = sprintf('water-requirement/%s?start_date=%s&end_date=%s',...
        testCase.SubjectUI.Selected, datestr(now, 'yyyy-mm-dd'),datestr(now, 'yyyy-mm-dd'));
      [vals, record] = get_test_data;
      
      testCase.verifyEqual(record.expected_water, vals(2), 'AbsTol', tol2dp, 'Expected water mismatch')
      testCase.verifyEqual(-record.excess_water, vals(1), 'AbsTol', tol1dp, 'Excess water mismatch')
      testCase.verifyEqual(record.given_water_total, vals(3), 'AbsTol', tol1dp, 'Given water mismatch')
      rem = str2double(remaining.String(2:end-1)); % Text displayed
      % The expected value uses a the required water rounded up to 2 d.p.
      expected = -(eui.AlyxPanel.round(record.excess_water, 'down') + amount);
      testCase.verifyEqual(rem, expected, 'AbsTol', tol2dp, 'Given water mismatch')
      
      % Test give water callback
      button.Callback()
      [vals, record] = get_test_data;
            
      testCase.verifyEqual(record.expected_water, vals(2), 'AbsTol', tol2dp, 'Expected water mismatch')
      testCase.verifyEqual(-record.excess_water, vals(1), 'AbsTol', tol1dp, 'Excess water mismatch')
      testCase.verifyEqual(record.given_water_total, vals(3), 'AbsTol', tol1dp, 'Given water mismatch')
      
      % Check log
      logPanel = findobj(testCase.hPanel, 'Tag', 'Logging Display');
      expected = sprintf('%.2f for "%s"', amount, testCase.SubjectUI.Selected);
      testCase.verifyTrue(contains(logPanel.String{end}, expected), 'Failed to update log')
      
      function [vals, record] = get_test_data()
        wr = testCase.Panel.AlyxInstance.getData(endpnt); % Get today's weight and water record
        record = wr.records(end);
        vals = [cell2mat(textscan(wtr_text.String(1,:), '%*s %*s %*s %.2f %*s %.2f %*s')),...
          cell2mat(textscan(wtr_text.String(2,end-10:end), '%*s %.2f'))];
        vals(isnan(vals)) = 0;
      end
    end
    
    function test_giveFutureWater(testCase)
      subject = 'ZM_335';
      testCase.SubjectUI.Selected = subject;
      % Tolerance for water verifications, permit rounding to 2 decimal
      % places; dates have a tolerance of ~15 min
      tol = 0.01; 
      
      testCase.Mock.InTest = true;
      testCase.Mock.UseDefaults = false;

      % Find Give water in future button
      button = findall(testCase.Parent, 'String', 'Give water in future');
      testCase.assertTrue(numel(button)==1, 'Unable to retrieve all required UI elements');
      
      amount = rand;
      responses = {['0 0 -1 ', num2str(amount), ' -1'], '0 0 -1'};
      testCase.Mock.Dialogs('Future Amounts') = fun.CellSeq.create(responses);
      button.Callback();
      
      % Check training day added
      toTrian = dat.loadParamProfiles('WeekendWater');
      testCase.verifyEqual(toTrian.(subject), [now+3, now+5], 'AbsTol', tol, ...
        'Failed to add training dates to saved params')
      
      % Check water posted to Alyx
      wr = testCase.Panel.AlyxInstance.getData(['subjects/', subject]);
      last = wr.water_administrations(end);
      testCase.verifyEqual(Alyx.datenum(last.date_time), now+4, 'AbsTol', tol, ...
        'Date of post incorrect')
      testCase.verifyEqual(last.water_administered, amount, 'AbsTol', tol, ...
        'Incorrect amount posted to Alyx')

      % Check log
      logPanel = findobj(testCase.hPanel, 'Tag', 'Logging Display');
      expected = contains(logPanel.String{end}, sprintf('%.2f for %s', amount, subject)) ...
        && endsWith(logPanel.String{end}, datestr(now+4, 'dddd dd mmm yyyy'));
      testCase.verifyTrue(expected, 'Water administration not logged')
      expected = endsWith(logPanel.String{end-1}, ...
        sprintf('%s marked for training on %s and %s', ...
        subject, datestr(now+3, 'dddd'), datestr(now+5, 'dddd')));
      testCase.verifyTrue(expected, 'Training days not logged')
      
      % Check training day removed
      button.Callback();
      toTrian = dat.loadParamProfiles('WeekendWater');
      testCase.verifyEqual(toTrian.(subject), now+3, 'AbsTol', tol, ...
        'Failed to add training dates to saved params')
    end
    
    function test_activeFlag(testCase)
      % Ensure that the panel is active when the DatabaseURL is added and
      % not empty
      
      % First ensure panel was set up as active
      testCase.assertNotEmpty(getOr(dat.paths, 'databaseURL'), ...
        'Expected non-empty databaseURL field in paths')
      str = iff(testCase.Panel.AlyxInstance.IsLoggedIn, 'Logout', 'Login');
      button = findobj(testCase.Parent, 'String', str);
      testCase.assertEqual(button.Enable, 'on', 'AlyxPanel not enabled')
      
      % Set invalid database URL
      baseURL = testCase.Panel.AlyxInstance.BaseURL;
      paths.databaseURL = '';
      save(fullfile(getOr(dat.paths,'rigConfig'), 'paths'), 'paths')
      testCase.assertEmpty(getOr(dat.paths,'databaseURL'),...
        'Failed to create custom paths file')
      
      testCase.Figure = figure('Name', testCase.Subjects{end});
      eui.AlyxPanel(testCase.Figure);
      
      % Reset URL
      paths.databaseURL = baseURL;
      save(fullfile(getOr(dat.paths,'rigConfig'), 'paths'), 'paths')
      clearCBToolsCache % Ensure paths are reloaded
      testCase.fatalAssertEqual(getOr(dat.paths, 'databaseURL'), baseURL, ...
        'Failed to remove databaseURL field in paths')
      button = findobj(testCase.Figure, 'String', 'Login');
      testCase.verifyEqual(button.Enable, 'off', ...
        'AlyxPanel enabled while databaseURL undefined')

      close(testCase.Figure)
    end
    
    function test_round(testCase)
      % Test round up
      testCase.verifyEqual(testCase.Panel.round(0.8437, 'up'), 0.85);
      testCase.verifyEqual(testCase.Panel.round(0.8437, 'up', 3), 0.844);
      testCase.verifyEqual(testCase.Panel.round(12.6, 'up'), 13);
      testCase.verifyEqual(testCase.Panel.round(-2.3710, 'up'), -2.3);
      
      % Test round down
      testCase.verifyEqual(testCase.Panel.round(0.8437, 'down'), 0.84);
      testCase.verifyEqual(testCase.Panel.round(0.78375, 'down', 3), 0.783);
      testCase.verifyEqual(testCase.Panel.round(12.6, 'down'), 12);
      testCase.verifyEqual(testCase.Panel.round(-2.3710, 'down'), -2.4);
      
      % Test default behaviour
      testCase.verifyEqual(testCase.Panel.round(0.8437), 0.84);
      testCase.verifyEqual(testCase.Panel.round(0.855), 0.86);
      testCase.verifyEqual(testCase.Panel.round(-0.855), -0.86);
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
