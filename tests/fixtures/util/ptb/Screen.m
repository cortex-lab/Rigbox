function varargout = Screen(varargin)
% % Copy an image, very quickly, between textures, offscreen windows and onscreen windows.
% [resident [texidresident]] = Screen('PreloadTextures', windowPtr [, texids]);
% Screen('DrawTexture', windowPointer, texturePointer [,sourceRect] [,destinationRect] [,rotationAngle] [, filterMode] [, globalAlpha] [, modulateColor] [, textureShader] [, specialFlags] [, auxParameters]);
% Screen('DrawTextures', windowPointer, texturePointer(s) [, sourceRect(s)] [, destinationRect(s)] [, rotationAngle(s)] [, filterMode(s)] [, globalAlpha(s)] [, modulateColor(s)] [, textureShader] [, specialFlags] [, auxParameters]);
% Screen('CopyWindow', srcWindowPtr, dstWindowPtr, [srcRect], [dstRect], [copyMode])
%
% % Copy an image, slowly, between matrices and windows :
% imageArray=Screen('GetImage', windowPtr [,rect] [,bufferName] [,floatprecision=0] [,nrchannels=3])
% Screen('PutImage', windowPtr, imageArray [,rect]);
%
% % Synchronize with the window's screen (on-screen only):
% [VBLTimestamp StimulusOnsetTime swapCertainTime] = Screen('WaitUntilAsyncFlipCertain', windowPtr);
% [info] = Screen('GetFlipInfo', windowPtr [, infoType=0] [, auxArg1]);
% [telapsed] = Screen('DrawingFinished', windowPtr [, dontclear] [, sync]);
% framesSinceLastWait = Screen('WaitBlanking', windowPtr [, waitFrames]);
%
% % Load color lookup table of the window's screen (on-screen only):
% [gammatable, dacbits, reallutsize] = Screen('ReadNormalizedGammaTable', windowPtrOrScreenNumber [, physicalDisplay]);
% [oldtable, success] = Screen('LoadNormalizedGammaTable', windowPtrOrScreenNumber, table [, loadOnNextFlip][, physicalDisplay][, ignoreErrors]);
% oldclut = Screen('LoadCLUT', windowPtrOrScreenNumber [, clut] [, startEntry=0] [, bits=8]);
%
% % Get (and set) information about a window or screen:
% windowPtrs=Screen('Windows');
% kind=Screen(windowPtr, 'WindowKind');
% isOffscreen=Screen(windowPtr,'IsOffscreen');
% hz=Screen('FrameRate', windowPtrOrScreenNumber [, mode] [, reqFrameRate]);
% hz=Screen('NominalFrameRate', windowPtrOrScreenNumber [, mode] [, reqFrameRate]);
% [ monitorFlipInterval nrValidSamples stddev ]=Screen('GetFlipInterval', windowPtr [, nrSamples] [, stddev] [, timeout]);
% screenNumber=Screen('WindowScreenNumber', windowPtr);
% pixelSize=Screen('PixelSize', windowPtrOrScreenNumber);
% pixelSizes=Screen('PixelSizes', windowPtrOrScreenNumber);
% [width, height]=Screen('WindowSize', windowPointerOrScreenNumber [, realFBSize=0]);
% [width, height]=Screen('DisplaySize', ScreenNumber);
% [oldmaximumvalue, oldclampcolors, oldapplyToDoubleInputMakeTexture] = Screen('ColorRange', windowPtr [, maximumvalue][, clampcolors][, applyToDoubleInputMakeTexture]);
% info = Screen('GetWindowInfo', windowPtr [, infoType=0] [, auxArg1]);
% resolutions=Screen('Resolutions', screenNumber);
% oldResolution=Screen('Resolution', screenNumber [, newwidth] [, newheight] [, newHz] [, newPixelSize] [, specialMode]);
% oldSettings = Screen('ConfigureDisplay', setting, screenNumber, outputId [, newwidth][, newheight][, newHz][, newX][, newY]);
% Screen('ConstrainCursor', windowIndex, addConstraint [, rect]);
%
% % Get/set details of environment, computer, and video card (i.e. screen):
% struct=Screen('Version');
% comp=Screen('Computer');
%
% % Helper functions.  Don't call these directly, use eponymous wrappers:
% [x, y, buttonVector, hasKbFocus, valuators]= Screen('GetMouseHelper', numButtons [, screenNumber][, mouseIndex]);
% Screen('HideCursorHelper', windowPntr [, mouseIndex]);
% Screen('ShowCursorHelper', windowPntr [, cursorshapeid][, mouseIndex]);
% Screen('SetMouseHelper', windowPntrOrScreenNumber, x, y [, mouseIndex][, detachFromMouse]);
% Screen('SetMouseHelper', windowPntrOrScreenNumber, x, y [, mouseIndex][, detachFromMouse]);
%
% % Internal testing of Screen
% timeList= Screen('GetTimelist');
% Screen('ClearTimelist');
% Screen('Preference','DebugMakeTexture', enableDebugging);
%
% % Support for 3D graphics rendering and for interfacing with external OpenGL code:
% [targetwindow, IsOpenGLRendering] = Screen('GetOpenGLDrawMode');
% [textureHandle rect] = Screen('SetOpenGLTextureFromMemPointer', windowPtr, textureHandle, imagePtr, width, height, depth [, upsidedown][, target][, glinternalformat][, gltype][, extdataformat][, specialFlags]);
% [textureHandle rect] = Screen('SetOpenGLTexture', windowPtr, textureHandle, glTexid, target [, glWidth][, glHeight][, glDepth][, textureShader][, specialFlags]);
% [ gltexid gltextarget texcoord_u texcoord_v ] =Screen('GetOpenGLTexture', windowPtr, textureHandle [, x][, y]);
%
% % Support for plugins and for builtin high performance image processing pipeline:
% [ret1, ret2, ...] = Screen('HookFunction', windowPtr, 'Subcommand', 'HookName', arg1, arg2, ...);
% proxyPtr = Screen('OpenProxy', windowPtr [, imagingmode]);
% transtexid = Screen('TransformTexture', sourceTexture, transformProxyPtr [, sourceTexture2][, targetTexture][, specialFlags]);

