%% Script for running all Rigbox tests
% To be called for code checks and the like
% TODO May become a function
% TODO May add flags for levels of testing
% TODO Method setup in dat_test may become global fixture
% TODO Deal with directory changes
main_tests = testsuite;

%% Gather signals tests
root = getOr(dat.paths,'rigbox');
signals_tests = testsuite(fullfile(root, 'signals', 'tests'));

%% Gather alyx-matlab tests
alyx_tests = testsuite(fullfile(root, 'alyx-matlab', 'tests'));

%% Filter & run
% the suite is automatically sorted based on shared fixtures. However, if
% you add, remove, or reorder elements after initial suite creation, call
% the sortByFixtures method to sort the suite.
all_tests = [main_tests signals_tests alyx_tests];
results = run(all_tests);

%% Diagnostics
failed = {all_tests([results.Failed]).Name}';
% Load benchmarks and compare for performance tests?