# Contributing

When contributing to this repository, please first discuss the change you wish to make via issue,
email, or any other method with the owners of this repository before making a change. 

Please note we have a code of conduct, please follow it in all your interactions with the project.

## Pull Request Process

We have two main branches: the dev branch where we deploy new features and the master branch which contains the stable build that most users will work with.  Below is the general for adding a new feature:

1. Ensure any new code is accompanied by a test that adequately covers all expected use cases, and [MATLAB documentation](https://www.mathworks.com/help/matlab/matlab_prog/add-help-for-your-program.html)
2. Update the README.md with details of changes to the interface, wherever relavent.  This includes changes to any major UIs or install scripts.  It's worth also ensuring the configuration scripts and tutorials in the docs/ dirctory are up to date.
3. Create a pull request to merge into the dev branch.  Before merging the code must pass all tests and be approved by one reviewer.
4. Once merged into dev the changes may be summerized in the release notes.
5. Once there have been sufficient changes to the dev branch to be considered a major version and all changes have been deployed for at least a week, the team will open a pull request to merge into the master branch.
6. Before merging into master the submodule dependencies should be updated and checked first.  The previous code is archived in the releases tab.
3. Increase the version numbers in any examples files and the README.md to the new version that this
   Pull Request would represent. The versioning scheme we use is [SemVer](http://semver.org/).
4. You may merge the Pull Request in once you have the sign-off of two other developers, or if you do not have permission to do that, you may request the second reviewer to merge it for you.

## Style guidelines

Although there aren't any strict guidelines we suggest making your code as consistent with the rest of the repository as possible.  Some examples:
* Variables and function names generally follow the MATLAB convention of 'Dromedary case' (`expRef`, `inferParameters`) and when defining a commonly used variable be consistent with the names in other files.  If assigning an output of a function, try to use name defined in that functions' header (`[expRef, expDate, expSequence] = listExps(subjects)`).  
* Class names and properties are in 'camel case' (`AlyxPanel`, `obj.Token`).
* In general clarity > brevity.  Don't be afraid to spread things out over a number of lines and to add in-line comments.  Long variable names are often much clearer (`inputSensorPosCount` vs `iputPosN`).
* There are a number of utility functions in [cb-tools](https://github.com/cortex-lab/Rigbox/tree/master/cb-tools/burgbox) that we encourage the use of.  Many of these implementations of functional programming methods.
* Information on the physical organization of the repository can be found [here](https://github.com/cortex-lab/Rigbox/issues/123#issue-422187511).

## Code of Conduct

### Our Pledge

In the interest of fostering an open and welcoming environment, we as
contributors and maintainers pledge to making participation in our project and
our community a harassment-free experience for everyone, regardless of age, body
size, disability, ethnicity, gender identity and expression, level of experience,
nationality, personal appearance, race, religion, or sexual identity and
orientation.

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
behavior and are expected to take appropriate and fair corrective action in
response to any instances of unacceptable behavior.

Project maintainers have the right and responsibility to remove, edit, or
reject comments, commits, code, wiki edits, issues, and other contributions
that are not aligned to this Code of Conduct, or to ban temporarily or
permanently any contributor for other behaviors that they deem inappropriate,
threatening, offensive, or harmful.

### Scope

This Code of Conduct applies both within project spaces and in public spaces
when an individual is representing the project or its community. Examples of
representing a project or community include using an official project e-mail
address, posting via an official social media account, or acting as an appointed
representative at an online or offline event. Representation of a project may be
further defined and clarified by project maintainers.

### Enforcement

Instances of abusive, harassing, or otherwise unacceptable behavior may be
reported by contacting the project team at [INSERT EMAIL ADDRESS]. All
complaints will be reviewed and investigated and will result in a response that
is deemed necessary and appropriate to the circumstances. The project team is
obligated to maintain confidentiality with regard to the reporter of an incident.
Further details of specific enforcement policies may be posted separately.

Project maintainers who do not follow or enforce the Code of Conduct in good
faith may face temporary or permanent repercussions as determined by other
members of the project's leadership.

### Attribution

This Code of Conduct is adapted from the [Contributor Covenant][homepage], version 1.4,
available at [http://contributor-covenant.org/version/1/4][version]

[homepage]: http://contributor-covenant.org
[version]: http://contributor-covenant.org/version/1/4/
