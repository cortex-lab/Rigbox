classdef choiceWorldExpPanel < eui.ExpPanel
    %eui.SqueakExpPanel Basic UI control for monitoring an experiment
    %   TODO
    %
    % Part of Rigbox
    
    % 2015-03 CB created
    
    properties
        SignalUpdates = struct('name', cell(500,1), 'value', cell(500,1), 'timestamp', cell(500,1))
        NumSignalUpdates = 0
        LabelsMap
        RecentColour = [0 1 0]
    end
    
    properties (Access = protected)
        PsychometricAxes % Handle to axes of psychometric plot
        ExperimentAxes % Handle to axes of wheel trace and threhold line plot
        ExperimentHands % handles to plot objects in the experiment axes
        ScreenAxes
        ScreenHands
        VelAxes
        VelHands
        InputSensorPosTime % Vector of timesstamps in seconds for plotting the wheel trace
        InputSensorPos % Vector of azimuth values for plotting the wheel trace
        InputSensorPosCount = 0 % Running total of azimuth samples recieved for axes plot
        ExtendThresholdLines = false % Flag for plotting dotted threshold lines during cue interactive delay.  Currently unused.
        lastEvtTime = now;
    end
    
    properties (Access = protected, SetObservable)
      contrastLeft = []
      contrastRight = []
    end
    
    methods
        function obj = choiceWorldExpPanel(parent, ref, params, logEntry)
            obj = obj@eui.ExpPanel(parent, ref, params, logEntry);
            obj.LabelsMap = containers.Map();
            % Initialize InputSensor properties for speed
            obj.InputSensorPos = nan(1000*30, 1);
            obj.InputSensorPosTime = nan(1000*30, 1);
            obj.InputSensorPosCount = 0;
            obj.Block.numCompletedTrials = -1;
            obj.Block.trial = struct('contrastLeft', [], 'contrastRight', [], ...
                'response', [], 'repeatNum', [], 'feedback', [],...
                'wheelGain', []);
            obj.Listeners = [obj.Listeners,...
              addlistener(obj,'contrastLeft','PostSet',@obj.setContrast), ...
              addlistener(obj,'contrastRight','PostSet',@obj.setContrast)];
        end
        
        function update(obj)
            update@eui.ExpPanel(obj);
            processUpdates(obj); % update labels with latest signal values
            labelsMapVals = values(obj.LabelsMap)';
            labels = deal([labelsMapVals{:}]);
            if ~isempty(labels) % colour decay by recency on labels
                dt = cellfun(@(t)etime(clock,t),...
                    ensureCell(get(labels, 'UserData')));
                c = num2cell(exp(-dt/1.5)*obj.RecentColour, 2);
                set(labels, {'ForegroundColor'}, c);
            end
            
        end
    end
    
    methods %(Access = protected)
      function setContrast(obj, ~, ~)
        cL = obj.contrastLeft;
        cR = obj.contrastRight;
        if ~isempty(cL)&&~isempty(cR)
          if cL>0 && cL>cR
            colorL = 'g'; colorR = 'r';
          elseif cL>0 && cL==cR
            colorL = 'g'; colorR = 'g';
          elseif cR>0
            colorL = 'r'; colorR = 'g';
          elseif isnan(cL)||isnan(cR)
            colorL = 'k'; colorR = 'k';
          else
            colorL = 'r'; colorR = 'r';
          end
          set(obj.ExperimentHands.threshL, 'Color', colorL);
          set(obj.ExperimentHands.threshR, 'Color', colorR);
          obj.Parameters.Struct.stimulusContrast = [cL cR];
          % show the visual stimulus
