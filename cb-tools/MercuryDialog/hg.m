function out = hg(varargin)
% Copyright 2010 The MathWorks, Inc.
% hg: wrapper for Mercurial's command line tool hg
    if ispc
        xcd();
    end
    if iscell(varargin)
        command = ['hg ' makeargs(varargin)];
    else
        command = ['hg ' varargin];
    end
    if nargout > 0
        [~, out] = system(command);
    else
        system(command);
    end
end

function args = makeargs(arglist)
    args = [];
    for l = 1:length(arglist)
        args = [args ' "' arglist{l} '"'];
    end
end
