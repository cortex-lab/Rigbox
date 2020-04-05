%% Contributing to the documentation
% These docs are all made in MATLAB using the
% <https://uk.mathworks.com/help/matlab/matlab_prog/publishing-matlab-code.html
% publish> feature.  This page explains how to make changes to the docs so
% that they make it on the <https://cortex-lab.github.io/Rigbox Rigbox
% Documentation Website>.

%% Organization
% There are two folders in 'rigbox/docs', one called 'scripts' which
% contains the source files that you can edit, and one called 'html', which
% contains the exported html copies, as well as any images you want to add.
%
% The home page can be found in 'index.m'.  This script should have links
% to all other pages in the documentation for easy navigation. 

%% File markup
% MATLAB has a rather idiosyncratic markup syntax which takes some getting
% used to.  For an informative guide on how to format things correctly in
% your scripts, see their
% <https://uk.mathworks.com/help/matlab/matlab_prog/marking-up-matlab-comments-for-publishing.html
% markup guide>.

%% Publishing changes
% The scripts folder contains one special function called |fixFiles| which
% will export the scripts for you and also do some optional
% post-processing.
help fixFiles

%% Committing changes to Github
% In order to avoid overwriting other people's changes, please commit any
% documentation changes to the 'documentation' branch Rigbox.  Please don't
% commit any changes that affect actual Rigbox code, only files in the
% 'docs' folder or function docstrings.  Any other changes should be made
% on a feature branch off dev (see <CONTRIBUTING.md> for more details).
% Below are some steps to follow when making minor changes: 
%
% # Switch to the documentation branch by running |git checkout
% origin/documentation|
% # Make your changes to one of the scripts, e.g. index.m.  At the bottom
% of the page, make sure the version number is increased, e.g. 0.1.3 ->
% 0.1.4
% # Publish them by calling |fixFiles('changed')|
% # Check that your changes look OK by opening the changed files in your
% browser, e.g. docs/html/index.html.  This is important because the markup
% can sometimes not work as expected.
% # In Git Bash run |git pull| to make sure your local branch is fully
% up-to-date with the remote one.
% # Commit your changes to the branch by running e.g. |git commit -am
% "Fixed typo in index.m"|
% # Push your local changes to the remote repository: |git push|

%% Updating the Website
% The above steps will commit your changes to the documentation branch,
% which every so often will be merged into dev and master so that
% everyone's local documentation is the same.  
%
% To propogate these changes to the github.io site, we have to merge the
% documentation branch into the gh-pages branch following the below steps:
%
% # Switch to the gh-pages branch: |git checkout origin/gh-pages|
% # Fetch the latest changes from the documentation branch to make sure
% you're fully up-to-date: |git fetch origin/documentation|
% # Merge the docmentation branch into gh-pages: |git merge documentation|
% # Now copy all the files from Rigbox/docs/html to Rigbox/
% # Stage these modified doc files using git add, e.g. |git add index.html|
% # Commit the changes.  The amend flag can be used here: |git commit
% --amend|
% # Push the changes to the remote: |git push|
%
% You may receive an email with a build warning saying something like 'The
% page build completed successfully, but returned the following warning for
% the `gh-pages` branch: It looks like you're using GitHub Pages to
% distribute binary files'.  This warning can be safely ignored.  
% 
% Note that the files used by the Website have to be in the root directory
% of the gh-pages branch.  If your files aren't copied from the docs/html
% folder to the root folder they won't be visible on the Website.
%
% If this seems daunting, you can simply leave your changes on the
% documentation branch and the changes will make their way to the write
% place when someone else pushes their edits.  Another option is to email
% me the edited script and I'll do it for you :)

%% Tips:
% If you want to add a completely new page, simply create a new script in
% docs/scripts (e.g. 'how_to_blah.m' - you can call it anything), then add
% a link to it in the 'index.m' script so people can find it.  Feel free to
% inter-link between files are much as possible.  Likewise you can add new
% sections to the index page with links to guides in a different order,
% e.g. you might want a list of pages for users setting up new rigs. 
%
% At the bottom of each file make sure there is an author and version.
% This helps people track changes to the documentation.
%
% Links should be relative to the index page.  Starting with |./| means
% 'realtive to the current folder.  It's easiest to just keep all html
% files in one folder, then interlinking is kept simple.  
%
% There is an images folder in the html folder.  Some but not all of the
% images are here.  Linking to an image in the images folder works thus:
% |./images/image_01.png|.
%
% By default the scripts exported with |fixFiles| do not execute any of the
% code.  If you want to export the output of the code in a script, add the
% name of the script to the `evalOn` array on (or near) line 42 of
% |fixFiles|, e.g.

% Files whose code should be evaluated
evalOn = ["using_test_gui.m", "SignalsPrimer.m", "how_to_blah.m"];

%%%
% If you want to do some fancy post-processing to your file, e.g. add
% JavaScript or some feature that can't be done in the markup, add a
% section to |fixFiles| that loads the html file, edit the source code and
% write back into the file.  This will be executed each time the file is
% re-exported.  
%
% Sometimes MATLAB (or other programs) can prevent these files from being
% written to, or prevents Git from changing branches (you will see a
% message in Git Bash the following:
%
%    Unlink of file 'docs/html/how_to_blah.html' failed. Should I try again? (y/n)
%
% If this happens simply close MATLAB and any open pages in your browser,
% then try again.

%% Etc.
% Author: Miles Wells
%
% v0.0.1
