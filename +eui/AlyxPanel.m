
function AlyxPanel(obj, parent)
% Makes a panel with some controls to interact with Alyx in basic ways.
% Obj must be an eui.MControl object. 
%
% TODO:
% - when making a session, put Headfix and Location in by default
% - get subject page launcher working
% - test "stored weighings" functionality
% - replace queries on subject and session with ones that already do the
% filtering as desired, for speed.
% - what to do about a subject that is in the database but not in /expInfo?
% Create its expInfo folder here?

%%
% parent = figure; % for testing

alyxPanel = uix.Panel('Parent', parent, 'Title', 'Alyx');
alyxbox = uiextras.VBox('Parent', alyxPanel);

loginbox = uix.HBox('Parent', alyxbox);
loginText = bui.label('Not logged in', loginbox);
loginBtn = uicontrol('Parent', loginbox,...
    'Style', 'pushbutton', ...
    'String', 'Login', ...
    'Enable', 'on',...
    'Callback', @(src, evt)alyxLogin(obj));
loginbox.Widths = [-1 75];

waterReqbox = uix.HBox('Parent', alyxbox);
waterReqText = bui.label('Log in to see water requirements', waterReqbox);
refreshBtn = uicontrol('Parent', waterReqbox,...
    'Style', 'pushbutton', ...
    'String', 'Refresh', ...
    'Enable', 'off',...
    'Callback', @(src, evt)dispWaterReq(obj));
waterReqbox.Widths = [-1 75];

waterbox = uix.HBox('Parent', alyxbox);

viewSubjectBtn = uicontrol('Parent', waterbox,...
    'Style', 'pushbutton', ...
    'String', 'View subject''s history', ...
    'Enable', 'off',...
    'Callback', @(src, evt)viewSubjectHistory(obj));
viewAllSubjectBtn = uicontrol('Parent', waterbox,...
    'Style', 'pushbutton', ...
    'String', 'View all WR subjects', ...
    'Enable', 'off',...
    'Callback', @(src, evt)viewAllSubjects(obj));
bui.label('', waterbox); % to take up empty space
isHydrogelChk = uicontrol('Parent', waterbox,...
    'Style', 'checkbox', ...
    'String', 'Hydrogel?', ...
    'HorizontalAlignment', 'right',...
    'Value', true, ...
    'Enable', 'on');
waterAmt = uicontrol('Parent', waterbox,...
    'Style', 'edit',...
    'BackgroundColor', [1 1 1],...
    'HorizontalAlignment', 'right',...
    'Enable', 'on',...
    'String', '0.00');
giveWater = uicontrol('Parent', waterbox,...
    'Style', 'pushbutton', ...
    'String', 'Give water', ...
    'Enable', 'off',...
    'Callback', @(src, evt)giveWaterFcn(obj));
waterbox.Widths = [150 150 -1 75 75 75];

launchbox = uix.HBox('Parent', alyxbox);
subjectURLbtn = uicontrol('Parent', launchbox,...
    'Style', 'pushbutton', ...
    'String', 'Launch webpage for Subject', ...
    'Enable', 'off',...
    'Callback', @(src, evt)launchSubjectURL(obj));

sessionURLbtn = uicontrol('Parent', launchbox,...
    'Style', 'pushbutton', ...
    'String', 'Launch webpage for Session', ...
    'Enable', 'off',...
    'Callback', @(src, evt)launchSessionURL(obj));



% set a callback on MControl's subject selection so that we can show water
% requirements for new mice as they are selected

obj.NewExpSubject.addlistener('SelectionChanged', @(~,~)dispWaterReq(obj));


