% +EXP Classes and functions for the Rigbox Experiment framework
%   The Experiment framework is for setting up and running
%   stimulus-delivering experiments.  The framework allows parameterizing
%   individual experiments at a single-trial level. Visual and auditory
%   stimuli can be controlled by experiment phases or by the Signals
%   framework.  Phases changes are managed by an event-handling system.
%
% Files
%   %%% Experiment Classes
%   Experiment                 - Base class for stimuli-delivering experiments
%   LIARExperiment             - Linear Input and Reward experiment
%   SignalsExp                 - Trial-based Signals Experiments
%
%   %%% Event Handlers
%   EventHandler               - Performs actions following an event
%   EventInfo                  - Experimental event info base class
%   TrialEventInfo             - Provides information about a trial event
%   ThresholdEventInfo         - Provides information about a threshold reached
%   ResponseEventInfo          - Provides information about a subject's response
%
%   %%% Event Actions
%   Action                     - Base-class for actions used with an EventHandler
%   StartPhase                 - Instruction to start a particular experiment phase
%   EndPhase                   - Instruction to end a particular experiment phase
%   StartTrial                 - Instruction to start a new trial in an experiment
%   EndTrial                   - Instruction to end a new trial in an experiment
%   DeliverReward              - Delivers reward in an experiment
%   LoadSound                  - Loads specified samples ready for playing
%   PlaySound                  - Plays the currently loaded sound
%   StartServices              - Starts experiment services
%   StopServices               - Stops experiment services
%   TriggerLaser               - Triggers laser pulse in an experiment
%   RegisterNoGoResponse       - Register time threshold response
%   RegisterThresholdResponse  - Register the appropriate response
%   StartResponseFeedback      - Start appropriate feedback phase for response
%
%   %%% Parameters
%   Parameters                 - A store & methods for managing experiment parameters
%   ConditionServer            - Interface for provision of trial parameters
%   PresetConditionServer      - Provides preset trials from an array
%   inferParameters            - Infers the parameters required for Signals experiments
%   promptForParams            - 
%   trialConditions            - Returns trial parameter Signals
%
%   %%% Time-Samplers
%   TimeSampler                - Interface for generating times from some distribution
%   FixedTime                  - Always generates a fixed time
%   UniformInterval            - A time sampled uniformly from an interval
%   ExponentialInterval        - A time sampled with a flat hazard function
%
%   %%% Other
%   configureSignalsExperiment - 
%   SignalsTest                - 
