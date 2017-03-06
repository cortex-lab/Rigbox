classdef ROIToy < handle
  %BUI.ROIToy Movie player with ROI selection
  %   TODO
  %
  % Part of Burgbox

  % 2013-01 CB created    
  
  properties
    DefaultRegionRadius = 5
    ROIMode = 'select'
    Axes % axes component containing the image
  end
  
  properties (SetAccess = private)
    FrameIdx = 1
    StackIdx = 1
    NumRegions = 0
    Regions = struct('x', {}, 'y', {}, 'motifMask', {}, 'frameMask', {}, 'outlinePoints', {})
    IsPlaying = false
    ViewMode = 'frame'
    PlayStep
  end
  
  properties (Dependent = true)
    Stacks % array of img.ImageSeries
    SelectedRegion
  end
  
  properties (Access = private)
    % blank stack for when no data is loaded
    BlankStack
    Image % handle to the image object
    FrameSlider
    FrameDt
    StatusText
    StackMenu
    SpeedMenu
    PlayButton
    ZProjectButton
    SelectedIdx
    AnimationTimer = []
    AnimationPeriod = 30/1000; % seconds
    PlayFps = [5 10 20 30 50 100]
    PlaySpeed = [0.25 0.5 1 2 5 10]
    RegionLine
    MouseRegionOffset = [0 0]
    RootContainer
    RangeSliders
    pStacks
    StackListener %listener for the currently selected stack
  end
  
  events
    SelectionChanged
    RegionChanged
    FrameChanged
  end
  
  methods
    function obj = ROIToy(parent)
      obj.BlankStack = img.ImageArray(rand(100));
      obj.BlankStack.Info.title = 'none';
      buildUI(obj, parent);
    end
    
    function [x, t] = regionTimeseries(obj, stackIdx, regionIdx)
      if nargin < 2
        stackIdx = obj.StackIdx;
      end
      if nargin < 3
        region = obj.SelectedRegion;
      else
        region = obj.Regions(regionIdx);
      end
      ci = find(obj.Stacks(stackIdx).X == region.x, 1);
      ri = find(obj.Stacks(stackIdx).Y == region.y, 1);
      x = squeeze(obj.Stacks(stackIdx).Frames(ri,ci,:));
      if nargout > 1
        t = obj.Stacks(stackIdx).Time;
      end
    end
    
    function x = stackBackground(obj, idx)
      %STACKBACKGROUND Computes the frame mean over time over non-ROI area
      %   Detailed explanation goes here
      if nargin < 2
        idx = obj.StackIdx;
      end
      x = bsxfun(@times, allRegionsMask(obj), obj.Stacks(idx).Frames);
      x = mean(reshape(x, [], obj.Stacks(idx).NumFrames), 1);
    end
    
    function r = region(obj, idx)
      r = obj.Region(idx);
    end
    
    function clearRegions(obj)
      n = length(obj.Regions);
      for i = n:-1:1
        removeRegion(obj, i);
      end
    end
    
    function setRegions(obj, regions)
      clearRegions(obj);
      n = numel(regions);
      for i = 1:n
        addRegion(obj, regions(i));
      end
    end

    function M = allRegionsMask(obj)
      M = sum(cell2mat(shiftdim({obj.Regions.mask}, -1)), 3);
    end

    function value = get.SelectedRegion(obj)
      value = obj.Regions(obj.SelectedIdx);
    end
    
    function value = get.Stacks(obj)
      value = obj.pStacks;
    end
    
    function set.Stacks(obj, value)
      disp('setting new stack data');
      obj.pStacks = value;
      obj.configureStack();
    end
    
    function showZProject(obj, projectfun)
      % stop playing if currently running
      obj.stopStack();
      
      zProject = projectfun(obj.Stacks(obj.StackIdx).Frames);
      set(obj.Image, 'CData', zProject);
      obj.ViewMode = 'project';
      set(obj.ZProjectButton, 'String', '<HTML>&Xi;</HTML>');
    end
    
    function showFrame(obj, idx)
      if ~strcmp(obj.ViewMode, 'frame')
        % if the viewmode isn't currently frame, make it so
        obj.ViewMode = 'frame';
        set(obj.ZProjectButton, 'String', '<HTML>&mdash;</HTML>');
      end

      obj.FrameIdx = idx; % save original, potentially fractional index
      ridx = round(idx); % round fractional index for actual frame to show
      % display image frame
      frame = obj.Stacks(obj.StackIdx).Frames(:,:,ridx);
      set(obj.Image, 'CData', frame);

      % update the status text
      set(obj.StatusText, 'String', obj.statusText);
      
      % update the slider value
      set(obj.FrameSlider, 'Value', obj.FrameIdx);
      
      % notify interested handlers that the current frame has changed
      notify(obj, 'FrameChanged');
    end
    
    function showStack(obj, idx)
      obj.StackListener = []; %clear any current listener
      obj.StackIdx = idx;
      obj.configureStack();
    end
    
    function stopStack(obj)
      obj.IsPlaying = false;
      if ~isempty(obj.AnimationTimer)
        %stop and clear playback animation timer
        stop(obj.AnimationTimer);
        delete(obj.AnimationTimer);
        obj.AnimationTimer = [];
      end
      % update ui state to allow playback to begin again
      set(obj.PlayButton, 'String', '|>');
    end
    
    function playStack(obj)
      % stop if already running
      obj.stopStack();
      
      obj.IsPlaying = true;
      
      % update button state
      set(obj.PlayButton, 'String', '||');
      % create and start a timer to animate frame playback
      obj.AnimationTimer = timer('ExecutionMode', 'fixedRate',...
        'Period', obj.AnimationPeriod,...
        'TimerFcn', @(src, evt) obj.nextFrame(obj.PlayStep));
      start(obj.AnimationTimer);
    end
    
    function nextFrame(obj, stepSize)
      %show next frame, where next frame is advanced from previous by
      %stepSize
      if nargin < 2
        stepSize = 1;
      end
      nextFrame = obj.FrameIdx + stepSize;
      if nextFrame > obj.Stacks(obj.StackIdx).NumFrames
        nextFrame = 1;
      end
      obj.showFrame(nextFrame);
    end
    
    function delete(obj)
      disp('delete ROIToy called');
      if obj.RootContainer.isvalid
        delete(obj.RootContainer);
      end
      if ~isempty(obj.AnimationTimer)
        t = obj.AnimationTimer;
        stop(t);
        delete(t);
        obj.AnimationTimer = [];
      end
      if obj.Axes.isvalid
        delete(obj.Axes);
      end
      if ~isempty(obj.StackListener)
        obj.StackListener = [];
      end
    end
  end
  
  methods (Access = private)
    function lumSliderChanged(obj)
      values = sort(cell2mat(get(obj.RangeSliders, 'Value')));
      obj.Axes.CLim = values;
      set(obj.RangeSliders(1), 'Value', values(1));
      set(obj.RangeSliders(2), 'Value', values(2));
    end

    function moveRegion(obj, idx, newx, newy)
      p = obj.Regions(idx).outlinePoints;
      set(obj.RegionLine(idx), 'XData', p(1,:) + newx, 'YData', p(2,:) + newy);
      obj.Regions(idx).x = newx;
      obj.Regions(idx).y = newy;
