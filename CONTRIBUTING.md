When contributing to this repository, please first discuss the change you wish to make via creation of a [github issue](https://github.com/cortex-lab/Rigbox/issues) (preferred), or email with the [project maintainers](#project-maintainers). 

Please adhere to our [Code of Conduct](#code-of-conduct).

We roughly follow a [gitflow workflow](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow) without using 'git-flow' extensions. We also support [forking workflows](https://www.atlassian.com/git/tutorials/comparing-workflows/forking-workflow) for contributors who wish to fork this repository and maintain their own local versions. 

If you are unfamiliar with repositories with submodules, please first read this helpful [blog post.](https://github.blog/2016-02-01-working-with-submodules/)

## Contributing - Our Pull Request Process

Following the gitflow workflow, Rigbox and its main submodules (signals, alyx-matlab, and wheelAnalysis) each have two main branches: the dev branch is where new features are deployed, and the master branch contains the stable build that most users will work with. Contributors should create a new feature branch for any changes/additions they wish to make. Contributors should then create a pull request for the feature branch. If making a change to a submodule, a pull request should be sent to that submodule's repository. (e.g. if a user is making a change to a file within the signals repository, a pull request should be made to the [signals repository](https://github.com/cortex-lab/signals/pulls), not to the Rigbox repository.) **All pull requests should be made to the dev branch of the appropriate repository.** All pull requests will be reviewed by the project maintainers. Below are procedural guidelines to follow for contributing via a pull request:

1. Ensure any new file follows [MATLAB documentation guidelines](https://www.mathworks.com/help/matlab/matlab_prog/add-help-for-your-program.html) and is accompanied by a test file that adequately covers all expected use cases. This test file should be placed in the appropriate repository's 'tests' folder, and follow the naming convention of `<newFile>_test`. If the contributor is not adding a new file but instead changing/adding to an exisiting file that already has an accompanying test file, a test that accompanies the contributor's code should be added to the existing test file. See the [Rigbox/tests folder](https://github.com/cortex-lab/Rigbox/tree/dev/tests) for examples.

2. Ensure all existing tests for the entire repo pass. To do so, in MATLAB within the `Rigbox/tests` folder, run 
> [exitStatus, failures] = runall();
	
If `exitStatus` returns as 0, all tests passed. Note that the MATLAB environment (i.e. MATLAB version and dependent toolbox versions of the [toolboxes listed here](https://github.com/cortex-lab/Rigbox#prerequisites)) in which the project maintainers run these tests may differ from the contributor's MATLAB environment. Failures that the contributor suspects are due to a specific MATLAB environment amongst those for which Rigbox maintains support should be reported as issues. If possible, contributors should compare tests results in one environment with the most up-to-date MATLAB environment which Rigbox supports in order to confirm that a different environment is what caused the failures.

3. When making changes to the interface, update the README.md with relevant details. This includes changes to any major UIs or installation scripts. It's also worth ensuring the configuration scripts and tutorials in the 'docs' folder for Rigbox, and the 'docs' folder for any submodule(s) which may have been changed, are up-to-date.

4. Create a pull request to merge the contributed branch into the dev branch. The submodule dependencies should be first checked and updated, if necessary. The branch will then be merged upon approval by at least one authorized reviewer. Once merged into dev, the changes may be summarized in the release notes.

5. Once the dev branch has accumulated sufficient changes for it to be considered a new major version, and all changes have been deployed for at least a week, the project maintainers will open a pull request to merge dev into the master branch. The project maintainers should ensure that the version numbers, README.md and CHANGELOG.md are up-to-date. The versioning specification numbering used is [SemVer](http://semver.org/). Previous versions are archived in [releases](https://github.com/cortex-lab/Rigbox/releases).

## Style Guidelines

Although there aren't any strict guidelines, we suggest making your code as consistent with the rest of the repository as possible. Some examples:
* For a particularly well-documented function, see ['sig.timeplot'](https://github.com/cortex-lab/signals/blob/259fbaf34316bc4e77a1089e8b972c60d5dab3a1/%2Bsig/timeplot.m). For a particularly well-documented class, see ['hw.Timeline'](https://github.com/cortex-lab/Rigbox/blob/dev/%2Bhw/Timeline.m) 
* Variables and function names generally follow the MATLAB convention of 'Dromedary case' (e.g. `expRef`, `inferParameters`).
* Class names and properties are in 'camel case' (e.g. `AlyxPanel`, `obj.Token`).
* When defining commonly used variables, be consistent with the names across files. 
* If assigning an output of a function, try to use the name defined in that functions' header (e.g. `[expRef, expDate, expSequence] = listExps(subjects)`).  
* In general, clarity > brevity. Don't be afraid to spread things out over a number of lines and to add in-line comments. Long variable names are often much clearer (e.g. `inputSensorPosCount` vs `inpPosN`).
* There are a number of utility functions in [cb-tools](https://github.com/cortex-lab/Rigbox/tree/master/cb-tools/burgbox) that we encourage the use of. Many of these are implementations of functional programming methods.
* Information on the physical organization of the repository can be found [here](https://github.com/cortex-lab/Rigbox/issues/123#issue-422187511).

## Project Maintainers

Rigbox is currently maintained and developed by Miles Wells (miles.wells@ucl.ac.uk), Jai Bhagat (j.bhagat@ucl.ac.uk), and a number of others at [CortexLab](https://www.ucl.ac.uk/cortexlab). The majority of the code was written by [Chris Burgess](https://github.com/dendritic/). 

## Code of Conduct

### Our Pledge

In the interest of fostering an open and welcoming environment, we as
maintainers and contributors pledge to make participation in our project and
our community an enjoyable and harassment-free experience for everyone.

### Our Standards

Examples of behavior that contributes to creating a positive environment
include:

* Using welcoming and inclusive language
* Being respectful of differing viewpoints and experiences
* Gracefully accepting constructive criticism
* Focusing on what is best for the community
* Showing empathy towards other community members

Examples of unacceptable behavior by participants include:

* The use of sexualized language or imagery and unwelcome sexual attention or
advances
* Trolling, insulting/derogatory comments, and personal or political attacks
* Public or private harassment
* Publishing others' private information, such as a physical or electronic
  address, without explicit permission
* Other conduct which could reasonably be considered inappropriate in a
  professional setting

### Our Responsibilities

Project maintainers are responsible for clarifying the standards of acceptable
behavior, and are expected to take appropriate and fair corrective action in
response to any instances of unacceptable behavior.

Project maintainers have the right and responsibility to remove, edit, or
reject comments, commits, code, wiki edits, issues, and other contributions, particularly those
that are not aligned to this Code of Conduct. 

Project maintainers may ban temporarily or permanently any contributor for behaviors that are deemed inappropriate, threatening, offensive, or harmful.

### Scope

This Code of Conduct applies both within project spaces and in public spaces
when an individual is representing the project or its community. Examples of
representing a project or community include using an official project e-mail
address, posting via an official social media account, or acting as an appointed
representative at an online or offline event. Representation of a project may be
further defined and clarified by project maintainers.

### Enforcement

Instances of abusive, harassing, or otherwise unacceptable behavior may be
reported by contacting the project maintainers. All complaints will be reviewed and investigated, and will result in a response that is deemed necessary and appropriate to the circumstances.

Project maintainers who do not follow or enforce the Code of Conduct in good
faith may face temporary or permanent repercussions as determined by other
members of the project's leadership.

### Attribution

This Code of Conduct is adapted from the [Contributor Covenant][homepage], version 1.4,
available at [http://contributor-covenant.org/version/1/4][version]

[homepage]: http://contributor-covenant.org
[version]: http://contributor-covenant.org/version/1/4/
