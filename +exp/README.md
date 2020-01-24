## +Exp:
The +exp package contains classes and functions for the Rigbox Experiment framework.
The Experiment framework is for setting up and running stimulus-delivering experiments.  The framework allows parameterizing individual experiments at a single-trial level. Visual and auditory stimuli can be controlled by experiment phases or by the Signals framework.  Phases changes are managed by an event-handling system.

## Contents:

Below is a summery of files contained:

### Experiment Classes
- `Experiment.m`                 - Base class for stimuli-delivering experiments
- `LIARExperiment.m`             - Linear Input and Reward experiment
- `SignalsExp.m`                 - Trial-based Signals Experiments

### Event Handlers
- `EventHandler.m`               - Performs actions following an event
- `EventInfo.m`                  - Experimental event info base class
- `TrialEventInfo.m`             - Provides information about a trial event
- `ThresholdEventInfo.m`         - Provides information about a threshold reached
- `ResponseEventInfo.m`          - Provides information about a subject's response

### Event Actions
- `Action.m`                     - Base-class for actions used with an EventHandler
- `StartPhase.m`                 - Instruction to start a particular experiment phase
- `EndPhase.m`                   - Instruction to end a particular experiment phase
- `StartTrial.m`                 - Instruction to start a new trial in an experiment
- `EndTrial.m`                   - Instruction to end a new trial in an experiment
- `DeliverReward.m`              - Delivers reward in an experiment
- `LoadSound.m`                  - Loads specified samples ready for playing
- `PlaySound.m`                  - Plays the currently loaded sound
- `StartServices.m`              - Starts experiment services
- `StopServices.m`               - Stops experiment services
- `TriggerLaser.m`               - Triggers laser pulse in an experiment
- `RegisterNoGoResponse.m`       - Register time threshold response
- `RegisterThresholdResponse.m`  - Register the appropriate response
- `StartResponseFeedback.m`      - Start appropriate feedback phase for response

### Parameters
- `Parameters.m`                 - A store & methods for managing experiment parameters
- `ConditionServer.m`            - Interface for provision of trial parameters
- `PresetConditionServer.m`      - Provides preset trials from an array
- `inferParameters.m`            - Infers the parameters required for Signals experiments
- `promptForParams.m`            - 
- `trialConditions.m`            - Returns trial parameter Signals

### Time-Samplers
- `TimeSampler.m`                - Interface for generating times from some distribution
- `FixedTime.m`                  - Always generates a fixed time
- `UniformInterval.m`            - A time sampled uniformly from an interval
- `ExponentialInterval.m`        - A time sampled with a flat hazard function
- `configureSignalsExperiment.m` - 

### Subpackages
- `+test/`    - Functions for testing and plotting Signals via the Command.