%%
    function alyxLogin(obj)
        % Are we logging in or out?
        if isempty(obj.AlyxInstance) % logging in
            % attempt login
            [ai, username] = alyx.loginWindow(); % returns an instance if success, empty if you cancel
            if ~isempty(ai) % successful
                obj.AlyxInstance = ai;
                obj.AlyxUsername = username;
                set(loginText, 'String', sprintf('You are logged in as %s', obj.AlyxUsername));
                set(subjectURLbtn, 'Enable', 'off'); % currently this doesn't work, it's disabled permanently
                set(sessionURLbtn, 'Enable', 'on');
                set(giveWater, 'Enable', 'on');
                set(refreshBtn, 'Enable', 'on');
                set(viewSubjectBtn, 'Enable', 'on');
                set(viewAllSubjectBtn, 'Enable', 'on');
                set(loginBtn, 'String', 'Logout');
                
                obj.log('Logged into Alyx successfully as %s', username);
                
                dispWaterReq(obj);
                
                % try updating the subject selectors in other panels
                s = alyx.getData(ai, 'subjects');
                living = logical(cell2mat(cellfun(@(x)x.alive, s, 'uni', false)));
                respUser = cellfun(@(x)x.responsible_user, s, 'uni', false);
                subjNames = cellfun(@(x)x.nickname, s, 'uni', false);
                thisUserSubs = sort(subjNames(living&strcmp(respUser, obj.AlyxUsername)));
                otherUserSubs = sort(subjNames(living&~strcmp(respUser, 'charu'))); % excluding charu eliminates mice in stock. 
                      % note that we leave this User's mice also in
                      % otherUserSubs, in case they get confused and look
                      % there. 
                newSubs = {'default', thisUserSubs{:}, otherUserSubs{:}};
                oldSubs = obj.NewExpSubject.Option;
                obj.NewExpSubject.Option = newSubs;
                obj.LogSubject.Option = newSubs; % these are the ones in the weighing tab
                
                % any database subjects that weren't in the old list of
                % subjects will need a folder in expInfo.
                firstTimeSubs = newSubs(~ismember(newSubs, oldSubs));
                for fts = 1:length(firstTimeSubs)
                    thisDir = fullfile(dat.reposPath('expInfo', 'master'), firstTimeSubs{fts});
                    if ~exist(thisDir, 'dir')
                        fprintf(1, 'making expInfo directory for %s\n', firstTimeSubs{fts});
                        mkdir(thisDir);
                    end
                end
                
                % post any un-posted weighings 
                if ~isempty(obj.weighingsUnpostedToAlyx)
                    try
                        for w = 1:length(obj.weighingsUnpostedToAlyx)
                            d = obj.weighingsUnpostedToAlyx{w};
                            alyx.postData(obj.AlyxInstance, 'weighings/', d);
                            obj.log('Alyx weight posting succeeded: %.2f for %s', d.weight, d.subject);
                        end
                        obj.weighingsUnpostedToAlyx = {};                    
                    catch me 
                        obj.log('Failed to post stored weighings')
                    end
                end
                
                
            else
                obj.log('Did not log into Alyx');
            end
        else % logging out
            obj.AlyxInstance = [];
            obj.AlyxUsername = [];
            set(loginText, 'String', 'Not logged in');
            set(subjectURLbtn, 'Enable', 'off');
            set(sessionURLbtn, 'Enable', 'off');
            set(giveWater, 'Enable', 'off');
            set(refreshBtn, 'Enable', 'off');
            set(loginBtn, 'String', 'Login');
            set(viewSubjectBtn, 'Enable', 'off');
            set(viewAllSubjectBtn, 'Enable', 'off');
            obj.log('Logged out of Alyx');
            
            % return the subject selectors to their previous values 
            obj.NewExpSubject.Option = dat.listSubjects;
            obj.LogSubject.Option = obj.NewExpSubject.Option;
        end
    end

    function giveWaterFcn(obj)
        ai = obj.AlyxInstance;
        thisSubj = obj.NewExpSubject.Selected;
        thisDate = now;
        amount = str2double(get(waterAmt, 'String'));
        isHydrogel = logical(get(isHydrogelChk, 'Value'));
        
        if ~isempty(ai)
            wa = alyx.postWater(ai, thisSubj, amount, thisDate, isHydrogel);
            if ~isempty(wa) % returned us a created water administration object successfully
                if isHydrogel
                    wstr = 'Hydrogel';
                else
                    wstr = 'Water';
                end
                obj.log('%s administration of %.2f for %s posted successfully to alyx', wstr, amount, thisSubj);
            end
        end
        
        dispWaterReq(obj);
    end

    function dispWaterReq(obj)
        ai = obj.AlyxInstance;
        if isempty(ai)
            set(waterReqText, 'String', 'Log in to see water requirements');
        else
            thisSubj = obj.NewExpSubject.Selected;
            try
                s = alyx.getData(ai, alyx.makeEndpoint(ai, ['subjects/' thisSubj])); % struct with data about the subject
                
                if s.water_requirement_total==0 
                    set(waterReqText, 'String', sprintf('Subject %s not on water restriction', thisSubj));
                else
                    set(waterReqText, 'String', ...
                        sprintf('Subject %s requires %.2f of %.2f today', ...
                        thisSubj, s.water_requirement_remaining, s.water_requirement_total));
                end
                
            catch me 
                d = loadjson(me.message);
                if isfield(d, 'detail') && strcmp(d.detail, 'Not found.')            
                    set(waterReqText, 'String', sprintf('Subject %s not found in alyx', thisSubj));
                end
                
            end            
        end
    end

    function launchSessionURL(obj)
        ai = obj.AlyxInstance;
        thisSubj = obj.NewExpSubject.Selected;
        thisDate = alyx.datestr(now);
        
        % determine whether there is a session for this subj and date
        ss = alyx.getData(ai, 'sessions'); % ideally should be able to query directly here for subject and date
        subjectsPerSession = cellfun(@(x)x.subject, ss, 'uni', false);
        datesPerSession = cellfun(@(x)floor(alyx.datenum(x.start_time)), ss, 'uni', false);
        thisSessInd = find([datesPerSession{:}]==floor(now) & strcmp(subjectsPerSession, thisSubj));
                
        % if not, create one
        if isempty(thisSessInd)
            clear d
            d.subject = thisSubj;
            d.start_time = alyx.datestr(now);
            d.users = {obj.AlyxUsername};
            try
                thisSess = alyx.postData(ai, 'sessions', d);
                obj.log('New session created for %s', thisSubj);
            catch me
                obj.log('Could not create new session - cannot launch page'); 
                return
            end
            
        else
            thisSess = ss{thisSessInd};
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
        if ~isempty(ai)
            thisSubj = obj.NewExpSubject.Selected;
            subjURL = fullfile(ai.baseURL, 'admin', 'subject', thisSubj); % this is wrong - need uuid
            web(subjURL, '-browser');
        end
    end

    function viewSubjectHistory(obj)
        
        ai = obj.AlyxInstance;
        if ~isempty(ai)
            % collect the data for the table
            thisSubj = obj.NewExpSubject.Selected;
            s = alyx.getData(ai, alyx.makeEndpoint(ai, ['subjects/' thisSubj])); % struct with data about the subject
            
            weighingDates = floor(cell2mat(cellfun(@(x)alyx.datenum(x.date_time), s.weighings, 'uni', false)))';
            weights = cell2mat(cellfun(@(x)x.weight, s.weighings, 'uni', false))';
            
            waterDates = floor(cell2mat(cellfun(@(x)alyx.datenum(x.date_time), s.water_administrations, 'uni', false)))';
            waterAmounts = cell2mat(cellfun(@(x)x.water_administered, s.water_administrations, 'uni', false))';
