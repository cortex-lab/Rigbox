classdef AlyxPanel < handle
  % EUI.ALYXPANEL A GUI for interating with the Alyx database
  %   This class is emplyed by mc (but may also be used stand-alone) to
  %   post weights and water administations to the Alyx database.
  %
  %   eui.AlyxPanel() opens a stand-alone GUI. eui.AlyxPanel(parent)
  %   constructs the panel inside a parent object.
  %
  %   Use the login button to retrieve a token from the database.
  %   Use the subject drop-down to select the subject.
  %   Subject weights can be entered using the 'Manual weighing' button.
  %   Previous weighings and water infomation can be viewed by pressing
  %   the 'Subject history' button.
  %   Water administrations can be recorded by entering a value in ml
  %   into the text box.  Pressing return does not post the water, but
  %   updates the text to the right of the box, showing the amount of
  %   water remaining (i.e. the amount below the subject's calculated
  %   minimum requirement for that day.  The check box to the right of
  %   the text box is to indicate whether the water was liquid
  %   (unchecked) or gel (checked).  To post the water to Alyx, press the
  %   'Give water' button.
  %   To post gel for future date (for example weekend hydrogel), Click
  %   the 'Give gel in future' button and enter in all the values
  %   starting at tomorrow then the day after, etc.
  %   The 'All WR subjects' button shows the amount of water remaining
  %   today for all mice that are currently on water restriction.
  %
  %   The 'default' subject is for testing and is usually ignored.
  %
  %   See also ALYX, EUI.MCONTROL
  %
  %   2017-03 NS created
  %   2017-10 MW made into class
  properties (SetAccess = private)
    AlyxInstance = Alyx; % An Alyx object to interfacing with the database
    SubjectList % List of active subjects from database
    Subject = 'default' % The name of the currently selected subject
  end
  
  properties (Access = private)
    LoggingDisplay % Control for showing log output
    RootContainer % Handle of the uix.Panel object named 'Alyx'
    NewExpSubject % Drop-down menu subject list
    LoginText % Text displaying whether/which user is logged in
    LoginButton % Button to log in to Alyx
    WaterEntry % Text box for entering the amout of water to give
    IsHydrogel % UI checkbox indicating whether to water to be given is in gel form
    WaterRequiredText % Handle to text UI element displaying the water required
    WaterRemainingText % Handle to text UI element displaying the water remaining
    LoginTimer % Timer to keep track of how long the user has been logged in, when this expires the user is automatically logged out
    WaterRemaining % Holds the current water required for the selected subject
  end
  
  events (NotifyAccess = 'protected')
    Connected % Notified when logged in to database
    Disconnected % Notified when logged out of database
  end
  
  methods
    function obj = AlyxPanel(parent)
      % Constructor to build all the UI elements and set callbacks to
      % the relevant functions.  If a handle to parant UI object is
      % not specified, a seperate figure is created.  An optional
      % handle to a logging display panal may be provided, otherwise
      % one is created.
      
      if ~nargin % No parant object: create new figure
        f = figure('Name', 'alyx GUI',...
          'MenuBar', 'none',...
          'Toolbar', 'none',...
          'NumberTitle', 'off',...
          'Units', 'normalized',...
          'OuterPosition', [0.1 0.1 0.4 .4]);
        parent = uiextras.VBox('Parent', f,...
          'Visible', 'on');
        % subject selector
        sbox = uix.HBox('Parent', parent);
        bui.label('Select subject: ', sbox);
        obj.NewExpSubject = bui.Selector(sbox, {'default'}); % Subject dropdown box
        % set a callback on subject selection so that we can show water
        % requirements for new mice as they are selected.  This should
        % be set by any other GUI that instantiates this object (e.g.
        % MControl using this as a panel.
        obj.NewExpSubject.addlistener('SelectionChanged', @(src, evt)obj.dispWaterReq(src, evt));
      end
      
      obj.RootContainer = uix.Panel('Parent', parent, 'Title', 'Alyx');
      alyxbox = uiextras.VBox('Parent', obj.RootContainer);
      
      loginbox = uix.HBox('Parent', alyxbox);
      % Login infomation
      obj.LoginText = bui.label('Not logged in', loginbox);
      % Button to log in and out of Alyx
      obj.LoginButton = uicontrol('Parent', loginbox,...
        'Style', 'pushbutton', ...
        'String', 'Login', ...
        'Enable', 'on',...
        'Callback', @(~,~)obj.login);
      loginbox.Widths = [-1 75];
      
      waterReqbox = uix.HBox('Parent', alyxbox);
      obj.WaterRequiredText = bui.label('Log in to see water requirements', waterReqbox); % water required text
      % Button to refresh all data retrieved from Alyx
      uicontrol('Parent', waterReqbox,...
        'Style', 'pushbutton', ...
        'String', 'Refresh', ...
        'Enable', 'off',...
        'Callback', @(~,~)obj.dispWaterReq);
      waterReqbox.Widths = [-1 75];
      
      waterbox = uix.HBox('Parent', alyxbox);
      % Button to launch a dialog displaying water and weight info for a given mouse
      uicontrol('Parent', waterbox,...
        'Style', 'pushbutton', ...
        'String', 'Subject history', ...
        'Enable', 'off',...
        'Callback', @(~,~)obj.viewSubjectHistory);
      % Button to launch a dialog displaying water and weight info for all mice
      uicontrol('Parent', waterbox,...
        'Style', 'pushbutton', ...
        'String', 'All WR subjects', ...
        'Enable', 'off',...
        'Callback', @(~,~)obj.viewAllSubjects);
      % Button to open a dialog for manually submitting a mouse weight
      uicontrol('Parent', waterbox,...
        'Style', 'pushbutton', ...
        'String', 'Manual weighing', ...
        'Enable', 'off',...
        'Callback', @(~,~)obj.recordWeight);
      % Button to launch dialog for submitting gel administrations
      % for future dates
      uicontrol('Parent', waterbox,...
        'Style', 'pushbutton', ...
        'String', 'Give gel in future', ...
        'Enable', 'off',...
        'Callback', @(~,~)obj.giveFutureGel);
      % Check box to indicate whether water was gel or liquid
      obj.IsHydrogel = uicontrol('Parent', waterbox,...
        'Style', 'checkbox', ...
        'String', 'Hydrogel?', ...
        'HorizontalAlignment', 'right',...
        'Value', true, ...
        'Enable', 'off');
      % Input for submitting amount of water
      obj.WaterEntry = uicontrol('Parent', waterbox,...
        'Style', 'edit',...
        'BackgroundColor', [1 1 1],...
        'HorizontalAlignment', 'right',...
        'Enable', 'off',...
        'String', '0.00', ...
        'Callback', @(src, evt)obj.changeWaterText(src, evt));
      % Button for submitting water administration
      uicontrol('Parent', waterbox,...
        'Style', 'pushbutton', ...
        'String', 'Give water', ...
        'Enable', 'off',...
        'Callback', @(~,~)giveWater(obj));
      % Label Indicating the amount of water remaining
      obj.WaterRemainingText = bui.label('[]', waterbox);
      waterbox.Widths = [100 100 100 100 75 75 75 75];
      
      launchbox = uix.HBox('Parent', alyxbox);
      % Button for launching subject page in browser
      uicontrol('Parent', launchbox,...
        'Style', 'pushbutton', ...
        'String', 'Launch webpage for Subject', ...
        'Enable', 'off',...
        'Callback', @(~,~)obj.launchSubjectURL);
      % Button for launching (and creating) a session for a given subject in the browser
      uicontrol('Parent', launchbox,...
        'Style', 'pushbutton', ...
        'String', 'Launch webpage for Session', ...
        'Enable', 'off',...
        'Callback', @(~,~)obj.launchSessionURL);
      
      if ~nargin
        % logging message area
        obj.LoggingDisplay = uicontrol('Parent', parent, 'Style', 'listbox',...
          'Enable', 'inactive', 'String', {});
        parent.Sizes = [50 150 150];
      else
        % Use parent's logging display
        obj.LoggingDisplay = findobj('Tag', 'Logging Display');
      end
    end
    
    function delete(obj)
      % To be called before destroying AlyxPanel object.  Deletes the
      % loggin timer
      disp('AlyxPanel destructor called');
      if obj.RootContainer.isvalid; delete(obj.RootContainer); end
      if ~isempty(obj.LoginTimer) % If there is a timer object
        stop(obj.LoginTimer) % Stop the timer...
        delete(obj.LoginTimer) % ... delete it...
        obj.LoginTimer = []; % ... and remove it
      end
    end
    
    function login(obj)
      % Used both to log in and out of Alyx.  Logging means to
      % generate an Alyx token with which to send/request data.
      % Logging out does not cause the token to expire, instead the
      % token is simply deleted from this object.
      
      % Are we logging in or out?
      if ~obj.AlyxInstance.IsLoggedIn % logging in
        % attempt login
        obj.AlyxInstance.login(); % returns an instance if success, empty if you cancel
        if obj.AlyxInstance.IsLoggedIn % successful
          % Start log in timer, to automatically log out after 30
          % minutes of 'inactivity' (defined as not calling
          % dispWaterReq)
          obj.LoginTimer = timer('StartDelay', 30*60, 'TimerFcn', @(~,~)obj.login);
          start(obj.LoginTimer)
          % Enable all buttons
          set(findall(obj.RootContainer, '-property', 'Enable'), 'Enable', 'on');
          set(obj.LoginText, 'String', ['You are logged in as ', obj.AlyxInstance.User]); % display which user is logged in
          set(obj.LoginButton, 'String', 'Logout');
          
          % try updating the subject selectors in other panels
          s = obj.AlyxInstance.getData('subjects?stock=False&alive=True');
          
          respUser = cellfun(@(x)x.responsible_user, s, 'uni', false);
          subjNames = cellfun(@(x)x.nickname, s, 'uni', false);
          
          thisUserSubs = sort(subjNames(strcmp(respUser, obj.AlyxInstance.User)));
          otherUserSubs = sort(subjNames);
          % note that we leave this User's mice also in
          % otherUserSubs, in case they get confused and look
          % there.
          
          newSubs = [{'default'}, thisUserSubs, otherUserSubs];
          obj.NewExpSubject.Option = newSubs;
          obj.SubjectList = newSubs;
          
          notify(obj, 'Connected'); % Notify listeners of login
          obj.log('Logged into Alyx successfully as %s', obj.AlyxInstance.User);
          
          % any database subjects that weren't in the old list of
          % subjects will need a folder in expInfo.
          firstTimeSubs = newSubs(~ismember(newSubs, dat.listSubjects));
          for fts = 1:length(firstTimeSubs)
            thisDir = fullfile(dat.reposPath('expInfo', 'master'), firstTimeSubs{fts});
            if ~exist(thisDir, 'dir')
              fprintf(1, 'making expInfo directory for %s\n', firstTimeSubs{fts});
              mkdir(thisDir);
            end
          end
        else
          obj.log('Did not log into Alyx');
        end
      else % logging out
        obj.AlyxInstance.logout;
        if ~isempty(obj.LoginTimer) % If there is a timer object
          stop(obj.LoginTimer) % Stop the timer...
          delete(obj.LoginTimer) % ... delete it...
          obj.LoginTimer = []; % ... and remove it
        end
        set(obj.LoginText, 'String', 'Not logged in')
        % Disable all buttons
        set(findall(obj.RootContainer, '-property', 'Enable'), 'Enable', 'off')
        set(obj.LoginButton, 'Enable', 'on', 'String', 'Login') % ... except the login button
        notify(obj, 'Disconnected'); % Notify listeners of logout
        obj.log('Logged out of Alyx');
      end
    end
    
    function giveWater(obj)
      % Callback to the give water button.  Posts the value entered
      % in the text box as either liquid or gel depending on the
      % state of the 'is hydrogel' check box
      thisDate = now;
      amount = str2double(get(obj.WaterEntry, 'String'));
      isHydrogel = logical(get(obj.IsHydrogel, 'Value'));
      if obj.AlyxInstance.IsLoggedIn && amount~=0 && ~isnan(amount)
        wa = obj.AlyxInstance.postWater(obj.Subject, amount, thisDate, isHydrogel);
        if ~isempty(wa) % returned us a created water administration object successfully
          wstr = iff(isHydrogel, 'Hydrogel', 'Water');
          obj.log('%s administration of %.2f for %s posted successfully to alyx', wstr, amount, obj.Subject);
        end
      end
      % update the water required text
      dispWaterReq(obj);
    end
    
    function giveFutureGel(obj)
      % Open a dialog allowing one to input water submissions for
      % future dates
      thisDate = now;
      prompt=sprintf('Enter space-separated numbers \n[tomorrow, day after that, day after that.. etc] \nEnter 0 to skip a day');
      answer = inputdlg(prompt,'Future Gel Amounts', [1 50]);
      if isempty(answer)||~obj.AlyxInstance.IsLoggedIn
        return  % user pressed 'Close' or 'x'
      end
      amount = str2num(answer{:}); %#ok<ST2NM>
      weekendDates = thisDate + (1:length(amount));
      for d = 1:length(weekendDates)
        if amount(d) > 0
          obj.AlyxInstance.postWater(obj.Subject, amount(d), weekendDates(d), 1);
          obj.log(['Hydrogel administration of %.2f for %s posted successfully to alyx for '...
            datestr(weekendDates(d))], amount(d), obj.Subject);
        end
      end
    end
    
    function dispWaterReq(obj, src, ~)
      % Display the amount of water required by the selected subject
      % for it to reach its minimum requirement.  This function is
      % also used to update the selected subject, for example it is
      % this funtion to use as a callback to subject dropdown
      % listeners
      ai = obj.AlyxInstance;
      % Set the selected subject if it is an input
      if nargin>1; obj.Subject = src.Selected; end
      if ~ai.IsLoggedIn
        set(obj.WaterRequiredText, 'String', 'Log in to see water requirements');
        return
      end
      % Refresh the timer as the user isn't inactive
      stop(obj.LoginTimer); start(obj.LoginTimer)
      try
        s = ai.getData(ai.makeEndpoint(['subjects/' obj.Subject])); % struct with data about the subject
        if s.water_requirement_total==0
          set(obj.WaterRequiredText, 'String', sprintf('Subject %s not on water restriction', obj.Subject));
        else
          set(obj.WaterRequiredText, 'String', ...
            sprintf('Subject %s requires %.2f of %.2f today', ...
            obj.Subject, s.water_requirement_remaining, s.water_requirement_total));
          obj.WaterRemaining = s.water_requirement_remaining;
        end
      catch me
        d = loadjson(me.message);
        if isfield(d, 'detail') && strcmp(d.detail, 'Not found.')
          set(obj.WaterRequiredText, 'String', sprintf('Subject %s not found in alyx', obj.Subject));
        end
      end
    end
    
    function changeWaterText(obj, src, ~)
      % Update the panel text to show the amount of water still
      % required for the subject to reach its minimum requirement.
      % This text is updated before the value in the water text box
      % has been posted to Alyx.  For example if the user is unsure
      % how much gel over the minimum they have weighed out, pressing
      % return will display this without posting to Alyx
      %
      % See also DISPWATERREQ, GIVEWATER
      if ~obj.AlyxInstance.IsLoggedIn && ~isempty(obj.WaterRemaining)
        rem = obj.WaterRemaining;
        curr = str2double(src.String);
        set(obj.WaterRemainingText, 'String', sprintf('(%.2f)', rem-curr));
      end
    end
    
    function recordWeight(obj, weight, subject)
      % Post a subject's weight to Alyx.  If no inputs are provided,
      % create an input dialog for the user to input a weight.  If no
      % subject is provided, use this object's currently selected
      % subject.
      %
      % See also VIEWSUBJECTHISTORY, VIEWALLSUBJECTS
      ai = obj.AlyxInstance;
      if nargin < 3; subject = obj.Subject; end
      if nargin < 2
        prompt = {sprintf('weight of %s:', subject)};
        dlgTitle = 'Manual weight logging';
        numLines = 1;
        defaultAns = {'',''};
        weight = inputdlg(prompt, dlgTitle, numLines, defaultAns);
        if isempty(weight); return; end
      end
      % inputdlg returns weight as a cell, otherwise it may now be
      weight = ensureCell(weight); % ensure it's a cell
      % convert to double if weight is a string
      weight = iff(ischar(weight{1}), str2double(weight{1}), weight{1});
      try
        w = postWeight(ai, weight, subject); %FIXME: If multiple things flushed, length(w)>1
        obj.log('Alyx weight posting succeeded: %.2f for %s', w.weight, w.subject);
      catch
        if ~ai.IsLoggedIn % if not logged in, save the weight for later
          obj.log('Warning: Weight not posted to Alyx; will be posted upon login.');
        else
          obj.log('Warning: Alyx weight posting failed!');
        end
      end
      % Update weight and refresh login timer
      obj.dispWaterReq
    end
    
    function launchSessionURL(obj)
      % Launch the Webpage for the current base session in the
      % default Web browser.  If no session exists for today's date,
      % a new base session is created accordingly.
      %
      % See also LAUNCHSUBJECTURL
      ai = obj.AlyxInstance;
      % determine whether there is a session for this subj and date
      thisDate = ai.datestr(now);
      sessions = ai.getData(['sessions?type=Base&subject=' obj.Subject]);
      
      % If the date of this latest base session is not the same date
      % as today, then create a new one for today
      if isempty(sessions) || ~strcmp(sessions{end}.start_time(1:10), thisDate(1:10))
        % Ask user whether he/she wants to create new session
        % Construct a questdlg with three options
        choice = questdlg('Would you like to create a new base session?', ...
          ['No base session exists for ' datestr(now, 'yyyy-mm-dd')], ...
          'Yes','No','No');
        % Handle response
        switch choice
          case 'Yes'
            % Create our base session
            d = struct;
            d.subject = obj.Subject;
            d.procedures = {'Behavior training/tasks'};
            d.narrative = 'auto-generated session';
            d.start_time = thisDate;
            d.type = 'Base';
            
            thisSess = ai.postData('sessions', d);
            if ~isfield(thisSess,'subject') % fail
              warning('Submitted base session did not return appropriate values');
              warning('Submitted data below:');
              disp(d)
              warning('Return values below:');
              disp(thisSess)
              return
            else % success
              obj.log(['Created new base session in Alyx for ' obj.Subject]);
            end
          case 'No'
            return
        end
      else
        thisSess = sessions{end};
      end
      
      % parse the uuid from the url in the session object
      u = thisSess.url;
      uuid = u(find(u=='/', 1, 'last')+1:end);
      
      % make the admin url
      adminURL = fullfile(ai.baseURL, 'admin', 'actions', 'session', uuid, 'change');
      
      % launch the website
      web(adminURL, '-browser');
    end
    
    function launchSubjectURL(obj)
      ai = obj.AlyxInstance;
      if ~ai.IsLoggedIn
        s = ai.getData(ai.makeEndpoint(['subjects/' obj.Subject]));
        subjURL = fullfile(ai.BaseURL, 'admin', 'subjects', 'subject', s.id, 'change'); % this is wrong - need uuid
        web(subjURL, '-browser');
      end
    end
    
    function viewSubjectHistory(obj, ax)
      % View historical information about a subject.
      % Opens a new window and plots a set of weight graphs as well
      % as displaying a table with the water and weight entries for
      % the selected subject.  If an axes handle is provided, this
      % function plots a single weight graph
      
      % If not logged in or 'default' is selected, return
      if ~obj.AlyxInstance.IsLoggedIn||strcmp(obj.Subject, 'default'); return; end
      % collect the data for the table
      endpnt = sprintf('water-requirement/%s?start_date=2016-01-01&end_date=%s', obj.Subject, datestr(now, 'yyyy-mm-dd'));
      wr = obj.AlyxInstance.getData(endpnt);
      records = catStructs(wr.records, nan);
      % no weighings found
      if isempty(wr.records)
        obj.log('No weight data found for subject %s', obj.Subject);
        return
      end
      dates = cellfun(@(x)datenum(x), {records.date});
      
      % build the figure to show it
      if nargin==1
        f = figure('Name', obj.Subject, 'NumberTitle', 'off'); % popup a new figure for this
        p = get(f, 'Position');
        set(f, 'Position', [p(1) p(2) 1100 p(4)]);
        histbox = uix.HBox('Parent', f, 'BackgroundColor', 'w');
        plotBox = uix.VBox('Parent', histbox, 'BackgroundColor', 'w');
        ax = axes('Parent', plotBox);
      end
      
      plot(ax, dates, [records.weight_measured], '.-');
      hold(ax, 'on');
      plot(ax, dates, [records.weight_expected]*0.7, 'r', 'LineWidth', 2.0);
      plot(ax, dates, [records.weight_expected]*0.8, 'LineWidth', 2.0, 'Color', [244, 191, 66]/255);
      box(ax, 'off');
      if numel(dates) > 1; xlim(ax, [min(dates) max(dates)]); end
      if nargin == 1
        set(ax, 'XTickLabel', arrayfun(@(x)datestr(x, 'dd-mmm'), get(ax, 'XTick'), 'uni', false))
      else
        ax.XTickLabel = arrayfun(@(x)datestr(x, 'dd-mmm'), get(ax, 'XTick'), 'uni', false);
      end
      ylabel(ax, 'weight (g)');
      
      if nargin==1
        ax = axes('Parent', plotBox);
        plot(ax, dates, [records.weight_measured]./[records.weight_expected], '.-');
        hold(ax, 'on');
        plot(ax, dates, 0.7*ones(size(dates)), 'r', 'LineWidth', 2.0);
        plot(ax, dates, 0.8*ones(size(dates)), 'LineWidth', 2.0, 'Color', [244, 191, 66]/255);
        box(ax, 'off');
        xlim(ax, [min(dates) max(dates)]);
        set(ax, 'XTickLabel', arrayfun(@(x)datestr(x, 'dd-mmm'), get(ax, 'XTick'), 'uni', false))
        ylabel(ax, 'weight as pct (%)');
        
        axWater = axes('Parent',plotBox);
        plot(axWater, dates, [records.water_given]+[records.hydrogel_given], '.-');
        hold(axWater, 'on');
        plot(axWater, dates, [records.hydrogel_given], '.-');
        plot(axWater, dates, [records.water_given], '.-');
        plot(axWater, dates, [records.water_expected], 'r', 'LineWidth', 2.0);
        box(axWater, 'off');
        xlim(axWater, [min(dates) max(dates)]);
        set(axWater, 'XTickLabel', arrayfun(@(x)datestr(x, 'dd-mmm'), get(axWater, 'XTick'), 'uni', false))
        ylabel(axWater, 'water/hydrogel (mL)');
        
        % Create table of useful weight and water information,
        % sorted by date
        histTable = uitable('Parent', histbox,...
          'FontName', 'Consolas',...
          'RowName', []);
        weightsByDate = num2cell([records.weight_measured]);
        weightsByDate = cellfun(@(x)sprintf('%.1f', x), weightsByDate, 'uni', false);
        weightsByDate(isnan([records.weight_measured])) = {[]};
        weightPctByDate = num2cell([records.weight_measured]./[records.weight_expected]);
        weightPctByDate = cellfun(@(x)sprintf('%.1f', x*100), weightPctByDate, 'uni', false);
        weightPctByDate(isnan([records.weight_measured])) = {[]};
        
        dat = horzcat(...
          arrayfun(@(x)datestr(x), dates', 'uni', false), ...
          weightsByDate', ...
          arrayfun(@(x)sprintf('%.1f', 0.8*x), [records.weight_expected]', 'uni', false), ...
          weightPctByDate');
        waterDat = (...
          num2cell(horzcat([records.water_given]', [records.hydrogel_given]', ...
          [records.water_given]'+[records.hydrogel_given]', [records.water_expected]',...
          [records.water_given]'+[records.hydrogel_given]'-[records.water_expected]')));
        waterDat = cellfun(@(x)sprintf('%.2f', x), waterDat, 'uni', false);
        dat = horzcat(dat, waterDat);
        
        set(histTable, 'ColumnName', {'date', 'meas. weight', '80% weight', 'weight pct', 'water', 'hydrogel', 'total', 'min water', 'excess'}, ...
          'Data', dat(end:-1:1,:),...
          'ColumnEditable', false(1,5));
        histbox.Widths = [ -1 725];
      end
    end
    
    function viewAllSubjects(obj)
      ai = obj.AlyxInstance;
      if ai.IsLoggedIn
        wr = ai.getData(ai.makeEndpoint('water-restricted-subjects'));
        
        subjs = cellfun(@(x)x.nickname, wr, 'uni', false);
        waterReqTotal = cellfun(@(x)x.water_requirement_total, wr, 'uni', false);
        waterReqRemain = cellfun(@(x)x.water_requirement_remaining, wr, 'uni', false);
        
        % build a figure to show it
        f = figure; % popup a new figure for this
        wrBox = uix.VBox('Parent', f);
        wrTable = uitable('Parent', wrBox,...
          'FontName', 'Consolas',...
          'RowName', []);
        
        htmlColor = @(colorNum)reshape(dec2hex(round(colorNum'*255),2)',1,6);
        %             colorgen = @(colorNum,text) ['<html><table border=0 width=400 bgcolor=#',htmlColor(colorNum),'><TR><TD>',text,'</TD></TR> </table></html>'];
        colorgen = @(colorNum,text) ['<html><body bgcolor=#',htmlColor(colorNum),'>',text,'</body></html>'];
        
        wrdat = cellfun(@(x)colorgen(1-double(x>0)*[0 0.3 0.3], sprintf('%.2f',x)), waterReqRemain, 'uni', false);
        
        set(wrTable, 'ColumnName', {'Name', 'Water Required', 'Remaining Requirement'}, ...
          'Data', horzcat(subjs', ...
          cellfun(@(x)sprintf('%.2f',x),waterReqTotal', 'uni', false), ...
          wrdat'), ...
          'ColumnEditable', false(1,3));
      end
    end
    
    function log(obj, varargin)
      % Function for displaying timestamped information about
      % occurrences.  If the LoggingDisplay property is unset, the
      % message is printed to the command prompt.
      % log(formatSpec, A1,... An)
      %
      % See also FPRINTF
      message = sprintf(varargin{:});
      if ~isempty(obj.LoggingDisplay)
        timestamp = datestr(now, 'dd-mm-yyyy HH:MM:SS');
        str = sprintf('[%s] %s', timestamp, message);
        current = get(obj.LoggingDisplay, 'String');
        %NB: If more that one instance of MATLAB is open, we use
        %the last opened LoggingDisplay
        set(obj.LoggingDisplay(end), 'String', [current; str], 'Value', numel(current) + 1);
      else
        fprintf(message)
      end
    end
  end
  
end