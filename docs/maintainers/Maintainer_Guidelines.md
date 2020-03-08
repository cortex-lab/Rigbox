The purpose of this document is to establish a protcol for the project maintainers to follow when adding and reviewing new code. For contributing new code to this repository, we roughly follow a [gitflow workflow](https://nvie.com/posts/a-successful-git-branching-model). We also support [forking workflows](https://www.atlassian.com/git/tutorials/comparing-workflows/forking-workflow) for contributors who wish to fork this repository and maintain their own local versions. 

## Style Guidelines

[Richard Johnson](https://uk.mathworks.com/matlabcentral/profile/authors/22731-richard-johnson) writes, "Style guidelines are not commandments. Their goal is simply to help programmers write well." Well-written code implies code that is easy to read. Code that is easy to read is typically written in a consistent style, so new code should be as consistent as possible with the rest of the repository.

A file's header documentation (aka a docstring) is written as follows:
* Functions have the following sections in the given order:
	- One-line summary description
	- Long description
	- Inputs
	- Outputs
	- Examples
	- See also
	- Warnings/Exceptions (optional)
	- Additional notes (optional)
	- Todos (optional)
* Classes have the following sections in the given order:
	- One-line summary description
	- Long description
	- Examples
	- See also
	- Warnings/Exceptions (optional)
	- Additional notes (optional)
	- Todos (optional)

A file's body documentation should adhere to the following:
* For classes, each method, property, and event should be documented. Method docstrings only need contain the 'One-line summary description' and 'Examples' sections. Additional explanations should be given for methods, properties, and events that are within blocks that are given non-default attributes. e.g.
```
properties (Dependent)
  % `Dependent` because...
  property1
end

methods (Access=protected)
  % `Access=protected` because...
  method1
end

events (ListenAccess=private)
  % `ListenAccess=private` because...
  event1
end
```
* Whitespace conventions:
	- A tab/indent is set at two spaces.
	- Whitespace between lines is used sparingly, but can be used to improve readability between blocks of code.
	- Each line contains no more than 75 characters. Whitespace should be used to align statements that span multiple lines via a hanging indent or single indent e.g.
	```
	stash = ['stash push -m "stash working changes before '...
             'scheduled git update"'];
	```
* Block quotes should be written as full sentences above the corresponding code. e.g.
  ```
  % Check that the inputs are properly defined.
  if len(varargin) ~= 1 && len(varargin) ~= 2 ...
  ```
* Inline quotes should be written as a short phrase that starts two spaces after the corresponding code. e.g.
  ```
  if len(varargin) == 1  % return input
  ```
* Variables should be documented where they are declared. e.g.
  ```
  % The Rigbox root directory
  root = getOr(dat.paths, 'rigbox');
  ```
* Variable names referenced in comments are surrounded by back ticks for readability e.g.
  ```
  % New signal carrying `a` with its rows flipped in the up-down direction
  b = flipud(a);
  ```
* In general, clarity > brevity. Don't be afraid to spread things out over a number of lines and to add block and in-line comments. Long variable names are often much clearer (e.g. `inputSensorPosCount` instead of `inpPosN`).
* ["Scare quotes"](https://www.chicagomanualofstyle.org/qanda/data/faq/topics/Punctuation/faq0014.html) are generally to be avoided.

Additional conventions:
* Naming conventions:
	- Variable and function names are in lower camelCase (e.g. `expRef`, `inferParameters`)
	- Class and class property names are in upper CamelCase (e.g. `AlyxPanel`, `obj.Token`)
* A variable name commonly used across files should have a consistent meaning, and variables which share the same meaning across files should have the same name (e.g. `validationLag` is used in both `hw.Window` and its subclass `hw.ptb.Window` to denote the amount of time between drawing an image and flipping it to the screen).
* When assigning a function's output(s), use the name(s) defined in that function's header (e.g. `[expRef, expDate, expSequence] = listExps(subjects)`).

See `/docs/maintainers/exampleDocumentationFunction.m` and `/docs/maintainers/ExampleDocumentationClass` for examples of a well-documented function and class that adhere to these style guidelines.

## Pull Request Review and Release Guidelines

Following the gitflow workflow, Rigbox and its main submodules (signals, alyx-matlab, and wheelAnalysis) each have two main branches: the 'dev' branch is where new features are deployed, and the 'master' branch contains the stable build that most users will work with. Below are procedural guidelines for the maintainers to follow when reviewing a pull request: (*Note: when reviewing a pull request into a submodule, the steps below should first be followed to merge the feature branch into the 'dev' branch of that submodule, then the submodule's 'dev' branch should be added and committed to a new Rigbox feature branch, and this feature branch should then be merged into Rigbox 'dev'.*)

1. Ensure any new file follows the above [style guidelines](#style-guidelines) and is accompanied by a test file that adequately covers all expected use cases. This test file should be placed in the appropriate repository's `tests` folder, and follow the naming convention of `<newFile>_test`. If the contributor is not adding a new file but instead changing/adding to an exisiting file that already has an accompanying test file, a test that accompanies the contributor's code should be added to the existing test file. See the [Rigbox/tests folder](https://github.com/cortex-lab/Rigbox/tree/dev/tests) for examples. 

	*Note: [MATLAB's Testing Frameworks documentation](https://uk.mathworks.com/help/matlab/matlab-unit-test-framework.html?s_tid=CRUX_lftnav) has examples for writing [script-based](https://uk.mathworks.com/help/matlab/matlab_prog/write-script-based-unit-tests.html), [function-based](https://uk.mathworks.com/help/matlab/matlab_prog/write-simple-test-case-with-functions.html), and [class-based](https://uk.mathworks.com/help/matlab/matlab_prog/write-simple-test-case-using-classes.html) unit tests.*

2. Ensure all existing tests for the entire repo pass. To do so, in MATLAB within the `Rigbox/tests` folder, run
 
	`[exitStatus, failures] = runall();`
	
	If `exitStatus` returns as 0, all tests passed. Note that the MATLAB environment (i.e. MATLAB version and dependent toolbox versions of the [toolboxes listed here](https://github.com/cortex-lab/Rigbox#requirements)) in which the project maintainers run these tests may differ from a user's MATLAB environment. Failures that are suspected to be due to a specific MATLAB environment (amongst those for which Rigbox maintains support) should be reported as issues. If possible, maintainers should compare tests results between the oldest and latest MATLAB environments that Rigbox supports.

3. Update the `README`, `CHANGELOG`, and configuration and tutorial scripts in the `docs` folder (and the `docs` folder for any submodules which may have been changed) as necessary with relevant details.

4. Merge a feature branch into 'dev' as follows: squash the feature branch down to the commmit where it branched off from 'dev', rebase the squashed branch onto 'dev', and then merge the rebased branch into 'dev' (See [here](https://blog.carbonfive.com/2017/08/28/always-squash-and-rebase-your-git-commits) for more info on why to adopt the "squash, rebase, merge" workflow). 

5. Merge 'dev' into 'master' and create a new Rigbox release as follows: when the 'dev' branch has accumulated sufficient changes for it to be considered a new major version, and the most recent commit on 'dev' has been deployed for at least a week, a new release of Rigbox should first be created on github from the 'master' branch, via the link [here](https://github.com/cortex-lab/Rigbox/releases/new). Thereafter, 'dev' should be merged into 'master'. In this way, the latest release of Rigbox is the old, stable 'master' branch, and the latest commits on the 'master' branch are the ones that will be included in the following release.