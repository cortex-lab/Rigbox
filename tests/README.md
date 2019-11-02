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
checkCoverage('fun_package', fileparts(which('fun.run')))

```

## Contents:

- `fixtures/` - All custom fixtures and functions for shadowing core ones during tests.
- `optimizations/` - Performance tests on various functions before and after changes.  These are
 more for historical record and do not need to be run routinely.
- `cortexlab/` - The location of tests for functions found in the ../cortexlab folder
