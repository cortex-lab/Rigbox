%% Updating Rigbox
% This guide contains infomation on how to update Rigbox and how to switch
% back to older versions.  Updates can either be done automatically via Git
% or manually.

%% Before you update
% It's often useful to read the release notes or CHANGELOG.  The former
% provides an overview of all changes, including a 'major changes' section
% which details the changes that may affect your analysis code or how
% experiments are run.  For instance changes to function names and
% signature are considered major changes.  
%
% Note that you will always be able to go back to previous releases (more
% below).  The CHANGELOG file will tell you what version of Rigbox you're
% currently using.

%% Automatic updating
% Update checks can be made when running either |mc| or |srv.expServer|.
% The 'updateSchedule' field in your |dat.paths| file determines when new
% code may be pulled from the master (most stable) branch.  Options include
% weekdays (e.g. 'Monday'), 'Never' (to never update), and 'Everyday' (to
% update every day).  String or cell arrays can be used to update on
% multiple days:
%
%  % Check for updates on Mondays and Fridays
%  p.updateSchedule = ["Monday", "Friday"];
%
% When updateSchedule is set for a particular day, the code is fetched on
% the day given, or if the code hasn't been fetched in over a week.  If the
% code has already been fetched for that day it won't be fetched again
% until the next scheduled day.  When updateSchedule is set to 'everyday',
% the code is fetched at most once an hour.
%
% *NB*: This requires Rigbox to be installed via Git (instructions can be
% found <./install.html here>).  The location of the Git Bash executable
% should be set in the 'gitExe' field in the |dat.paths| file.  The default
% path can be found in the <../scripts/paths_template.m paths_template>:
%
%   % Location of git for automatic updates
%   p.gitExe = 'C:\Program Files\Git\cmd\git.exe'; 
%

%% Updating manually via Git
% You can check for updates (and download them) by running |git.update| in
% the MATLAB command window.  
%
% To do this directly in Git:
% 
% # Open Git Bash
% # Change directory by typing |cd| and the path to your main Rigbox
% folder.  You can use a tilda as shorthand for C:/Users/<username>, e.g. 
% |cd ~/Documents/Github/Rigbox|
% # Type |git pull --recurse-submodules|.  The recurse flag ensures that
% signals, alyx-matlab, etc. are also updated.
% # Check the end of the message.  Ensure you don't see this messgae:
%
%  CONFLICT (content): Merge conflict in path/to/example_file.m
%  Automatic merge failed; fix conflicts and then commit the result.
% 
% This message means that there was a local change to the code which can't
% be merged with the recent remote changes.  If you're happy to discard
% your local changes you can run this command:
%
%  git reset --hard origin/master
%  git pull --recurse-submodules
%
% This resets the code to the current remote master branch state.  The
% second line ensures that the other modules are updates too.

%% Switching between releases
% On the all releases are tagged with a version number.  The most recent
% version, including patches, is on the master (stable) branch and can be
% updated by following the instructions in the previous section.
%
% To go back to a previous release version first list the versions
% available:
%
%   git.listVersions;
%
% To switch to one of the available versions run the following in the
% MATLAB command window:
%
%   git.switchVersion('2.4.0'); % Switch to version 2.4.0
%   git.switchVersion('latest'); % Switch to latest version
%   git.switchVersion('previous'); % Switch to the previous version
%   git.switchVersion(2.3); % Switch to the most recently patched version 2.3
%
% In Git Bash this can be done with the following command:
%
%  git checkout tags/version 2.1
%
% *NB*: Once you've switched to a specific version, the code will no longer
% update.
% 
% If you believe that the most recent commit on the master branch has
% caused a problem, either switch to the previous version (see above) or
% revert the most recent change with the following command in Git Bash:
%
%  git reset --hard master@{"10 minutes ago"}
%
% *NB*: By reverting the code in this way, the code will still update
% at the next scheduled time.

%% Updating without Git
% You can download the source code for the most recent version manually:
% 
% # navigate to the <https://github.com/cortex-lab/Rigbox/ Rigbox GitHub
% repository Webpage>
% # click the green button on the right-hand side that says 'Clone or
% download'
% # in the pop-up balloon click on 'Download ZIP'
% # replace the previous code with the code extracted from the zip file
% 
% To download a previous version:
%
% # go to <https://github.com/cortex-lab/Rigbox/releases>
% # under the release you wish to download, click the 'Assets' dropdown and
% download the Source code zip file
% # replace the previous code with the code extracted from the zip file
%

%% Etc.
% Author: Miles Wells
%
% v1.0.0
