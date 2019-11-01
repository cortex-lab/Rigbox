function old = setTestFlag(TF)
% SETTESTFLAG Set global INTEST flag
%   Allows setting of test flag via callback function
global INTEST
old = INTEST;
INTEST = TF;
