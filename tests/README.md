## Tests:
This 'tests' folder contains all performance and unit tests for Rigbox.  Similar folders are
 found in the alyx-matlab and signals submodules.  The simplest way to test everything is to
  call the function `runall`.  This will run all the Rigbox and submodule tests and output the
   result.  For quickly checking code coverage, use the funciton `checkCoverage`.
   
   A continuous integration service routinely runs all these tests on MATLAB 2018b.  Code
    coverage is calculated excluding anything found in the docs and tests folders. 
    
### Examples
```matlab
% Run all tests and throw error on fail:
[failed, failures] = runall(ignoreTagged);
assert(~failed, 'The following tests failed:\n%s', strjoin({failures.Name}, '\n'))

% Check the coverage of a particular test:
checkCoverage('cellflat') % Folder can be inferred 

% Check coverage of a package test:
checkCoverage('fun_package', '+fun')
```

### Creating new tests
Tests may be added and modified as necessary.  Tests may be either scripts, functions or subclasses of `matlab.unittest.TestCase` or `matlab.perftest.TestCase`.  When using any current or new fixtures (e.g. loading test data, calling `dat.paths`), use the class form and apply the fixtures folder as a PathsFixture.
For setting up a folder structure for code that saves/loads data via `dat.paths`, apply the ReposFixture.  Before calling `dat.paths` or any fixture function that shadows a Rigbox or builtin function, call `setTestFlag(true)` in the setup.  This supresses any warnings and errors designed to ensure users don't accidently call the wrong function outside of a test.
Additional test mock functions may be found in `fixtures\util`.  For mocking a rig hardware file, sublass `matlab.mock.TestCase` and then call `mockRig` with an instance of your test class.  Many of the fixture functions are stateful, containing persistant variables for recording call history or for injecting output behaviours.  Clear these are the end of your test by applying the `ClearTestCache` fixture.

A typical setup method may look like this:

```
function setup(testCase)
  % Set test flag to true while in test
  oldTF = setTestFlag(true);
  testCase.addTeardown(@setTestFlag(oldTF)) % Reset on teardown
  % Create a set of folders for various repository paths
  testCase.applyFixture(ReposFixture)
  % Clear all persistant variables and cache on teardown
  testCase.applyFixture(ClearTestCache)
  % Generate a set of mock rig objects and behaviours
  [rig, behaviour] = testCase.mockRig;
end
```

## Contents:

For a full list of test functions see `Contents.m`.

- `fixtures/` - All custom fixtures and functions for shadowing core ones during tests.
- `optimizations/` - Performance tests on various functions before and after changes.  These are
 more for historical record and do not need to be run routinely.
- `cortexlab/` - The location of tests for functions found in the ../cortexlab folder
