---
name: Bug report
about: Create a report to help us improve
title: ''
labels: bug
assignees: ''

---

**Describe the bug**
A clear and concise description of what the bug is.  Feel free to paste in the error that was printed to the MATLAB command window.  

**To Reproduce**
Steps to reproduce the behavior.  Be as specific as possible.  Does the error always occur?  Are there similar steps that don't produce the error, or is it specific to a particular experiment?

**Expected behavior**
A clear and concise description of what you expected to happen.

**Screenshots**
If GUI related, add screenshots to help explain your problem.

**Desktop (please complete the following information):**
 - Code version (e.g. `2.3.1`) - you can find this in the `CHANGELOG.md` file, or provide the Git commit info by pasting the output of running `git log -1` in Git Bash (`git.runCmd('git log -1')` from MATLAB)
 - MATLAB version - run `ver` in the MATLAB command prompt and paste the output here.

**Additional context**
Try running the Rigbox tests and pasting the report here.
```
cd tests % cd into tests folder in Rigbox root directory
runall(1);
```
