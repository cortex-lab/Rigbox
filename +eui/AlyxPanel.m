
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

waterReqbox = uix.HBox('Parent', alyxbox);
waterReqText = bui.label('Log in to see water requirements', waterReqbox);
refreshBtn = uicontrol('Parent', waterReqbox,...
    'Style', 'pushbutton', ...
    'String', 'Refresh', ...
    'Enable', 'off',...
    'Callback', @(src, evt)[]);

waterbox = uix.HBox('Parent', alyxbox);
waterAmt = uicontrol('Parent', waterbox,...
    'Style', 'edit',...
    'BackgroundColor', [1 1 1],...
    'HorizontalAlignment', 'left',...
    'Enable', 'on',...
    'String', '0.00');
isHydrogelChk = uicontrol('Parent', waterbox,...
    'Style', 'checkbox', ...
    'String', 'Hydrogel?', ...
    'Enable', 'on');
giveWater = uicontrol('Parent', waterbox,...
    'Style', 'pushbutton', ...
    'String', 'Give water', ...
    'Enable', 'off',...
    'Callback', @(src, evt)giveWaterFcn(obj));

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
        if ~isempty(wa)
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
    if ~isempty(ai)
        
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
        subjURL = fullfile(baseURL, 'admin', 'subject', thisSubj);
        web(subjURL, '-browser');
    end
end