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
        AlyxInstance % An Alyx object to interfacing with the database
        SubjectList % List of active subjects from database
        Subject = 'default' % The name of the currently selected subject
    end
    
    properties (Access = private)
        LoggingDisplay % Control for showing log output
        RootContainer % Handle of the uix.Panel object named 'Alyx'
        NewExpSubject % Drop-down menu subject list
        LoginText % Text displaying whether/which user is logged in
        LoginButton % Button to log in to Alyx
        WeightButton % Button to submit weight to Alyx
        WaterEntry % Text box for entering the amout of water to give
        WaterType % UI checkbox indicating whether to water to be given is in gel form
        WaterRequiredText % Handle to text UI element displaying the water required
        WaterRemainingText % Handle to text UI element displaying the water remaining
        LoginTimer % Timer to keep track of how long the user has been logged in, when this expires the user is automatically logged out
        WeightTimer % Timer to reset weight button text when scale no longer gives new readings
        WaterRemaining % Holds the current water required for the selected subject
    end
    
    events (NotifyAccess = 'protected')
        Connected % Notified when logged in to database
        Disconnected % Notified when logged out of database
    end
    
    methods
        function obj = AlyxPanel(parent, active)
            % Constructor to build all the UI elements and set callbacks to the
            % relevant functions.  If a handle to parant UI object is not
            % specified, a seperate figure is created.  An optional handle to a
            % logging display panal may be provided, otherwise one is created. If
            % the active flag is set to false (default is true), the panel is
            % inactive and the instance of Alyx will be set to headless.
            %
            % See also Alyx
            
            obj.AlyxInstance = Alyx('','');
            if ~nargin % No parant object: create new figure
                f = figure('Name', 'alyx GUI',...
                    'MenuBar', 'none',...
                    'Toolbar', 'none',...
                    'NumberTitle', 'off',...
                    'Units', 'normalized',...
                    'OuterPosition', [0.1 0.1 0.4 .4],...
                    'DeleteFcn', @(~,~)obj.delete);
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
            
            % Default to active AlyxPanel
            if nargin < 2; active = true; end
            
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
            
            % If active flag set as false, make Alyx headless
            if ~active
                obj.AlyxInstance.Headless = true;
                set(obj.LoginButton, 'Enable', 'off')
            end
            
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
            obj.WeightButton = uicontrol('Parent', waterbox,...
                'Style', 'pushbutton', ...
                'String', 'Manual weighing', ...
                'Enable', 'off',...
                'Callback', @(~,~)obj.recordWeight);
            % Button to launch dialog for submitting water administrations
            % for future dates
            uicontrol('Parent', waterbox,...
                'Style', 'pushbutton', ...
                'String', 'Give water in future', ...
                'Enable', 'off',...
                'Callback', @(~,~)obj.giveFutureWater);
            % Dropdown to indicate water type (sucrose, gel, etc.)
            obj.WaterType = uicontrol('Parent', waterbox,...
                'Style', 'popupmenu', ...
                'String', {'Water'}, ...
                'HorizontalAlignment', 'right',...
                'Value', 1, ...
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
            if ~isempty(obj.WeightTimer) && isvalid(obj.WeightTimer)
                stop(obj.WeightTimer) % Stop the timer...
                delete(obj.WeightTimer) % ... delete it...
                obj.WeightTimer = []; % ... and remove it
            end
        end
        
        function login(obj, varargin)
            % Used both to log in and out of Alyx.  Logging means to
            % generate an Alyx token with which to send/request data.
            % Logging out does not cause the token to expire, instead the
            % token is simply deleted from this object.
            
            % Temporarily disable the Subject Selector
            obj.NewExpSubject.UIControl.Enable = 'off';
            % Reset headless flag in case user wishes to retry connection
            obj.AlyxInstance.Headless = false;
            % Are we logging in or out?
            if ~obj.AlyxInstance.IsLoggedIn % logging in
                % attempt login
                obj.AlyxInstance = obj.AlyxInstance.login(varargin{:}); % returns an instance if success, empty if you cancel
                if obj.AlyxInstance.IsLoggedIn % successful
                    % Start log in timer, to automatically log out after 30
                    % minutes of 'inactivity' (defined as not calling
                    % dispWaterReq)
                    obj.LoginTimer = timer('StartDelay', 30*60, 'TimerFcn',...
                        @(~,~)obj.login, 'BusyMode', 'queue', 'Name', 'Login Timer');
                    start(obj.LoginTimer)
                    % Enable all buttons
                    set(findall(obj.RootContainer, '-property', 'Enable'), 'Enable', 'on');
                    set(obj.LoginText, 'ForegroundColor', 'black',...
                        'String', ['You are logged in as ', obj.AlyxInstance.User]); % display which user is logged in
                    set(obj.LoginButton, 'String', 'Logout');
                    
                    % try updating the subject selectors in other panels
                    newSubs = obj.AlyxInstance.listSubjects;
                    obj.NewExpSubject.Option = newSubs;
                    obj.SubjectList = newSubs;
                    
                    % update water type list
                    wt = obj.AlyxInstance.getData('water-type');
                    obj.WaterType.String = {wt.name};
                    
                    notify(obj, 'Connected'); % Notify listeners of login
                    obj.log('Logged into Alyx successfully as %s', obj.AlyxInstance.User);
                    
                    % any database subjects that weren't in the old list of
                    % subjects will need a folder in the main repository.
                    firstTimeSubs = newSubs(~ismember(newSubs, dat.listSubjects));
                    for fts = 1:length(firstTimeSubs)
                        thisDir = fullfile(dat.reposPath('main', 'master'), firstTimeSubs{fts});
                        if ~exist(thisDir, 'dir')
                            fprintf(1, 'making directory for %s\n', firstTimeSubs{fts});
                            mkdir(thisDir);
                        end
                    end
                elseif obj.AlyxInstance.Headless
                    % Panel inactive or login failed due to Alyx being down
                    set(findall(obj.RootContainer, '-property', 'Enable'), 'Enable', 'on');
                    set(obj.LoginText, 'ForegroundColor', [0.91, 0.41, 0.17],...
                        'String', 'Unable to reach Alyx, posts to be queued');
                    set(obj.LoginButton, 'String', 'Retry'); % Retry button
                    obj.log('Failed to reach Alyx server, please retry later');
                else
                    obj.log('Did not log into Alyx');
                end
            else % logging out
                obj.AlyxInstance = obj.AlyxInstance.logout;
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
            % Reable the Subject Selector
            obj.NewExpSubject.UIControl.Enable = 'on';
            obj.dispWaterReq()
        end
        
        function giveWater(obj)
            % Callback to the give water button.  Posts the value entered
            % in the text box as either liquid or gel depending on the
            % state of the 'is hydrogel' check box
            thisDate = now;
            amount = str2double(get(obj.WaterEntry, 'String'));
            type = obj.WaterType.String{obj.WaterType.Value};
            if obj.AlyxInstance.IsLoggedIn && amount~=0 && ~isnan(amount)
                wa = obj.AlyxInstance.postWater(obj.Subject, amount, thisDate, type);
                if ~isempty(wa) % returned us a created water administration object successfully
                    obj.log('%s administration of %.2f for "%s" posted successfully to alyx', type, amount, obj.Subject);
                end
            end
            % update the water required text
            dispWaterReq(obj);
        end
        
        function giveFutureWater(obj)
            % Open a dialog allowing one to input water submissions for
            % future dates.  If a -1 is inputted for a particular date, the
            % date is saved in the 'WeekendWater' struct of the
            % paramProfiles file.  This may be used to notify weekend staff
            % of the experimentor's intent to train on that date.  
            thisDate = now;
            waterType = obj.WaterType.String{obj.WaterType.Value};
            prompt = sprintf(['To post future ', strrep(lower(waterType), '%', '%%'), ', ',...
              'enter space-separated numbers, i.e. \n',...
              '[tomorrow, day after that, day after that.. etc] \n\n',...
              'Enter "0" to skip a day\nEnter "-1" to indicate training for that day\n']);
            amtStr = newid(prompt,'Future Amounts', [1 50]);
            if isempty(amtStr)||~obj.AlyxInstance.IsLoggedIn
                return  % user pressed 'Close' or 'x'
            end
            amt = str2num(amtStr{:}); %#ok<ST2NM> % amount of water
            futDates = thisDate + (1:length(amt)); % datenum of all input future dates
            
            futTrnDates = futDates(amt < 0); % future training dates
            if any(futTrnDates)
              dat.saveParamProfile('WeekendWater', obj.Subject, futTrnDates);
              [~,days] = weekday(futTrnDates, 'long');
              delim = iff(size(days,1) < 3, ' and ', {', ', ' and '});
              obj.log('%s marked for training on %s',...
                obj.Subject, strjoin(strtrim(string(days)), delim));
            else % If no training dates given, delete from structure
              try
                dat.delParamProfile('WeekendWater', obj.Subject);
              catch % Subject field may not exist is never marked for training
              end
            end
            
            futWtrDates = futDates(amt > 0); % future water giving dates
            amtWtrDates = amt(amt > 0); % amount of water to give on future water dates
            
            for d = 1:length(futWtrDates)
                obj.AlyxInstance.postWater(obj.Subject, amtWtrDates(d), futWtrDates(d), waterType);
                [~,day] = weekday(futWtrDates(d), 'long');
                obj.log('Water administration of %.2f for %s posted successfully to alyx for %s %s',...
                    amtWtrDates(d), obj.Subject, day, datestr(futWtrDates(d), 'dd mmm yyyy'));
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
                weight = newid(prompt, dlgTitle, numLines, defaultAns);
                if isempty(weight); return; end
            end
            % newid returns weight as a cell, otherwise it may now be
            weight = ensureCell(weight); % ensure it's a cell
            % convert to double if weight is a string
            weight = iff(ischar(weight{1}), str2double(weight{1}), weight{1});
            try
                w = postWeight(ai, weight, subject);
                obj.log('Alyx weight posting succeeded: %.2f for %s', w.weight, w.subject);
            catch ex
                if ~ai.IsLoggedIn % if not logged in, save the weight for later
                    obj.log('Warning: Weight not posted to Alyx; will be posted upon login.');
                else
                    obj.log('Warning: Alyx weight posting failed! %s', ex.message);
                end
            end
            % Update weight and refresh login timer
            obj.dispWaterReq
        end
        
        function [stat, url] = launchSessionURL(obj)
            % Launch the Webpage for the current base session in the
            % default Web browser.  If no session exists for today's date,
            % a new base session is created accordingly.
            %
            %  Outputs:
            %    stat (double) - returns the status of the operation: 
            %      0 if successful, 1 or 2 if unsuccessful.
            %    url (char) - the url for the subject page
            %
            % See also LAUNCHSUBJECTURL
            ai = obj.AlyxInstance;
            % determine whether there is a session for this subj and date
            thisDate = ai.datestr(now);
            sessions = ai.getData(['sessions?type=Base&subject=' obj.Subject]);
            stat = -1; url = [];
            
            % If the date of this latest base session is not the same date
            % as today, then create a new one for today
            if isempty(sessions) || ~strcmp(sessions(end).start_time(1:10), thisDate(1:10))
                % Ask user whether he/she wants to create new session
                % Construct a questdlg with three options
                choice = questdlg('Would you like to create a new base session?', ...
                    ['No base session exists for ' datestr(now, 'yyyy-mmm-dd')], ...
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
                        d.users = {obj.AlyxInstance.User};

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
                  otherwise
                        return
                end
            else
                thisSess = sessions(end);
            end
            
            % parse the uuid from the url in the session object
            u = thisSess.url;
            uuid = u(find(u=='/', 1, 'last')+1:end);
            
            % make the admin url
            url = [ai.BaseURL, '/admin/actions/session/', uuid, '/change'];
            
            % launch the website
            stat = web(url, '-browser');
        end
        
        function [stat, url] = launchSubjectURL(obj)
            % LAUNCHSUBJECTURL Launch the Webpage for the current subject
            %  Launches Web page in the default Web browser.  Note that the
            %  logged in state of the AlyxPanel is independent of the
            %  browser cookies, therefore you may need to log in to see the
            %  subject page.
            %
            %  Outputs:
            %    stat (double) - returns the status of the operation: 
            %      0 if successful, 1 or 2 if unsuccessful.
            %    url (char) - the url for the subject page
            %
            % See also LAUNCHSESSIONURL
            ai = obj.AlyxInstance;
            s = ai.getData(ai.makeEndpoint(['subjects/' obj.Subject]));
            url = fullfile(ai.BaseURL, 'admin', 'subjects', 'subject', s.id, 'change'); % this is wrong - need uuid
            stat = web(url, '-browser');
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
            wr = obj.AlyxInstance.getData(['water-requirement/', obj.Subject]);
            iw = iff(isempty(wr.implant_weight), 0, wr.implant_weight);
            records = catStructs(wr.records, nan);
            % no weighings found
            if isempty(wr.records)
                obj.log('No weight data found for subject %s', obj.Subject);
                return
            end
            weights = [records.weight];
            weights(isnan([records.weighing_at])) = nan;
            expected = [records.expected_weight];
            expected(expected==0|isnan(weights)) = nan;
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
            
            plot(ax, dates, weights, '.-');
            hold(ax, 'on');
            plot(ax, dates, ((expected-iw)*0.7)+iw, 'r', 'LineWidth', 2.0);
            plot(ax, dates, ((expected-iw)*0.8)+iw, 'LineWidth', 2.0, 'Color', [244, 191, 66]/255);
            box(ax, 'off');
            % Change the plot x axis limits
            maxDate = max(dates([records.is_water_restricted]|~isnan(weights)));
            if numel(dates) > 1 && ~isempty(maxDate) && min(dates) ~= maxDate
              xlim(ax, [min(dates) maxDate])
            else
              maxDate = now;
            end
            if nargin == 1
                set(ax, 'XTickLabel', arrayfun(@(x)datestr(x, 'dd-mmm'), get(ax, 'XTick'), 'uni', false))
            else
                xticks(ax, 'auto')
                ax.XTickLabel = arrayfun(@(x)datestr(x, 'dd-mmm'), get(ax, 'XTick'), 'uni', false);
            end
            ylabel(ax, 'weight (g)');
            
            if nargin==1
                ax = axes('Parent', plotBox);
                plot(ax, dates, (weights-iw)./(expected-iw), '.-');
                hold(ax, 'on');
                plot(ax, dates, 0.7*ones(size(dates)), 'r', 'LineWidth', 2.0);
                plot(ax, dates, 0.8*ones(size(dates)), 'LineWidth', 2.0, 'Color', [244, 191, 66]/255);
                box(ax, 'off');
                xlim(ax, [min(dates) maxDate]);
                set(ax, 'XTickLabel', arrayfun(@(x)datestr(x, 'dd-mmm'), get(ax, 'XTick'), 'uni', false))
                ylabel(ax, 'weight as pct (%)');
                
                axWater = axes('Parent',plotBox);
                plot(axWater, dates, obj.round([records.given_water_total], 'up'), '.-');
                hold(axWater, 'on');
                plot(axWater, dates, obj.round([records.given_water_supplement], 'down'), '.-');
                plot(axWater, dates, obj.round([records.given_water_reward], 'down'), '.-');
                plot(axWater, dates, obj.round([records.expected_water], 'up'), 'r', 'LineWidth', 2.0);
                box(axWater, 'off');
                xlim(axWater, [min(dates) maxDate]);
                set(axWater, 'XTickLabel', arrayfun(@(x)datestr(x, 'dd-mmm'), get(axWater, 'XTick'), 'uni', false))
                ylabel(axWater, 'water (mL)');
                
                % Create table of useful weight and water information,
                % sorted by date
                histTable = uitable('Parent', histbox,...
                    'FontName', 'Consolas',...
                    'RowName', []);
                weightsByDate = num2cell(weights);
                weightsByDate = cellfun(@(x)sprintf('%.1f', x), weightsByDate, 'uni', false);
                weightsByDate(isnan(weights)) = {[]};
                weightPctByDate = num2cell((weights-iw)./(expected-iw));
                weightPctByDate = cellfun(@(x)sprintf('%.1f', x*100), weightPctByDate, 'uni', false);
                weightPctByDate(isnan(weights)|~[records.is_water_restricted]) = {[]};
                
                dat = horzcat(...
                    arrayfun(@(x)datestr(x), dates', 'uni', false), ...
                    weightsByDate', ...
                    arrayfun(@(x)iff(isnan(x), [], @()sprintf('%.1f', 0.8*(x-iw)+iw)), expected', 'uni', false), ...
                    weightPctByDate');
                waterDat = (...
                    num2cell(horzcat([records.given_water_reward]', [records.given_water_supplement]', ...
                    [records.given_water_total]', [records.expected_water]',...
                    [records.given_water_total]'-[records.expected_water]')));
                waterDat = cellfun(@(x)sprintf('%.2f', x), waterDat, 'uni', false);
                waterDat(~[records.is_water_restricted],[1,3]) = {'ad lib'};
                dat = horzcat(dat, waterDat);
                
                set(histTable, 'ColumnName', {'date', 'meas. weight', '80% weight', 'weight pct', 'water', 'supplement', 'total', 'min water', 'excess'}, ...
                    'Data', dat(end:-1:1,:),...
                    'ColumnEditable', false(1,5));
                histbox.Widths = [ -1 725];
            end
        end
        
        function viewAllSubjects(obj)
            ai = obj.AlyxInstance;
            if ai.IsLoggedIn
                wr = ai.getData(ai.makeEndpoint('water-restricted-subjects'));
                
                % build a figure to show it
                f = figure('Name', 'All Water Restricted Subjects', 'NumberTitle', 'off'); % popup a new figure for this
                p = get(f, 'Position');
                set(f, 'Position', [p(1) p(2) 295, p(4)]);
                
                wrBox = uix.VBox('Parent', f);
                wrTable = uitable('Parent', wrBox,...
                    'FontName', 'Consolas',...
                    'RowName', []);
                
                htmlColor = @(colorNum)reshape(dec2hex(round(colorNum'*255),2)',1,6);
                %             colorgen = @(colorNum,text) ['<html><table border=0 width=400 bgcolor=#',htmlColor(colorNum),'><TR><TD>',text,'</TD></TR> </table></html>'];
                colorgen = @(colorNum,text) ['<html><body bgcolor=#',htmlColor(colorNum),'>',text,'</body></html>'];
                
                wrdat = cellfun(@(x)colorgen(1-double(x>0)*[0 0.3 0.3],...
                    sprintf('%.2f',obj.round(x, 'up'))), {wr.remaining_water}, 'uni', false);
                
                set(wrTable, 'ColumnName', {'Name', 'Water Required', 'Remaining Requirement'}, ...
                    'Data', horzcat({wr.nickname}', ...
                    cellfun(@(x)sprintf('%.2f',obj.round(x, 'up')),{wr.expected_water}', 'uni', false), ...
                    wrdat'), ...
                    'ColumnEditable', false(1,3));
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
                set(obj.WaterRequiredText, 'ForegroundColor', 'black',...
                    'String', 'Log in to see water requirements');
                return
            end
            % Refresh the timer as the user isn't inactive
            stop(obj.LoginTimer); start(obj.LoginTimer)
            try
                s = ai.getData('water-restricted-subjects'); % struct with data about restricted subjects
                idx = strcmp(obj.Subject, {s.nickname});
                if ~any(idx) % Subject not on water restriction
                    set(obj.WaterRequiredText, 'ForegroundColor', 'black',...
                        'String', sprintf('Subject %s not on water restriction', obj.Subject));
                else
                    % Get information on weight and water given
                    endpnt = sprintf('water-requirement/%s?start_date=%s&end_date=%s',...
                        obj.Subject, datestr(now, 'yyyy-mm-dd'),datestr(now, 'yyyy-mm-dd'));
                    wr = ai.getData(endpnt); % Get today's weight and water record
                    if ~isempty(wr.records)
                        record = wr.records(end);
                    else
                        record = struct();
                    end
                    weight = iff(isempty(record.weighing_at), NaN, record.weight); % Get today's measured weight
                    water = getOr(record, 'given_water_total', 0); % Get total water given
                    expected_weight = getOr(record, 'expected_weight', NaN);
                    % Set colour based on weight percentage
                    weight_pct = (weight-wr.implant_weight)/(expected_weight-wr.implant_weight);
                    if weight_pct < 0.7 % Mouse below 70% original weight
                        colour = 'red';
                        weight_pct = '< 70%';
                    elseif weight_pct < 0.8 % Mouse below 80% original weight
                        colour = [0.91, 0.41, 0.17]; % Orange
                        weight_pct = '< 80%';
                    else
                        colour = 'black'; % Mouse above 80% or no weight measured today
                        weight_pct = '> 80%';
                    end
                    % Round up water remaining to the near 0.01
                    remainder = obj.round(s(idx).remaining_water, 'up');
                    % Set text
                    set(obj.WaterRequiredText, 'ForegroundColor', colour, 'String', ...
                        sprintf(['Subject %s requires %.2f of %.2f today\n\t '...
                        'Weight today: %.2f (%s)    Water today: %.2f'], obj.Subject, ...
                        remainder, obj.round(s(idx).expected_water, 'up'), weight, ...
                        weight_pct, obj.round(water, 'down')));
                    % Set WaterRemaining attribute for changeWaterText callback
                    obj.WaterRemaining = remainder;
                end
            catch me
                d = me.message; %FIXME: JSON no longer returned
                if isfield(d, 'detail') && strcmp(d.detail, 'Not found.')
                    set(obj.WaterRequiredText, 'ForegroundColor', 'black',...
                        'String', sprintf('Subject %s not found in alyx', obj.Subject));
                else
                  rethrow(me)
                end
            end
        end
        
        function updateWeightButton(obj, src, ~)
            % Function for changing the text on the weight button to reflect the
            % current weight value obtained by the scale.  This function must be
            % a callback for the hw.WeighingScale NewReading event.  If a new
            % reading isn't read for 10 sec the manual weighing option is made
            % available instead.
            %
            % Example:
            %  aiPanel = eui.AlyxPanel;
            %  lh = event.listener(obj.WeighingScale, 'NewReading',...
            %     @(src,evt)aiPanel.updateWeightButton(src,evt));
            %
            % See also hw.WeighingScale, eui.MControl
            set(obj.WeightButton, 'String', sprintf('Record %.1fg', src.readGrams), 'Callback', @(~,~)obj.recordWeight(src.readGrams))
            obj.WeightTimer = timer('Name', 'Last Weight',...
                'TimerFcn', @(~,~)set(obj.WeightButton, 'String', 'Manual weighing', 'Callback', @(~,~)obj.recordWeight),...
                'StopFcn', @(src,~)delete(src), 'StartDelay', 10);
            start(obj.WeightTimer)
        end
                
    end
    
    methods (Access = protected)
        
        function changeWaterText(obj, src, ~)
            % Update the panel text to show the amount of water still
            % required for the subject to reach its minimum requirement.
            % This text is updated before the value in the water text box
            % has been posted to Alyx.  For example if the user is unsure
            % how much gel over the minimum they have weighed out, pressing
            % return will display this without posting to Alyx
            %
            % See also DISPWATERREQ, GIVEWATER
            if obj.AlyxInstance.IsLoggedIn && ~isempty(obj.WaterRemaining)
                rem = obj.WaterRemaining;
                curr = str2double(src.String);
                set(obj.WaterRemainingText, 'String', sprintf('(%.2f)', rem-curr));
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
                current = cellflat(get(obj.LoggingDisplay, 'String'));
                %NB: If more that one instance of MATLAB is open, we use
                %the last opened LoggingDisplay
                set(obj.LoggingDisplay(end), 'String', [current; str], 'Value', numel(current) + 1);
            else
                fprintf(message)
            end
        end
    end
    
    methods (Static)
        function A = round(a, direction, N)
          % ROUND Rounds a value a up or down to the nearest N s.f.
          %   Rounds a value in the specified direction to the nearest N
          %   significant figures.  The default behaviour is the same as
          %   MATLAB's builtin round function, that is to round to the
          %   nearest value.
          % 
          %   Examples:
          %     eui.AlyxPanel.round(0.8437, 'up') % 0.85
          %     eui.AlyxPanel.round(12.65, 'up', 3) % 12.6
          %     eui.AlyxPanel.round(12.6, 'down'), 12);
          %
          % See also ROUND
            if nargin < 2; direction = 'nearest'; end
            if nargin < 3; N = 2; end
            c = 10.^(N-ceil(log10(a)));
            c(c==Inf) = 0;
            switch direction
                case 'up'
                    A = ceil(a.*c)./c;
                case 'down'
                    A = floor(a.*c)./c;
                otherwise
                    A = round(a, N, 'significant');
            end
            A(a == 0) = 0;
        end
    end
end
