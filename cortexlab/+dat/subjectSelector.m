function [subjectName, expNum] = subjectSelector(varargin)
% function [subjectName, expNum] = subjectSelector([parentFig], [alyxInstance])
% make a popup window that will allow selection of a subject and expNum
%
% If you provide an alyxInstance, it will populate with a list of subjects
% from alyx; otherwise, from dat.listSubjects
%
% example usage:
% >> alyxInstance = Alyx.login;
% >> [subj, expNum] = subjectSelector([], alyxInstance);
%
% Created by NS 2017

subjectName = [];
expNum = 1;

f = figure();
set(f, 'MenuBar', 'none', 'Name', 'Select subject', 'NumberTitle', 'off','Resize', 'off', ...
    'WindowStyle', 'modal');
w = 300;
h = 50;

if nargin>0 && ~isempty(varargin{1})
    parentPos = get(varargin{1}, 'Position');
else
    parentPos = get(f, 'Position');    
end

newPos = [parentPos(1)+parentPos(3)/2-w/2, parentPos(2)+parentPos(4)/2-h/2, w, h];
set(f, 'Position', newPos);

txtChooseSubject = uicontrol('Style', 'text', 'Parent', f, ...
    'Position',[10 h-30 90 25], ...
    'String', 'Choose subject:', 'HorizontalAlignment', 'right');

txtChooseExpNum = uicontrol('Style', 'text', 'Parent', f, ...
    'Position',[10 h-55 90 25], ...
    'String', 'Choose exp num:', 'HorizontalAlignment', 'right');

subjectDropdown = uicontrol('Style', 'popupmenu', 'Parent', f, ...
    'Position',[110 h-25 90 25], ...
    'Background', [1 1 1], 'Callback', @pickExpNum);

if nargin>1
    ai = varargin{2};
        
    set(subjectDropdown, 'String', ai.listSubjects);
else
    set(subjectDropdown, 'String', dat.listSubjects);
end

edtExpNum = uicontrol('Style', 'text', 'Parent', f, ...
    'Position',[110 h-50 90 25], ...
    'String', num2str(expNum), 'Background', [1 1 1]);


uicontrol('Style', 'pushbutton', 'String', 'OK', 'Position', ...
    [210 h-25 90 25],'Callback', @ok);
uicontrol('Style', 'pushbutton', 'String', 'Cancel', 'Position', ...
    [210 h-50 90 25],'Callback', @cancel);

uiwait();

    function ok(~,~)
        
        subjectList = get(subjectDropdown, 'String');
        subjectName = subjectList{get(subjectDropdown, 'Value')};
        expNum = str2num(get(edtExpNum, 'String'));
        delete(f)
        
    end

    function cancel(~,~)
               
        subjectName = [];
        expNum = [];
        delete(f)
        
    end

    function pickExpNum(~,~)
        
        subjectList = get(subjectDropdown, 'String');
        subjectName = subjectList{get(subjectDropdown, 'Value')};
        try
            expNumSuggestion = dat.findNextSeqNum(subjectName);
            set(edtExpNum, 'String', num2str(expNumSuggestion));
        catch
        end
        
    end
end