%       [newx, newy]
%       tic
      stack = obj.Stacks(obj.StackIdx);
      obj.Regions(idx).frameMask = paste(obj,...
        obj.Regions(idx).motifMask, false(stack.FrameSize),...
        newx - stack.X(1) + 1, newy - stack.Y(1) + 1);
%       toc
      if any(obj.SelectedIdx == idx)
        notify(obj, 'SelectionChanged');
      end
    end
    
    function dst = paste(obj, src, dst, cx, cy)
      srcw = size(src, 2);
      srch = size(src, 1);
      siy = 1:srch;
      six = 1:srcw;
      diy = siy + cy - ceil(srcw/2);
      dix = six + cx - ceil(srch/2);
      validy = diy >= 1 & diy <= size(dst, 1);
      validx = dix >= 1 & dix <= size(dst, 2);
      dst(diy(validy),dix(validx)) = src(siy(validy),six(validx));
    end
    
    function idx = newRegion(obj, x, y, r)
      % create a region struct entry
      region.x = x;
      region.y = y;
      
      % create a mask
      stack = obj.Stacks(obj.StackIdx);
      
      region.motifMask = circleMask(r);
      region.frameMask = paste(obj, region.motifMask, false(stack.FrameSize),...
        x - stack.X(1) + 1, y - stack.Y(1) + 1);
      
      % create the points for the outline
      region.outlinePoints = circlePoints(obj, r);
      
      % add the new region to the ui
      idx = addRegion(obj, region);
    end
    
    function idx = addRegion(obj, region)
      idx = length(obj.Regions) + 1;
      obj.Regions(idx).x = region.x;
      obj.Regions(idx).y = region.y;
      obj.Regions(idx).outlinePoints = region.outlinePoints;
      if isfield(region, 'frameMask')
        obj.Regions(idx).frameMask = region.frameMask;
        obj.Regions(idx).motifMask = region.motifMask;
      else
        obj.Regions(idx).frameMask = region.mask;
        obj.Regions(idx).motifMask = region.mask;
      end
      p = region.outlinePoints;
      % create a graphic that handles clicks
      obj.RegionLine(idx) = obj.Axes.line(...
        p(1,:) + region.x, p(2,:) + region.y,...
        'Color', 'r', 'LineWidth', 2,...
        'ButtonDownFcn', @(src, evt) handleRegionClick(obj, src));
    end
    
    function removeRegion(obj, idx)
      % delete the graphic
      delete(obj.RegionLine(idx));
      obj.RegionLine(idx) = [];
      % delete the struct entry
      obj.Regions(idx) = [];
      obj.SelectedIdx(obj.SelectedIdx == idx) = [];
      obj.SelectedIdx(obj.SelectedIdx > idx) = obj.SelectedIdx(obj.SelectedIdx > idx) - 1;
    end
    
    function setSelected(obj, idx)
      obj.SelectedIdx = idx;
      set(obj.RegionLine, 'Color', 'r');
      set(obj.RegionLine(idx), 'Color', 'w');
      notify(obj, 'SelectionChanged');
    end

    function p = circlePoints(obj, r)
      t = linspace(0, 2*pi, 100);
      p(1,:) = r*cos(t);
      p(2,:) = r*sin(t);
    end
    
    function configureStack(obj)
      currStack = obj.StackIdx;
      frameSz = obj.Stacks(obj.StackIdx).FrameSize;
      obj.FrameDt = mean(diff(obj.Stacks(currStack).Time));
      % configure the stack menu
      titles = img.stackLabel(obj.Stacks);
      set(obj.StackMenu, 'String', titles, 'Value', currStack);
      % configure image x,y axis limits
      pxSz = @(range, len) (range(2) - range(1))/(len - 1);
      pxx = [obj.Stacks(currStack).X(1) obj.Stacks(currStack).X(end)];
      pxy = [obj.Stacks(currStack).Y(1) obj.Stacks(currStack).Y(end)];
      pxh = pxSz(pxy, frameSz(1));
      pxw = pxSz(pxx, frameSz(2));
      set(obj.Image, 'YData', pxy);
      set(obj.Image, 'XData', pxx);
      obj.Axes.YLim = [(pxy(1) - 0.5*pxh) (pxy(2) + 0.5*pxh)];
      obj.Axes.XLim = [(pxx(1) - 0.5*pxw) (pxx(2) + 0.5*pxw)];
      
      % configure the frame slider
      nframes = obj.Stacks(currStack).NumFrames;
      if nframes >= 2
        sliderstep = 1/(nframes - 1)*[1 2];
        slidermax = nframes;
        set(obj.FrameSlider, 'Enable', 'on');
      else
        sliderstep = [1 1];
        slidermax = 2;
        set(obj.FrameSlider, 'Enable', 'off');
      end
      set(obj.FrameSlider, 'Min', 1, 'Max', slidermax,...
        'Value', obj.FrameIdx, 'SliderStep', sliderstep);
      
      % configure the speed menu
      if ~isempty(obj.Stacks(currStack).Time)
        s = obj.PlaySpeed;
        speeds = cellfun(@(e) [num2str(e) 'x'], num2cell(s), 'UniformOutput', false);
      else
        s = obj.PlayFps;
        speeds = cellfun(@(e) [num2str(e) 'fps'], num2cell(s), 'UniformOutput', false);
      end
      set(obj.SpeedMenu, 'String', speeds);
      obj.updatePlayStep();
      
      %start listening to the current stack
      obj.StackListener = event.listener(...
        obj.Stacks(currStack), 'FrameContentChanged',...
        @(~, ~) iff(ishandle(obj.Axes.Handle), @obj.frameDataChanged, []));
      
      % ensure frame index within bounds
      if obj.FrameIdx > nframes
        obj.FrameIdx = nframes;
      end
      %update ui for current frame
      frameDataChanged(obj);
    end
    
    function frameDataChanged(obj)
      currStack = obj.StackIdx;
      %reconfigure image luminance limits
      range = [obj.Stacks(currStack).Min obj.Stacks(currStack).Max];
      if all(isfinite(range))
        set(obj.RangeSliders, 'Enable', 'on');
        set(obj.RangeSliders(1), 'Min', range(1), 'Max', range(2), 'Value', range(1));
        set(obj.RangeSliders(2), 'Min', range(1), 'Max', range(2), 'Value', range(2));
        obj.lumSliderChanged();
      else
        set(obj.RangeSliders, 'Enable', 'off');
      end
      %redraw current frame
      showFrame(obj, obj.FrameIdx);
    end
    
    function handleRegionClick(obj, line)
      switch obj.ROIMode
        case 'select'
          evt = bui.MouseEvent(obj.Axes.Handle);
          idx = find(obj.RegionLine == line);
          reg = obj.Regions(idx);
          setSelected(obj, idx);
          offset = [reg.x reg.y] - evt.CurrentPos;
          obj.MouseRegionOffset = offset;
      case 'delete'
          idx = find(obj.RegionLine == line);
          removeRegion(obj, idx);
      end
    end
    
    function handleMouseDown(obj, evt)
      px = round(evt.CurrentPos(1));
      py = round(evt.CurrentPos(2));
      switch obj.ROIMode
        case 'add'
          newRegion(obj, px, py, obj.DefaultRegionRadius);
        case 'select'
          setSelected(obj, []);
      end
    end
    
    function handleMouseMovement(obj, evt)
      px = round(evt.CurrentPos(1));
      py = round(evt.CurrentPos(2));
