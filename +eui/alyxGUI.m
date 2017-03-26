classdef alyxGUI < handle
    % eui.alyxGUI
    %   Standalone gui for alyx, without the rest of MC
    % Needs only three things: subject selector, log box, alyx panel
    %
    % Part of Rigbox
    
    properties
        AlyxInstance = [];
        AlyxUsername = [];
        weighingsUnpostedToAlyx = {}; % holds weighings until someone logs in, to be posted
    end
    
    properties (SetAccess = private)
        NewExpSubject
        
        
    end
    
    properties (Access = private)
        LoggingDisplay %control for showing log output
        
        RootContainer
        
        Listeners
        
    end
    
    methods
        function obj = alyxGUI()
            
            f = figure('Name', 'alyx GUI',...
                'MenuBar', 'none',...
                'Toolbar', 'none',...
                'NumberTitle', 'off',...
                'Units', 'normalized',...
                'OuterPosition', [0.1 0.1 0.4 .4]);
            
            obj.RootContainer = uiextras.VBox('Parent', f,...
                'Visible', 'on');
            
            % subject selector
            sbox = uix.HBox('Parent', obj.RootContainer);
            bui.label('Select subject: ', sbox);
            obj.NewExpSubject = bui.Selector(sbox, {'default'}); % Subject dropdown box
            
            % alyx panel
            eui.AlyxPanel(obj, obj.RootContainer);
            
            % logging message area
            obj.LoggingDisplay = uicontrol('Parent', obj.RootContainer, 'Style', 'listbox',...
                'Enable', 'inactive', 'String', {});
            
            obj.RootContainer.Sizes = [50 150 150];
            
            
        end
        
        function log(obj, varargin)
            message = sprintf(varargin{:});
            timestamp = datestr(now, 'dd-mm-yyyy HH:MM:SS');
            str = sprintf('[%s] %s', timestamp, message);
            current = get(obj.LoggingDisplay, 'String');
            set(obj.LoggingDisplay, 'String', [current; str], 'Value', numel(current) + 1);
        end
        
    end
end
