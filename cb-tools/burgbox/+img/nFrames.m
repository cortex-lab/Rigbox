function n = nFrames(tiff)
%nFrames find the number of frames in the Tiff

%keep guessing until we seek too far
guess = 1000;

if ischar(tiff)
  tiff = Tiff(tiff, 'r');
  closeTiff = onCleanup(@() close(tiff));
end

while true
  try
    tiff.setDirectory(guess);
    guess = 2*guess; %double the guess
  catch ex
    %now seek frame by frame to the last directory
    while ~tiff.lastDirectory
      tiff.nextDirectory();
    end
    break %break out of the loop
  end
end
%when overseeking occurs, the current directory/frame will be the last one
n = tiff.currentDirectory;

end

