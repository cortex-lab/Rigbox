% This guide covers the basics of running experiments via the MC GUI. 
%
% In order to start an experiment, you must first run `srv.expServer` on
% the SC. `srv.expServer` initializes the rig hardware and creates a window
% on the SC screen(s) on which visual stimuli are presented. 
%
% After launching `srv.expServer`, the `mc` command should be run on the
% MC. This launches a GUI in which you will select an experiment subject,
% task (which we refer to as an “expdef”, which is short for “experiment
% definition”), and rig (i.e. the SC on which you just launched
% `srv.expServer`) on which to run an experiment. These can all be selected
% via the appropriate dropdowns in the top left of the MC GUI. For
% launching a test experiment, select the `test` subject, and one of the
% expdefs in `/signals/docs/examples/expdefs/`. Additionally, if you have
% set up a remote Alyx database, you can log into Alyx in the top
% right-hand corner of the MC GUI. 
%
% Expdef parameters and rig options can be edited directly in the MC GUI
% before starting the experiment. Changes can be made to expdef parameters
% by editing their fields directly in the MC GUI. To set rig specific 
% options, press the `Options` push-button. To start the experiment, press
% the `Start` push-button. After starting the experiment, the MC GUI should
% switch from the `New` tab to the `Current` tab. In the `Current` tab,
% live updates of all currently running experiments will be shown.
% Additionally, if you’ve created an ExpPanel for the running expdef,
% you can view real-time psychometric performance plots for this expdef.
% For more information on creating an ExpPanel, see `using_ExpPanel`.
%
% @todo add pictures
