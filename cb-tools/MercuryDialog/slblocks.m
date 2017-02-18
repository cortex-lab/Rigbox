function blkStruct = slblocks
blkStruct.Name = 'Mercury Blocks';
blkStruct.OpenFcn = 'Mercury';
blkStruct.MaskDisplay = '';
blkStruct.MaskInitialization = '';

Browser(1).Library = 'Mercury';
Browser(1).Name    = 'Mercury';
Browser(1).IsFlat  = 1;% Is this library "flat" (i.e. no subsystems)?

blkStruct.Browser = Browser;

% End of slblocks


