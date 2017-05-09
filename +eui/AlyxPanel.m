
function AlyxPanel(obj, parent)
% Makes a panel with some controls to interact with Alyx in basic ways.
% Obj must be an eui.MControl object. 
%
% TODO:
% - when making a session, put Headfix and Location in by default
% - test "stored weighings" functionality
 

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
    'String', 'Subject history', ...
    'Enable', 'off',...
    'Callback', @(src, evt)viewSubjectHistory(obj));
viewAllSubjectBtn = uicontrol('Parent', waterbox,...
    'Style', 'pushbutton', ...
    'String', 'All WR subjects', ...
    'Enable', 'off',...
    'Callback', @(src, evt)viewAllSubjects(obj));
manualWeightBtn = uicontrol('Parent', waterbox,...
    'Style', 'pushbutton', ...
    'String', 'Manual weighing', ...
    'Enable', 'off',...
    'Callback', @(src, evt)manualWeightLog(obj));
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
    'String', '0.00', ...
    'Callback', @(src, evt)changeWaterText(src, evt, obj));
giveWater = uicontrol('Parent', waterbox,...
    'Style', 'pushbutton', ...
    'String', 'Give water', ...
    'Enable', 'off',...
    'Callback', @(src, evt)giveWaterFcn(obj));
waterLeftText = bui.label('[]', waterbox);
waterbox.Widths = [100 100 100 -1 75 75 75 75];

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
                set(subjectURLbtn, 'Enable', 'on'); 
                set(sessionURLbtn, 'Enable', 'on');
                set(giveWater, 'Enable', 'on');
                set(refreshBtn, 'Enable', 'on');
                set(viewSubjectBtn, 'Enable', 'on');
                set(viewAllSubjectBtn, 'Enable', 'on');
                set(manualWeightBtn, 'Enable', 'on');
                set(loginBtn, 'String', 'Logout');
                
                obj.log('Logged into Alyx successfully as %s', username);
                
                dispWaterReq(obj);
                
                % try updating the subject selectors in other panels
                s = alyx.getData(ai, 'subjects?stock=False&alive=True');
                
                respUser = cellfun(@(x)x.responsible_user, s, 'uni', false);
                subjNames = cellfun(@(x)x.nickname, s, 'uni', false);                
                      
                thisUserSubs = sort(subjNames(strcmp(respUser, obj.AlyxUsername)));
                otherUserSubs = sort(subjNames); 
                      % note that we leave this User's mice also in
                      % otherUserSubs, in case they get confused and look
                      % there. 
                      
                newSubs = {'default', thisUserSubs{:}, otherUserSubs{:}};
                oldSubs = obj.NewExpSubject.Option;
                obj.NewExpSubject.Option = newSubs;
                if isprop(obj, 'LogSubject')
                    obj.LogSubject.Option = newSubs; % these are the ones in the weighing tab
                end
                
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
                            wobj = alyx.postData(obj.AlyxInstance, 'weighings/', d);
                            obj.log('Alyx weight posting succeeded: %.2f for %s', wobj.weight, wobj.subject);
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
            set(manualWeightBtn, 'Enable', 'off');
            obj.log('Logged out of Alyx');
            
            % return the subject selectors to their previous values 
            obj.NewExpSubject.Option = dat.listSubjects;
            
            if isprop(obj, 'LogSubject')
                obj.LogSubject.Option = obj.NewExpSubject.Option;
            end
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
                    obj.AlyxInstance.water_requirement_remaining = s.water_requirement_remaining;
                end
                
            catch me 
                d = loadjson(me.message);
                if isfield(d, 'detail') && strcmp(d.detail, 'Not found.')            
                    set(waterReqText, 'String', sprintf('Subject %s not found in alyx', thisSubj));
                end
                
            end            
        end
    end

    function changeWaterText(src, evt, obj)
        ai = obj.AlyxInstance;
        if ~isempty(ai) && isfield(ai, 'water_requirement_remaining') && ~isempty(ai.water_requirement_remaining)
            rem = ai.water_requirement_remaining;
            curr = str2double(src.String);
            set(waterLeftText, 'String', sprintf('(%.2f)', rem-curr));
        end    
    end

    function manualWeightLog(obj)
        ai = obj.AlyxInstance;
        if ~isempty(ai)            
            subj = obj.NewExpSubject.Selected;
            prompt = {sprintf('weight of %s:', subj)};
            dlg_title = 'Manual weight logging';
            num_lines = 1;
            defaultans = {'',''};
            answer = inputdlg(prompt,dlg_title,num_lines,defaultans);
            
            if isempty(answer)
                % this happens if you click cancel
                return;
            end
            
            clear d
            d.subject = subj;
            d.weight = str2double(answer);
            d.user = ai.username;
            
          try
              w = alyx.postData(ai, 'weighings/', d);
              obj.log('Alyx weight posting succeeded: %.2f for %s', w.weight, w.subject);
          catch
              obj.log('Warning: Alyx weight posting failed!');
          end
        
          
        end
    end

    function launchSessionURL(obj)
        ai = obj.AlyxInstance;
        thisSubj = obj.NewExpSubject.Selected;
        thisDate = alyx.datestr(now);
        
        % determine whether there is a session for this subj and date
        ss = alyx.getData(ai, ['sessions?subject=' thisSubj '&start_date=' datestr(now, 'yyyy-mm-dd')]);                         
        
        % if not, create one
        if isempty(ss)
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
            thisSess = ss{1};
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
            s = alyx.getData(ai, alyx.makeEndpoint(ai, ['subjects/' thisSubj]));
            subjURL = fullfile(ai.baseURL, 'admin', 'subjects', 'subject', s.id, 'change'); % this is wrong - need uuid
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
            isHydrogel = cell2mat(cellfun(@(x)hydrogelVal(x.hydrogel), s.water_administrations, 'uni', false))';

            allDates = unique([weighingDates; waterDates]);
            waterByDate = cell2mat(arrayfun(@(x)sum(waterAmounts(waterDates==x&~isHydrogel)), allDates, 'uni', false)); 
            hydrogelByDate = cell2mat(arrayfun(@(x)sum(waterAmounts(waterDates==x&isHydrogel)), allDates, 'uni', false)); 
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
        
            dat = horzcat(...
                    arrayfun(@(x)datestr(x), allDates, 'uni', false), ...
                    weightsByDate, ...
                    num2cell(horzcat(waterByDate, hydrogelByDate, waterByDate+hydrogelByDate)));            
        
            set(histTable, 'ColumnName', {'date', 'weight', 'water', 'hydrogel', 'total'}, ...
                'Data', dat(end:-1:1,:),...
            'ColumnEditable', false(1,5));
        
            histbox.Heights = [350 -1];
        end
    end

    function val = hydrogelVal(x)
        if isempty(x)
            val = false;
        else
            val = logical(x);
        end
    end

    function viewAllSubjects(obj)
        ai = obj.AlyxInstance;
        if ~isempty(ai)

            wr = alyx.getData(ai, alyx.makeEndpoint(ai, 'water-restricted-subjects'));
            
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


end