%       fprintf('p=(%i,%i)\n', px, py);
      switch obj.ROIMode
        case 'add'
          if isempty(obj.SelectedIdx)
            % create and select new region that moves with mouse
            obj.MouseRegionOffset = [0 0];
            setSelected(obj, newRegion(obj, px, py, obj.DefaultRegionRadius));
            
          else
            moveRegion(obj, obj.SelectedIdx, px, py);
          end
        case 'select'
      end
    end
    
    function handleMouseDragged(obj, evt)
      stack = obj.Stacks(obj.StackIdx);
      frameMax = [stack.X(end) stack.Y(end)];
      frameMin = [stack.X(1) stack.Y(1)];
      
      p = round(evt.CurrentPos + obj.MouseRegionOffset);
      p = min(frameMax, max(frameMin, p));
      switch obj.ROIMode
        case 'add'
        case 'select'
          if ~isempty(obj.SelectedIdx)
            moveRegion(obj, obj.SelectedIdx, p(1), p(2));
          end
      end
    end
    
    function handleMouseLeft(obj)
      switch obj.ROIMode
        case 'add'
          removeRegion(obj, obj.SelectedIdx);
          obj.SelectedIdx = [];
      end
    end
    
    function s = statusText(obj)
      fidx = round(obj.FrameIdx); % round potentially fractional frame index
      nframes = obj.Stacks(obj.StackIdx).NumFrames;
      s = sprintf('Frame %*.i/%i', length(num2str(nframes)), fidx, nframes);
      t = obj.Stacks(obj.StackIdx).Time;
      if ~isempty(t)
        tmax = t(end);
        fprec = ceil(max(-log10(obj.FrameDt), 0));
        fwidth = length(sprintf('%.*f', fprec, tmax));
        tunits = 's';
