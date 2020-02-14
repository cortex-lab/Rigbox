% TESTS Unit and integration tests for Rigbox.
% Version xxx 02-Oct-2019
%  The tests folder contains all tests and fixtures for testing core Rigbox
%  functions and classes.  To run all tests, use `runall`.  This will
%  additionally run tests on alyx-matlab and signals.  To quickly check the
%  coverage of a given test, use `checkCoverage`.
% 
% Files:
%   runall               - Gathers and runs all tests in Rigbox
%   checkCoverage        - Check the coverage of a given test
%
%   AlyxPanel_test       - Tests for eui.AlyxPanel
%   ExpPanel_test        - Tests for eui.ExpPanel
%   ParamEditor_test     - Tests for eui.ParamEditor
%   Parameters_test      - Tests for exp.Parameters
%   calibrate_test       - Tests for hw.calibrate
%   catStructs_test      - Tests for catStructs
%   cellflat_test        - Tests for cellflat
%   cellsprintf_test     - Tests for cellsprintf
%   dat_test             - Tests for the +dat package
%   emptyElems_test      - Tests for emptyElems
%   ensureCell_test      - Tests for ensureCell
%   expServer_test       - Tests for srv.expServer
%   fileFunction_test    - Tests for fileFunction
%   file_test            - Tests for the +file package
%   fun_test             - Tests for the +fun package
%   iff_test             - Tests for iff
%   inferParams_test     - inferParams test
%   loadVar_test         - loadVar test
%   mapToCell_test       - Tests for mapToCell function
%   mergeStructs_test    - mergeStructs test
%   namedArg_test        - namedArg test
%   nop_test             - Tests for nop
%   num2cellstr_test     - Tests for num2cellstr
%   obj2json_test        - Tests for obj2struct
%   pick_test            - pick test
%   repelems_test        - repelems test
%   StimulusControl_test - Tests for srv.StimulusControl and
%                          srv.stimulusControllers
%   structAssign_test    - structAssign test
%   superSave_test       - superSave test
%   tabulateArgs_test    - Tests for tabulateArgs
%   varName_test         - varName test
