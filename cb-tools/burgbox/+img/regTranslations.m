function [dx, dy, target] = regTranslations(movie, target, varargin)
% registration Movie frame registration to a target frame using 
% parallelisation and array vectorisation for efficiency
%
%   [DX, DY, TARGET] = rapidReg(MOVIE, TARGET,...) find registration of
%   MOVIE (an (Y,X,T) array) to TARGET (either the target image frame (Y,X)
%   or 'auto', to find one automatically). Returns the translations required
%   to register each frame, DX and DY, and TAGRET, the target frame. 
%   Optionally takes, 'noparallel', meaning use single-threaded codepath 
%   instead of parallel.

% 2013-07 CB created (heavily plagiarised from Mario Dipoppa's code)

[h, w, nFrames] = size(movie);

%% Setup
%create a Gaussian filter for filtering registration frames
hGauss = fspecial('gaussian', [5 5], 1);

%look for flag on whether to use parallel codepath
if any(cell2mat(strfind(varargin, 'nopar')) == 1)
  parallel = false;
else
  parallel = true;
end

nMsgChars = 0;

%% If requested, compute best target frame
if strcmpi(target, 'auto')
  
  nMsgChars = nMsgChars + overfprintf(0, 'finding target..');
  %first compute a smoothed mean of each frame
  meanF = smooth(mean(reshape(movie, h*w, nFrames)));
  %now look in the middle third of the image frames for the minimum
  fromFrame = round(nFrames*1/3);
  toFrame = round(nFrames*2/3);
  [~, idx] = min(meanF(fromFrame:toFrame));
  minFrame = fromFrame + idx;
  %Gaussian filter the target image
  target = imfilter(movie(:,:,minFrame), hGauss, 'same', 'replicate');
end

%% Fourier transform the filtered movie frames for registration
nMsgChars = nMsgChars + overfprintf(0, 'filtering..');
ftFilteredMovie = fft2(imfilter(movie, hGauss, 'same', 'replicate'));

ftTarget = fft2(target);

%% Compute required displacement and register each frame
dx = zeros(1, nFrames);
dy = zeros(1, nFrames);
nMsgChars = nMsgChars + overfprintf(0, 'registering..');

if parallel
  %% Register in parallel
  temporaryPool = matlabpool('size') == 0;
  if temporaryPool
    matlabpool('open');%create default worker pool
  end
  try
    %do parallel loops in chunks of data to prevent matlab choking
    chunkSize = 14000; %frames
    nChunks = ceil(nFrames/chunkSize);
    progressStepSize = 100;
%     pctRunOnAll('mattoolsJava');
%     ppm = ParforProgMon('Registration: ', nFrames, progressStepSize, 300, 80);
    for i = 0:(nChunks - 1)
      sidx = i*chunkSize + 1;
      eidx = min((i + 1)*chunkSize, nFrames);
      n = eidx - sidx + 1;
      parfor t = sidx:eidx
        %find the best registration translation
        output = dftregistration(ftTarget, ftFilteredMovie(:,:,t), 20);
        dx(t) = output(4);
        dy(t) = output(3);
        
        if mod(t, progressStepSize) == 0
%           ppm.increment();
        end
      end
    end
%     ppm.delete();
    if temporaryPool
      matlabpool('close'); %close worker pool
    end
  catch ex
    if temporaryPool
      %in case of error, ensure temporary worker pool is closed
      matlabpool('close');
    end
    rethrow(ex)
  end
else
  %% Register sequentially
  for t = 1:nFrames
    %find the best registration translation
    output = dftregistration(ftTarget, ftFilteredMovie(:,:,t), 20);
    dx(t) = output(4);
    dy(t) = output(3);
  end
end

overfprintf(nMsgChars);

end

