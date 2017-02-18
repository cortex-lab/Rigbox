classdef ImageArray < img.ImageSeries
  %UNTITLED3 Summary of this class goes here
  %   Detailed explanation goes here
  
  properties
    X
    Y
  end
  
  properties (Dependent = true)
    Frames
    Time
  end
  
  properties (Access = private)
    pFrames
    pTime
  end
  
  methods
    function obj = ImageArray(frames, time, x, y, info)
      if nargin < 3 || isempty(x)
        x = 1:size(frames, 2);
      end
      if nargin < 4 || isempty(y)
        y = 1:size(frames, 1);
      end
      if nargin >= 5
        obj.Info = info;
      end
      
      obj.X = x;
      obj.Y = y;
      if nargin >= 2 && ~isempty(time)
        assert(numel(time) == size(frames, 3),...
          'length of time vector does not match number of frames');
        obj.pTime = time(:); % time always stored as a column vector
      end
      obj.Frames = frames;
    end

    function value = get.Frames(obj)
% % %       if isempty(obj.pFrames) && ~isempty(obj.BaseGenerator)
% % %         %if stored frames is empty, but a base generator exists, use it to
% % %         %generate the base images, and apply any transforms to it
% % %         obj.pFrames = obj.BaseGenerator();
% % %         obj.Y = 1:size(obj.pFrames, 1);
% % %         obj.X = 1:size(obj.pFrames, 2);
% % %         for j = 1:numel(obj.Transforms)
% % %           obj.pFrames = obj.Transforms{j}(obj);
% % %         end
% % %       end
      value = obj.pFrames;
    end
    
    function set.Frames(obj, value)
      obj.framesChanged(); % notify class that the frames have changed
      sizeChanged = ~isequal(size(value), size(obj.pFrames));
      obj.pFrames = value;
      % notify listeners of any structure change
      if sizeChanged
        notify(obj, 'FrameStructureChanged');
      end
      % always notify listeners that frames have changed
      notify(obj, 'FrameContentChanged');
    end
    
    function value = get.Time(obj)
      value = obj.pTime;
    end

    function [matPath, binPath] = fastSave(obj, path)
      %will save two files: <path>.mat and <path>.bin
      
      %create the structure to save as a MAT file
      s.framesSize = size(obj.pFrames);
      s.precision = class(obj.pFrames);
      s.t = obj.Time;
      s.x = obj.X;
      s.y = obj.Y;
      s.baseGenerator = obj.BaseGenerator;
      s.transforms = obj.Transforms;
      s.info = obj.Info;
      matPath = [path '.mat'];
      binPath = [path '.bin'];
      superSave(matPath, s);
      %save the image data as a binary file for speed
      fid = fopen(binPath, 'w');
      try
        fwrite(fid, obj.pFrames, s.precision);
        fclose(fid);
      catch ex
        fclose(fid);
        rethrow(ex);
      end
    end
  end
  
  methods (Static)
    function obj = fastLoad(path)
      %needs two files: <path>.mat and <path>.bin
      
      %load the structure with info
      s = load([path '.mat']);
       % bit of legacy file handling
      if ~isfield(s, 'info')
        % old system of storing title and units at the root with no meta
        % data
        s.info.title = s.title;
        %check title for an experiment ref, and if exists, set relevant
        %field
        expRef = regexp(s.info.title, data.expRefRegExp, 'match');
        if ~isempty(expRef)
          s.info.expRef = expRef{1};
        end
        s.info.units = s.units;
      end
      %load the image data from binary file, if it exists
      binpath = [path '.bin'];
      if file.exists(binpath)
        fid = fopen(binpath);
        try
          frames = reshape(fread(fid, inf, ['*', s.precision]), s.framesSize);
          fclose(fid);
        catch ex
          fclose(fid);
          rethrow(ex);
        end
        obj = img.ImageArray(frames, s.t, s.x, s.y, s.info);
      else
        %TODO: generate it
      end
      obj.BaseGenerator = fieldOrDefault(s, 'baseGenerator', []);
      obj.Transforms = fieldOrDefault(s, 'transforms', []);
    end
  end
  
end