%           caxis(obj.ScreenAxes, [0 255]);
        end
      end
        function newTrial(obj, num, condition)
        end
        
        function trialCompleted(obj, num, data)
        end
        
        function event(obj, name, t)
            %called when an experiment event occurs
            phaseChange = false;
            if strEndsWith(name, 'Started')
                if strcmp(name, 'experimentStarted')
                    obj.Root.TitleColor = [0 0.8 0.05]; % green title area
                else
                    %phase has started, add it to active phases
                    phase = name;
                    phase(strfind(name, 'Started'):end) = [];
                    obj.ActivePhases = [obj.ActivePhases; phase];
                    phaseChange = true;
                end
            elseif strEndsWith(name, 'Ended')
                if strcmp(name, 'experimentEnded')
                    obj.Root.TitleColor = [0.98 0.65 0.22]; %amber title area
                    obj.ActivePhases = {};
                    phaseChange = true;
                else
                    %phase has ended, remove it from active phases
                    phase = name;
                    phase(strfind(name, 'Ended'):end) = [];
                    obj.ActivePhases(strcmp(obj.ActivePhases, phase)) = [];
                    phaseChange = true;
                end
                %       else
                %         disp(name);
            end
            if phaseChange % only update if there was a change for efficiency
                %update status with list of running phases
                phasesStr = ['[' strJoin(obj.ActivePhases, ',') ']'];
                set(obj.StatusLabel, 'String', sprintf('Running %s', phasesStr));
            end
        end
        
        function processUpdates(obj)
            updates = obj.SignalUpdates(1:obj.NumSignalUpdates);
            obj.NumSignalUpdates = 0;
            
            if ~isempty(updates)
                %fprintf('processing %i signal updates\n', length(updates));
                
                % pull out wheel updates
                allNames = {updates.name};
                wheelUpdates = strcmp(allNames, 'inputs.wheel');
                
                if sum(wheelUpdates)>0
                    x = -[updates(wheelUpdates).value];
                    t = (24*3600*cellfun(@(x)datenum(x), {updates(wheelUpdates).timestamp}))-(24*3600*obj.StartedDateTime);
                    
                    nx = numel(x);
                    obj.InputSensorPosCount = obj.InputSensorPosCount+nx;
                    
                    if obj.InputSensorPosCount>numel(obj.InputSensorPos)
                        % full - drop the first half of the array and shift the
                        % last half back
                        halfidx = floor(numel(obj.InputSensorPos)/2);
                        obj.InputSensorPos(1:halfidx) = obj.InputSensorPos(halfidx:2*halfidx-1);
                        obj.InputSensorPos(halfidx+1:end) = NaN;
                        obj.InputSensorPosTime(1:halfidx) = obj.InputSensorPosTime(halfidx:2*halfidx-1);
                        obj.InputSensorPosTime(halfidx+1:end) = NaN;
                        obj.InputSensorPosCount = obj.InputSensorPosCount-halfidx;
                    end
                    obj.InputSensorPos(obj.InputSensorPosCount-nx+1:obj.InputSensorPosCount) = x;
                    obj.InputSensorPosTime(obj.InputSensorPosCount-nx+1:obj.InputSensorPosCount) = t;
                    
                end
                
                % now plot the wheel
                plotwindow = [-5 1];
                lastidx = obj.InputSensorPosCount;
                
                if lastidx>0
                    
                    firstidx = find(obj.InputSensorPosTime>obj.InputSensorPosTime(lastidx)+plotwindow(1),1);
                    
                    xx = obj.InputSensorPos(firstidx:lastidx);
                    tt = obj.InputSensorPosTime(firstidx:lastidx);
                    
                    set(obj.ExperimentHands.wheelH,...
                        'XData', xx,...
                        'YData', tt);
                    
                    set(obj.ExperimentAxes.Handle, 'YLim', plotwindow + tt(end));
                    
                    % update the velocity tracker too
                    [tt, idx] = unique(tt);
                    recentX = interp1(tt, xx(idx), tt(end)+[-0.3:0.05:0]);
                    vel = mean(diff(recentX));
                    set(obj.VelHands.Vel, 'XData', vel*[1 1]);
                    obj.VelHands.MaxVel = max(abs([obj.VelHands.MaxVel vel]));
                    set(obj.VelAxes, 'XLim', obj.VelHands.MaxVel*[-1 1]);
                    
                end
                
                % now deal with other updates
                updates = updates(~wheelUpdates);
                allNames = allNames(~wheelUpdates);
                
                % first check if there is an events.newTrial
                if any(strcmp(allNames, 'events.newTrial'))
                    
                    obj.Block.numCompletedTrials = obj.Block.numCompletedTrials+1;
                    
                    % Step 1: finish up the last trial
                    obj.PsychometricAxes.clear();
                    if obj.Block.numCompletedTrials > 2
                        psy.plot2AUFC(obj.PsychometricAxes.Handle, obj.Block);
                    end
                    
                    % make sure we have all necessary data about new trial
                    assert(all(ismember(...
                        {'events.trialNum', 'events.repeatNum'}, allNames)), ...
                        'exp panel did not find all the required data about the new trial!');
                    
                    % pull out the things we need to keep
                    trNum = updates(strcmp(allNames, 'events.trialNum')).value;
                    %assert(trNum==obj.Block.numCompletedTrials+1, 'trial number doesn''t match');
                    if ~(trNum==obj.Block.numCompletedTrials+1)
                        fprintf(1, 'trial number mismatch: %d, %d\n', trNum, obj.Block.numCompletedTrials+1);
                        obj.Block.numCompletedTrials = trNum-1;
                    end
                    obj.Block.trial(trNum).repeatNum = ...
                        updates(strcmp(allNames, 'events.repeatNum')).value;
                end
                
                
                for ui = 1:length(updates)
                    signame = updates(ui).name;
                    switch signame
                        case 'events.contrastLeft'
                          cL = updates(ui).value;
                          obj.Block.trial(obj.Block.numCompletedTrials+1).contrastLeft = cL;
                          obj.contrastLeft = cL;
                        case 'events.contrastRight'
                          cR = updates(ui).value;
                          obj.Block.trial(obj.Block.numCompletedTrials+1).contrastRight = cR;
                          obj.contrastRight = cR;
                        case 'events.wheelGain'
                          obj.Block.trial(obj.Block.numCompletedTrials+1).wheelGain = ...
                            updates(ui).value;
                        case 'events.interactiveOn'
                            
                            % re-set the response window starting now
                            ioTime = (24*3600*datenum(updates(ui).timestamp))-(24*3600*obj.StartedDateTime);
                            
                            p = obj.Parameters.Struct;                            
                            respWin = Inf; if respWin>1000; respWin = 1000; end
                            
                            gain = iff(isempty(obj.Block.trial(end).wheelGain), p.normalGain, obj.Block.trial(end).wheelGain);
                            mm = 31*2*pi/(p.encoderRes*4)*gain;
                            th = p.responseDisplacement/mm;
                            startPos = obj.InputSensorPos(find(obj.InputSensorPosTime<ioTime,1,'last'));
                            if isempty(startPos); startPos = obj.InputSensorPos(obj.InputSensorPosCount); end % for first trial
                            tL = startPos-th;
                            tR = startPos+th;
                            
                            set(obj.ExperimentHands.threshL, ...
                                'XData', [tL tL], 'YData', ioTime+[0 respWin]);
                            set(obj.ExperimentHands.threshR, ...
                                'XData', [tR tR], 'YData', ioTime+[0 respWin]);
                            
                            yd = get(obj.ExperimentHands.threshLoff, 'YData');
                            set(obj.ExperimentHands.threshLoff, 'XData', [tL tL], 'YData', [yd(1) ioTime]);
                            set(obj.ExperimentHands.threshRoff, 'XData', [tR tR], 'YData', [yd(1) ioTime]);
                            
                            obj.ExperimentAxes.XLim = startPos+1.5*th*[-1 1];
                            
                        case 'events.stimulusOn'
                                              
                            p = obj.Parameters.Struct;                            
                            soTime = (24*3600*datenum(updates(ui).timestamp))-(24*3600*obj.StartedDateTime);              
                            gain = iff(isempty(obj.Block.trial(end).wheelGain), p.normalGain, obj.Block.trial(end).wheelGain);
                            mm = 31*2*pi/(p.encoderRes*4)*gain;
                            th = p.responseDisplacement/mm;
                            startPos = obj.InputSensorPos(find(obj.InputSensorPosTime<soTime,1,'last'));
                            if isempty(startPos); startPos = obj.InputSensorPos(obj.InputSensorPosCount); end % for first trial
                            tL = startPos-th;
                            tR = startPos+th;
                            
                            set(obj.ExperimentHands.threshLoff,  ...
                                'XData', [tL tL], 'YData', soTime+[0 100]);
                            set(obj.ExperimentHands.threshRoff, ...
                                'XData', [tR tR], 'YData', soTime+[0 100]);
                            set(obj.ExperimentHands.threshL, 'YData', [NaN NaN]);
                            set(obj.ExperimentHands.threshR, 'YData', [NaN NaN]);
                            
                            set(obj.ExperimentHands.incorrIcon, 'XData', 0, 'YData', NaN);
                            set(obj.ExperimentHands.corrIcon, 'XData', 0, 'YData', NaN);
                            
                            obj.ExperimentAxes.XLim = startPos+1.5*th*[-1 1];
                            [x,y,im] = screenImage(obj.Parameters.Struct);
                            set(obj.ScreenHands.Im, 'XData', x, 'YData', y, 'CData', im);
                        case 'events.stimulusOff'   
                            
                            set(obj.ScreenHands.Im, 'CData', 127*ones(size(get(obj.ScreenHands.Im, 'CData'))));
                            caxis(obj.ScreenAxes, [0 255]);
                            
                        case 'events.response'
                            
                            obj.Block.trial(obj.Block.numCompletedTrials+1).response = updates(ui).value;
                            
                        case 'events.feedback'
                            
                            obj.Block.trial(obj.Block.numCompletedTrials+1).feedback = updates(ui).value;
                            
                            fbTime = (24*3600*datenum(updates(ui).timestamp))-(24*3600*obj.StartedDateTime);
                            whIdx = find(obj.InputSensorPosTime<fbTime,1, 'last');
                            
                            if updates(ui).value>0
                                set(obj.ExperimentHands.corrIcon, ...
                                    'XData', obj.InputSensorPos(whIdx), ...
                                    'YData', obj.InputSensorPosTime(whIdx));
                                set(obj.ExperimentHands.incorrIcon, ...
                                    'XData', 0, ...
                                    'YData', NaN);
                            elseif updates(ui).value==0
                                set(obj.ExperimentHands.incorrIcon, ...
                                    'XData', obj.InputSensorPos(whIdx), ...
                                    'YData', obj.InputSensorPosTime(whIdx));
                                set(obj.ExperimentHands.corrIcon, ...
                                    'XData', 0, ...
                                    'YData', NaN);
                            end
                            
                        case 'events.azimuth'
                            
                            az = updates(ui).value;
                            set(obj.ScreenAxes, 'XLim', -az+[-135 135]); % trick to move visual stimuli by moving the xlim in the opposite way
                            
                        case {'events.trialNum', 'events.repeatNum', 'events.totalWater'...
                                'events.disengaged', 'events.pctDecrease', 'events.proportionLeft',...
                                'events.trialsToSwitch'}
                            
                            if ~isKey(obj.LabelsMap, signame)
                                obj.LabelsMap(signame) = obj.addInfoField(signame, '');
                            end
                            str = toStr(updates(ui).value);
                            set(obj.LabelsMap(signame), 'String', str, 'UserData', clock,...
                                'ForegroundColor', obj.RecentColour);
                    end
                end
                
                
                
                
                
            end
        end
        
        function expUpdate(obj, rig, evt)
            if strcmp(evt.Name, 'signals')
                type = 'signals';
            else
                type = evt.Data{1};
            end
            
            switch type
                
                case 'signals' %queue signal updates
                    updates = evt.Data;
                    newNUpdates = obj.NumSignalUpdates + length(updates);
                    %fprintf(1, '%d signals updates\n', length(updates));
                    if newNUpdates > length(obj.SignalUpdates)
                        %grow message queue to accommodate
                        obj.SignalUpdates(2*newNUpdates).value = [];
                    end
                    try
                        obj.SignalUpdates(obj.NumSignalUpdates+1:newNUpdates) = updates;
                    catch
                        warning('Error caught in signals updates: length of updates = %g, length newNUpdates = %g', length(updates), newNUpdates-(obj.NumSignalUpdates+1))
                    end
                    obj.NumSignalUpdates = newNUpdates;
                    
                case 'event'
                    %disp(evt.Data);
                    obj.event(evt.Data{2}, evt.Data{3});
            end
        end
        
        function build(obj, parent)
            obj.Root = uiextras.BoxPanel('Parent', parent,...
                'Title', obj.Ref,... %default title is the experiment reference
                'TitleColor', [0.98 0.65 0.22],...%amber title area
                'Padding', 5,...
                'CloseRequestFcn', @obj.closeRequest,...
                'DeleteFcn', @(~,~) obj.cleanup());
            
            obj.MainVBox = uiextras.VBox('Parent', obj.Root, 'Spacing', 5);
            
            obj.InfoGrid = uiextras.Grid('Parent', obj.MainVBox);
            %       obj.InfoGrid.ColumnSizes = [150, -1];
            %panel for subclasses to add their own controls to
            obj.CustomPanel = uiextras.VBox('Parent', obj.MainVBox);
            
            bui.label('Comments', obj.MainVBox);
            
            obj.CommentsBox = uicontrol('Parent', obj.MainVBox,...
                'Style', 'edit',... %text editor
                'String', obj.LogEntry.comments,...
                'Max', 2,... %make it multiline
                'HorizontalAlignment', 'left',... %make it align to the left
                'BackgroundColor', [1 1 1],...%background to white
                'Callback', @obj.commentsChanged); %update comment in log
            
            buttonpanel = uiextras.HBox('Parent', obj.MainVBox);
            %info grid size will be updated as fields are added, the other
            %default panels get reasonable space, and the custom panel gets
            %whatever's left
            obj.MainVBox.Sizes = [0 -1 15 80 24];
            
            %add the default set of info fields to the grid
            obj.StatusLabel = obj.addInfoField('Status', 'Pending');
            obj.DurationLabel = obj.addInfoField('Elapsed', '-:--');
            
            if isfield(obj.Parameters.Struct, 'conditionId')
                obj.ConditionLabel = obj.addInfoField('Condition', 'N/A');
            end
            
            %buttons to stop experiment running if and when it is, by default
            %hidden
            obj.StopButtons = [...
                uicontrol('Parent', buttonpanel,...
                'Style', 'pushbutton',...
                'String', 'End'),...
                uicontrol('Parent', buttonpanel,...
                'Style', 'pushbutton',...
                'String', 'Abort')];
            set(obj.StopButtons, 'Enable', 'off', 'Visible', 'off');
            uicontrol('Parent', buttonpanel,...
                'Style', 'pushbutton',...
                'String', 'Parameters...',...
                'Callback', @(~, ~) obj.viewParams());
            
            % Build the psychometric axes
            plotgrid = uiextras.VBox('Parent', obj.CustomPanel, 'Padding', 5);
            
            uiextras.Empty('Parent', plotgrid, 'Visible', 'off');
            
            obj.PsychometricAxes = bui.Axes(plotgrid);
            obj.PsychometricAxes.ActivePositionProperty = 'position';
            obj.PsychometricAxes.YLim = [-1 101];
            obj.PsychometricAxes.NextPlot = 'add';
            
            uiextras.Empty('Parent', plotgrid, 'Visible', 'off');
            
            obj.ScreenAxes = axes('Parent', plotgrid);
            obj.ScreenHands.Im = imagesc(0,0,127);
            axis(obj.ScreenAxes, 'image');
            axis(obj.ScreenAxes, 'off');
            colormap(obj.ScreenAxes, 'gray');
            
            uiextras.Empty('Parent', plotgrid, 'Visible', 'off');
            
            obj.ExperimentAxes = bui.Axes(plotgrid);
            obj.ExperimentAxes.ActivePositionProperty = 'position';
            obj.ExperimentAxes.XTickLabel = [];
            obj.ExperimentAxes.NextPlot = 'add';
            obj.ExperimentHands.wheelH = plot(obj.ExperimentAxes,...
                [0 0],...
                [NaN NaN],...
                'Color', .75*[1 1 1]);
            obj.ExperimentHands.threshL = plot(obj.ExperimentAxes, ...
                [0 0],...
                [NaN NaN],...
                'Color', [1 1 1], 'LineWidth', 4);
            obj.ExperimentHands.threshR = plot(obj.ExperimentAxes, ...
                [0 0],...
                [NaN NaN],...
                'Color', [1 1 1], 'LineWidth', 4);
            obj.ExperimentHands.threshLoff = plot(obj.ExperimentAxes, ...
                [0 0],...
                [NaN NaN],...
                'Color', [0.5 0.5 0.5], 'LineWidth', 4);
            obj.ExperimentHands.threshRoff = plot(obj.ExperimentAxes, ...
                [0 0],...
                [NaN NaN],...
                'Color', [0.5 0.5 0.5], 'LineWidth', 4);
            obj.ExperimentHands.corrIcon = scatter(obj.ExperimentAxes, ...
                0, NaN, pi*10^2, 'b', 'filled');
            obj.ExperimentHands.incorrIcon = scatter(obj.ExperimentAxes, ...
                0, NaN, pi*10^2, 'rx', 'LineWidth', 4);
            
            uiextras.Empty('Parent', plotgrid, 'Visible', 'off');
            
            obj.VelAxes = axes('Parent', plotgrid);
            obj.VelHands.Zero = plot(obj.VelAxes, [0 0], [0 1], 'k--');
            hold(obj.VelAxes, 'on');
            obj.VelHands.Vel = plot(obj.VelAxes, [0 0], [0 1], 'r', 'LineWidth', 2.0);
            axis(obj.VelAxes, 'off');
            obj.VelHands.MaxVel = 1e-9;
            
            set(plotgrid, 'Sizes', [30 -2 30 -2 10 -4 5 -1]);
        end
    end
    
end