%         if isfield(obj.Stack, 'timeUnits')
%           tunits = obj.Stack(obj.StackIdx).timeUnits;          
%         end
        s = sprintf('%s, %*.*f/%*.*f%s', s, fwidth, fprec, ...
          t(fidx), fwidth, fprec, tmax, tunits);
      end
    end
    
    function f = stackTimeFactor(obj)
      f = 1; % seconds is default
%       if isfield(obj.Stack, 'timeUnits')
%         switch obj.Stack(obj.StackIdx).timeUnits
%           case 'ms'
%             f = 1/1000;          
%         end
%       end
    end
    
    function updatePlayStep(obj)
      speeds = get(obj.SpeedMenu, 'String');
      fpsMode = ~isempty(strfind(speeds{1}, 'fps'));
      if fpsMode
        fps = obj.PlayFps(get(obj.SpeedMenu, 'Value'));
        period = 1/fps;
      else
        speed = obj.PlaySpeed(get(obj.SpeedMenu, 'Value'));
        period = obj.stackTimeFactor*obj.FrameDt/speed;
      end
      % animation timer loops at a certain rate, so we need to step
      % a potentially fractional number of frames each loop iteration
      obj.PlayStep = obj.AnimationPeriod/period;
    end
    
    function playToggle(obj)
      if obj.IsPlaying
        stopStack(obj);
      else
        playStack(obj);
      end
    end
    
    function zProjectToggle(obj)
      switch obj.ViewMode
        case 'frame'
          obj.showZProject(@(f) nanmean(f, 3));
          obj.ViewMode = 'project-mean';
        otherwise
          obj.showFrame(obj.FrameIdx);
      end
    end
    
    function buildUI(obj, parent)
      obj.RootContainer = uiextras.VBox('Parent', parent);
      
      topbox = uiextras.HBox('Parent', obj.RootContainer, 'Padding', 1);
      
      obj.StackMenu = uicontrol('Style', 'popupmenu', 'Enable', 'on',...
        'String', {''},...
        'Callback', @(src, evt) obj.showStack(get(src, 'Value')),...
        'Parent', topbox);
      
      % the midbox has the luminance controls and axes
      midbox = uiextras.HBox('Parent', obj.RootContainer, 'Padding', 1);
      
      % set up the axes for displaying current frame image
      obj.Axes = bui.Axes(midbox);
      obj.Axes.ActivePositionProperty = 'Position';
      obj.Image = imagesc(0, 'Parent', obj.Axes.Handle);
      obj.Axes.XTickLabel = [];
      obj.Axes.YTickLabel = [];
      obj.Axes.DataAspectRatio = [1 1 1];
      
      % set up the luminance sliders
      slidergrid = uiextras.Grid('Parent', midbox);
      uicontrol('Style', 'text', 'Parent', slidergrid, 'String', '>');
      obj.RangeSliders(1) = uicontrol('Style', 'slider', 'Parent', slidergrid,...
        'Callback', @(~,~) obj.lumSliderChanged());
      uicontrol('Style', 'text', 'Parent', slidergrid, 'String', '<');
      obj.RangeSliders(2) = uicontrol('Style', 'slider', 'Parent', slidergrid,...
        'Callback', @(~,~) obj.lumSliderChanged());
      slidergrid.RowSizes = [15 -1];
      slidergrid.ColumnSizes = [15 15];
      midbox.Sizes = [-1 30];

      % configure handling mouse events over axes to update selector cursor
      obj.Axes.addlistener('MouseLeft', @(src, evt) handleMouseLeft(obj));
      obj.Axes.addlistener('MouseMoved', @(src, evt) handleMouseMovement(obj, evt));
      obj.Axes.addlistener('MouseButtonDown', @(src, evt) handleMouseDown(obj, evt));
      obj.Axes.addlistener('MouseDragged', @(src, evt) handleMouseDragged(obj, evt));

      bottombox = uiextras.HBox('Parent', obj.RootContainer, 'Padding', 1);
      
      obj.ZProjectButton = uicontrol('String', '<HTML>&mdash;</HTML>',...
        'Callback', @(src, evt) obj.zProjectToggle(),...
        'Parent', topbox);
      obj.PlayButton = uicontrol('String', '|>',...
        'Callback', @(src, evt) obj.playToggle(),...
        'Parent', topbox);
      obj.SpeedMenu = uicontrol('Style', 'popupmenu', 'Enable', 'on',...
        'String', {'', '', '', '', ''},...
        'Value', find(obj.PlaySpeed == 1, 1),...
        'Parent', topbox,...
        'Callback', @(s,e) obj.updatePlayStep());
      
      obj.FrameSlider = uicontrol('Style', 'slider', 'Enable', 'off',...
        'Parent', bottombox,...
        'Callback', @(src, ~) obj.showFrame(get(src, 'Value')));
      obj.StatusText = uicontrol('Style', 'edit', 'String', '', ...,
        'Enable', 'inactive', 'Parent', bottombox);
      set(obj.RootContainer, 'Sizes', [24 -1 24]);
      set(topbox, 'Sizes', [-1 24 24 58]);
      set(bottombox, 'Sizes', [-1 160]);
      
      obj.Stacks = obj.BlankStack;
    end
  end
  
end

