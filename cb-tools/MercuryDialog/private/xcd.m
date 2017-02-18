% Copyright 2010 The MathWorks, Inc.
% xcd: cd wrapper for portable interaction with Mercurial
function wd = xcd(wd)
    if nargin < 1 || isempty(wd)
        wd = pwd;
    end
    if ~ispc
        return
    end
    owd = wd;
    wd(wd=='/') = filesep;
    if wd(end) ~= filesep
        wd(end+1) = filesep;
    end
    fs = find(wd == filesep);
    for p = 1:length(fs)-1
        entr = dir(wd(1:fs(p)));
        for e = 1:length(entr)
            if strcmpi(entr(e).name,wd(fs(p)+1:fs(p+1)-1))
                wd(fs(p)+1:fs(p+1)-1) = entr(e).name;
                break
            end
        end
    end
    if ~strcmp(owd,wd)
        cd(wd);
    end
end
