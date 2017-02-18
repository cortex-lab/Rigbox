% Copyright 2010 The MathWorks, Inc.
% hgia_setup: setup default settings of Mercurial for use with SimulinkHg
function hgia_setup
    %% check if mercurial already has a default config file
    if ispc
        hgrc = [getenv('HOME') filesep 'Mercurial.ini'];
        have_hgrc = exist(hgrc,'file');
        if ~have_hgrc
            hgrc = [getenv('HOME') filesep '.hgrc'];
            have_hgrc = exist(hgrc,'file');
        end
        if ~have_hgrc
            hgrc = [getenv('USERPROFILE') filesep '.hgrc'];
            have_hgrc = exist(hgrc,'file');
        end
        if ~have_hgrc
            hgrc = [getenv('USERPROFILE') filesep 'Mercurial.ini'];
            have_hgrc = exist(hgrc,'file');
        end
    else
        hgrc = [getenv('HOME') filesep '.hgrc'];
        have_hgrc = exist(hgrc,'file');
    end
    
    %% if there is no hg config file we can create one for the user
    if ~have_hgrc
        a = questdlg('Do you want to create a basic setup for Mercurial?');
        switch a
            case 'Cancel'
                close(handles.hgwindow);
                return
            case 'No'
            case 'Yes'
                username = inputdlg('Username <e-mail>: ','Enter your username');
                if isempty(username)
                    close(handles.hgwindow);
                    return
                end
                hgrcf = fopen(hgrc,'w');
                fprintf(hgrcf,'[ui]\nusername=%s\n\n[extensions]\nhgext.purge=\nhgext.extdiff=\nrebase=\n',username{1});
                fclose(hgrcf);
        end
    end
end