%             isHydrogel = cellfun(@(x)x.is_hydrogel, s.water_administrations, 'uni', false);
            isHydrogel = false(size(waterAmounts));            

            allDates = unique([weighingDates; waterDates]);
            waterByDate = cell2mat(arrayfun(@(x)sum(waterAmounts(waterDates==x&~isHydrogel)), allDates, 'uni', false)); 
            weightsByDate = arrayfun(@(x)weights(find(weighingDates==x,1)), allDates, 'uni', false); % just first weighing from each date
            
            % build the figure to show it
            f = figure; % popup a new figure for this
            histbox = uix.VBox('Parent', f, 'BackgroundColor', 'w');
            
            ax = axes('Parent', histbox);
            plot(allDates(ismember(allDates,weighingDates)), [weightsByDate{ismember(allDates,weighingDates)}], '.-');
            box off;
            set(ax, 'XTickLabel', arrayfun(@(x)datestr(x, 'dd-mmm'), get(ax, 'XTick'), 'uni', false))
            ylabel('weight (g)');
            
            histTable = uitable('Parent', histbox,...
            'FontName', 'Consolas',...
            'RowName', []);
        
            set(histTable, 'ColumnName', {'date', 'weight', 'water', 'hydrogel'}, ...
                'Data', horzcat(arrayfun(@(x)datestr(x), allDates(end:-1:1), 'uni', false), weightsByDate(end:-1:1), mat2cell(waterByDate(end:-1:1), ones(size(waterByDate)))),...
            'ColumnEditable', false(1,4));
        
            histbox.Heights = [350 -1];
        end
    end

    function viewAllSubjects(obj)
        ai = obj.AlyxInstance;
        if ~isempty(ai)
            % subjects to check for being on water restriction are those in
            % the dropdown (we already did the searching for which are
            % alive and not in stock)
            subjs = obj.NewExpSubject.Option;
            subjs = unique(subjs(~strcmp(subjs, 'default')));
            subjDetails = cellfun(@(x)alyx.getData(ai, alyx.makeEndpoint(ai, ['subjects/' x])), subjs, 'uni', false);
            
            waterReqTotal = cellfun(@(x)x.water_requirement_total, subjDetails, 'uni', false);
            waterReqRemain = cellfun(@(x)x.water_requirement_remaining, subjDetails, 'uni', false);
            
            isOnRestriction = logical(cell2mat(cellfun(@(x)x>0, waterReqTotal, 'uni', false)));
            
            % build a figure to show it
            f = figure; % popup a new figure for this
            wrBox = uix.VBox('Parent', f);
            wrTable = uitable('Parent', wrBox,...
            'FontName', 'Consolas',...
            'RowName', []);
        
            htmlColor = @(colorNum)reshape(dec2hex(round(colorNum'*255),2)',1,6);
%             colorgen = @(colorNum,text) ['<html><table border=0 width=400 bgcolor=#',htmlColor(colorNum),'><TR><TD>',text,'</TD></TR> </table></html>'];
            colorgen = @(colorNum,text) ['<html><body bgcolor=#',htmlColor(colorNum),'>',text,'</body></html>'];
        
            wr = cellfun(@(x)colorgen(1-double(x>0)*[0 0.3 0.3], sprintf('%.2f',x)), waterReqRemain(isOnRestriction), 'uni', false);
            
            set(wrTable, 'ColumnName', {'Name', 'Water Required', 'Remaining Requirement'}, ...
                'Data', horzcat(subjs(isOnRestriction)', ...
                cellfun(@(x)sprintf('%.2f',x),waterReqTotal(isOnRestriction)', 'uni', false), ...
                wr'), ... 
            'ColumnEditable', false(1,3));
            
            
        end
    end


end