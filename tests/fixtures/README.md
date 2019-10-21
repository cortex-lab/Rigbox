## Test Fixtures:
This 'fixtures' folder contains all fixtures for the Rigbox unit tests.  A similar folder is
 found in the alyx-matlab and signals subfolders. 
   
Most of the folders here contain functions for shadowing core functions during testing.  Such
 functions allow us to spy on behaviour or inject dependencies.  Therefore this folder should
  never be added to the paths directly, but instead applied as a path fixture dynamically.  
    

## Contents:

- `+dat/` - Contains the `dat.paths` function for use during tests.  Tests of any function that
 calls `dat.paths` should apply this folder to their fixtures.
- `+hw/` - Contains the `hw.devices` function for injecting mock rig objects into functions
 under test.  Should be used by any test that normally calls this function.
- `+exp/` - Contains an old dummy experiment class and a configuration function for injecting a
 mock experiment object into functions under test.
- `data/` - Contains validation data for the subject history plots in `AlyxPanel_test`.  In
 general saving validation data for tests is to be avoided.
- `expDefinitions/` - Some experiment definition functions for testing signals related functions
 and classes, such as `exp.inferParameters` and `SignalsExp_test`.
- `util/` - Further functions for shadowing core functions in order.  These are only required
 during some tests and are therefore not applied as a path fixture.

The following temporary folders are created during tests and should not be modified:

- `Subjects/` - The location of the main repository path during tests.  This is where test
 subject data are saved and loaded.
- `Subjects2/` - The location of an alternate repository path during tests.
- `config/` - The location of the global config repository during tests.  This is where custom
  paths and test hardware files are saved and loaded.
- `alyxQ/` - The location of the local Alyx queue directory during tests.  Alyx posts are saved to
 and loaded from here during testing.