classdef ImageSeriesSlices < img.ImageSeries
  %UNTITLED5 Summary of this class goes here
  %   Detailed explanation goes here
  
  properties
    Time
    X
    Y
  end
  
  properties (Dependent = true)
    %Array to store the slices in. First three dimensions are as Frames
    % and the fourth is "slice-wise", i.e. (y,x,frame,slice).
    Slices
    %Function which produces the frames from the slices. Should take the
    %data as the first argument, and the dimension to apply the function
    %along as the second. "mean" is the default, so will produce a slice
    %"average"
    FrameFun
    %Indices of slices to include in frames computed from slices
    FrameIncludeSlices
    %Frames computed from the subset 'FrameIncludeSlices' of slices using
    %FrameFun
    Frames
    NumSlices
  end
  
  properties (Access = private)
    pSlices
    pFrames
    pFrameFun = @mean
    pFrameIncludeSlices
  end
  
  methods
    function value = get.NumSlices(obj)
      value = size(obj.pSlices, 4);
    end

    function set.Slices(obj, value)
      obj.pSlices = value;
      obj.pFrameIncludeSlices = 1:size(value, 4);
      obj.framesChanged();
    end

    function value = get.Slices(obj)
      value = obj.pSlices;
    end

    function value = get.FrameFun(obj)
      value = obj.pFrameFun;
    end

    function set.FrameFun(obj, value)
      obj.pFrameFun = value;
      obj.framesChanged();
    end

    function set.FrameIncludeSlices(obj, value)
      obj.pFrameIncludeSlices = value;
      obj.framesChanged();
      notify(obj, 'FrameContentChanged');
    end

    function value = get.FrameIncludeSlices(obj)
      value = obj.pFrameIncludeSlices;
    end

    function value = get.Frames(obj)
      if isempty(obj.pFrames)
        % the frame generated from the slices needs to be computed
        sliceIndices = obj.pFrameIncludeSlices;
        obj.pFrames = obj.FrameFun(obj.pSlices(:,:,:,sliceIndices), 4);
      end
      value = obj.pFrames;
    end
    
    function v = sliceVectors(obj)
      sz = size(obj.Slices);
      sidx = obj.pFrameIncludeSlices;
      v = reshape(obj.Slices(:,:,:,sidx), prod(sz(1:3)), numel(sidx));
    end
  end
  
  methods (Access = protected)
    function framesChanged(obj)
      obj.pFrames = []; % reset the cached frames
      obj.framesChanged@img.ImageSeries;
    end
  end
  
  methods (Static)
    function [obj, includedTimes] = timeSlices(baseSeries, times, relTimeRange)
      %[obj, includedTimes] = timeSlices(baseSeries, times, relTimeRange)
      %baseSeries, the stack to take slices from.
      %times, should contain a list of times around which each slice is made.
      %relTimeRange, is the range around each time to make each slice.
      %Returns:
      %obj, the ImageSeriesSlices created.
      %includedTimes, is a flag vector indicating which time slices were actually
      %  included (i.e. each element relating to those in times vector).
      %  Time slices are only included for which the full range is
      %  available in the baseSeries.
      
      nFramesPerSlice = round(diff(relTimeRange)/baseSeries.dt);
      
      tMins = times + relTimeRange(1) - 0.5*baseSeries.dt;
      tMaxs = times + relTimeRange(2);
      % only include time slices which fully intersect with the available
      % data time. The upper bound is last time *minus meanDt* to be safe.
      includedTimes = tMins >= min(baseSeries.Time) &...
        tMaxs < max(baseSeries.Time);
      
      t0s = tMins(includedTimes);
      indices = arrayfun(@(t) find(baseSeries.Time >= t, 1), t0s);
      
      obj = img.ImageSeriesSlices.indexedSlices(baseSeries, indices, nFramesPerSlice);
      obj.Time = linspace(relTimeRange(1), relTimeRange(2), nFramesPerSlice);
      
%       tMins = times + relTimeRange(1) - 0.5*meanDt;
%       tMaxs = times + relTimeRange(2) + 0.5*meanDt;
%       % only include time slices which fully intersect with the available
%       % data time. The upper bound is last time *minus meanDt* to be safe.
%       includedTimes = tMins >= min(baseSeries.Time) + meanDt &...
%         tMaxs < max(baseSeries.Time) - meanDt;
%       
%       t0s = tMins(includedTimes);
%       indices = arrayfun(@(t) find(baseSeries.Time >= t, 1), t0s);
%       
%       obj = ImageSeriesSlices.indexedSlices(baseSeries, indices, nFramesPerSlice);
%       obj.Time = linspace(relTimeRange(1), relTimeRange(2), nFramesPerSlice);
    end
    
    function obj = indexedSlices(baseSeries, indices, nFramesPerSlice)
      %baseSeries is the stack to take slices from
      %indices should contain a list of indices to start each slice from
      %framePerSlice is the number of frames to take (starting from each
      %  index) for each slice.
      nSlices = numel(indices);
      slicesSize = [baseSeries.FrameSize, nFramesPerSlice, nSlices];
      obj = img.ImageSeriesSlices;
      
      obj.Info = baseSeries.Info;
      obj.Info.tags = [obj.Info.tags 'sliced'];
      obj.X = baseSeries.X;
      obj.Y = baseSeries.Y;
      
      allindices = ndgrid(0:nFramesPerSlice - 1, 1:numel(indices)) +...
        repmat(indices, nFramesPerSlice, 1);
      
      % if the baseSeries has a Time vector, use the average of the slices
      % as the Time vector for this Frame
      if ~isempty(baseSeries.Time)
        timeSlices = reshape(baseSeries.Time(allindices(:)), nFramesPerSlice, []);
        obj.Time = mean(cumsum([zeros(1, nSlices); diff(timeSlices, [], 1)]), 2);
      end
      
      obj.Slices = reshape(baseSeries.Frames(:,:,allindices(:)), slicesSize);
    end
  end
  
end

