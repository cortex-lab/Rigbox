
function AlyxPanel(obj, parent)


%%
parent = figure; % for testing

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
dummy = bui.label('', waterbox); % to take up extra space, probably there is a better way to do this
isHydrogelChk = uicontrol('Parent', waterbox,...
    'Style', 'checkbox', ...
    'String', 'Hydrogel?', ...
    'HorizontalAlignment', 'right',...
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
waterbox.Widths = [-1 75 75 75];

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




%%
    function alyxLogin(obj)
        % Are we logging in or out?
        if isempty(obj.AlyxInstance) % logging in
            % attempt login
            [ai, username] = alyx.loginWindow(); % returns an instance if success, empty if you cancel
            if ~isempty(ai) % successful
                obj.AlyxInstance = ai;
                obj.AlyxUsername = username;
                set(loginText, 'String', sprintf('You are logged in as %s', username));
                set(subjectURLbtn, 'Enable', 'on');
                set(sessionURLbtn, 'Enable', 'on');
                set(giveWater, 'Enable', 'on');
                set(refreshBtn, 'Enable', 'on');
                set(loginBtn, 'String', 'Logout');
                dispWaterReq(obj);
                obj.log('Logged into Alyx successfully as %s', username);
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
            selectMouse(obj)
            obj.log('Logged out of Alyx');
        end
    end

    function giveWaterFcn(obj)
        ai = obj.AlyxInstance;
        thisSubj = obj.NewExpSubject.Selected;
        thisDate = alyx.datestr(now);
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
            s = alyx.getData(ai, alyx.makeEndpoint(ai, ['subjects/' thisSubj])); % struct with data about the subject
            if isempty(s) % didn't get any data back, so subj doesn't exist
                set(waterReqText, 'String', sprintf('Subject %s not found in alyx', thisSubj));
            else
                if isempty(s.water_requirement_remaining) % this field not being filled could probably represent multiple things...?
                    set(waterReqText, 'String', sprintf('Subject %s not on water restriction', thisSubj));
                else
                    set(waterReqText, 'String', ...
                        sprintf('Subject %s requires %.2f of %.2f today', ...
                        s.water_requirement_remaining, s.water_requirement_total, thisSubj));
                end
            end
        end
    end

    function launchSessionURL(obj)
        ai = obj.AlyxInstance;
        thisSubj = obj.NewExpSubject.Selected;
        thisDate = alyx.datestr(now);
        
        % determine whether there is a session for this subj and date
        
        % if not, create one
        
        % launch the website
        web(sessAdminURL, '-browser');
    end

    function launchSubjectURL(obj)
        ai = obj.AlyxInstance;
        if ~isempty(ai)
            thisSubj = obj.NewExpSubject.Selected;
            subjURL = fullfile(ai.baseURL, 'admin', 'subject', thisSubj);
            web(subjURL, '-browser');
        end
    end
end