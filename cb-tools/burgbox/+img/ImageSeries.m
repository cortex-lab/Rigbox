classdef ImageSeries < matlab.mixin.Heterogeneous & matlab.mixin.Copyable & handle
  %UNTITLED4 Summary of this class goes here
  %   Detailed explanation goes here
  
  
  properties
    Info = struct('tags', {{}}) %Metadata about the series
    %Function to generate series of images that were transformed to produce
    %this
    BaseGenerator
    %A set of functions that can be applied to in turn to the ImageSeries
    %starting from the base to (re)generate this ImageSeries
    Transforms = {}
  end

  properties (Abstract)
    Frames
    Time
    X
    Y
  end
  
  properties (Dependent = true)
    NumFrames
    FrameSize
    Centile
    Min
    Max
    MaxFramesForStats
  end
  
  properties (Access = protected)
    pCentile
    pMaxFramesForStats = 1000
    pDt
  end
  
  events
    FrameContentChanged %Content of frames changed
    FrameStructureChanged %Frame size or number of frames changed
  end

  methods
    function t = dt(obj)
      % assume that dt is close to constant (or error if the relative
      % standard deviation is more than 1%)
      if isempty(obj.pDt)
        dt = diff(obj.Time);
        rsd = 100*abs(std(dt)/mean(dt));
        assert(rsd <= 1,...
          'Frame time relative standard deviation > 1%% (it''s %.2f%%)', rsd);
        obj.pDt = mean(dt);
      end
      t = obj.pDt;
    end
    
    function i = with(obj, frames, x, y)
      i = obj.copy; %make a copy of this
      i.Frames = frames; %set the copies frame to that passed
      if nargin >= 3
        i.X = x;
      end
      if nargin >= 4
        i.Y = y;
      end
    end

    function i = apply(obj, fun)
      i = fun(obj);
      if ~isa(i, 'img.ImageSeries')
        %assume output was the frames array
        i = obj.with(i);
      end
      i.Transforms = [i.Transforms; {fun}]; % then add to its list of transforms
    end

    function value = get.FrameSize(obj)
      sz = size(obj.Frames);
      value = sz(1:2);
    end

    function value = get.NumFrames(obj)
      value = size(obj.Frames, 3);
    end
    
    function value = get.Max(obj)
      % The maximum value of the frames. Note this potentially an
      % approximation by computing from only a subset of frames
      value = obj.Centile(100);
    end
    
    function value = get.Min(obj)
      % The minimum value of the frames. Note this potentially an
      % approximation by computing from only a subset of frames
      
      %force the centiles to be computed if not already
      if isempty(obj.pCentile)
        cnt = obj.Centile;
      end
      value = obj.pCentile(1);
    end
    
    function value = get.MaxFramesForStats(obj)
      value = obj.pMaxFramesForStats;
    end
    
    function set.MaxFramesForStats(obj, value)
      % clear computed stats if the new value is larger (i.e. requested to
      % use more frames to compute stats on)
      if value > obj.pMaxFramesForStats
        obj.invalidateStats();
      end
      obj.pMaxFramesForStats = value;
    end

    function value = get.Centile(obj)
      % returns the approximate 100 (i.e. integer, 1-100) percentiles of the data
      % for the zeroth, use Min
      if isempty(obj.pCentile)
        % compute the approximate percentiles by striding the frames if
        % more than 2000
        stride = floor(max(obj.NumFrames/obj.pMaxFramesForStats, 1));
        fprintf('Recomputing centiles with a frame stride of %i\n', stride);
        slices = obj.Frames(:,:,1:stride:end);
        flat = slices(:);
        y = prctile(flat, 0:100);
        obj.pCentile = y;
      end
      value = obj.pCentile(2:end);
    end    
  end
  
  methods (Access = protected)
    function framesChanged(obj)
      obj.invalidateStats(); % clear any cached statistics
    end

    function invalidateStats(obj)
      obj.pCentile = [];
    end
  end
  
  methods (Static)
    function i = from(baseGen, transforms)
      if nargin < 2
        transforms = {};
      end
      i = baseGen();
      i.BaseGenerator = baseGen;
      for j = 1:numel(transforms)
        i = i.apply(transforms{j});
      end
    end
  end
  
end