% % Draw Text in windows
% [oldFontName,oldFontNumber,oldTextStyle]=Screen('TextFont', windowPtr [,fontNameOrNumber][,textStyle]);
% [normBoundsRect, offsetBoundsRect, textHeight, xAdvance] = Screen('TextBounds', windowPtr, text [,x] [,y] [,yPositionIsBaseline] [,swapTextDirection]);
% [newX, newY, textHeight]=Screen('DrawText', windowPtr, text [,x] [,y] [,color] [,backgroundColor] [,yPositionIsBaseline] [,swapTextDirection]);
% oldTextColor=Screen('TextColor', windowPtr [,colorVector]);
% oldTextBackgroundColor=Screen('TextBackgroundColor', windowPtr [,colorVector]);
% oldMatrix = Screen('TextTransform', windowPtr [, newMatrix]);

% global INTEST
% persistent history
% 
% if isempty(INTEST) || ~INTEST
%   error('Rigbox:tests:Screen:notInTest', 'Screen called while out of test')
% end
% 
% if isempty(history)
%   history = containers.Map('KeyType', 'int32', 'ValueType', 'any');
% end
% 
% if strcmp(varargin{1}, 'GetHistory')
%   time = history;
% else
%   key = length(history) + 1;
%   history(key) = varargin;
%   time = GetSecs;
% end

persistent argMap
if isempty(argMap)
  
  functions = {...
    'Close' % 0
    'CloseAll'
    'glPushMatrix'
    'glPopMatrix'
    'glLoadIdentity'
    'glTranslate'
    'glScale'
    'glRotate'
    'DrawLine'
    'DrawArc'
    'FrameArc'
    'FillArc'
    'FillRect'
    'FrameRect'
    'FillOval'
    'FrameOval'
    'FramePoly'
    'FillPoly'
    'BeginOpenGL'
    'EndOpenGL'
    'Preference' % 1
    'Screens'
    'Windows'
    'Rect'
    'TextModes'
    'TextMode'
    'TextSize'
    'TextStyle'
    'MakeTexture'
    'PanelFitter'
    'SelectStereoDrawBuffer'
    'OpenWindow' % 2
    'OpenOffscreenWindow'
    'Flip' % 5
    'AsyncFlipBegin'
    'AsyncFlipEnd'
    'AsyncFlipCheckEnd'};

  nArgs = [zeros(1,20), ones(1,11), 2, 2, 5, 5, 5, 5];
  argMap = containers.Map(functions, num2cell(nArgs));
end

if strcmp(varargin{1}, 'Rect')
  varargout = {randi(100, 1, 4)};
else
  varargout = deal(num2cell(randi(10, 1, argMap(varargin{1}))));
end