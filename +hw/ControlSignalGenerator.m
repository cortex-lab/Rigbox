classdef ControlSignalGenerator < matlab.mixin.Heterogeneous & handle
  %HW.CONTROLSIGNALGENERATOR Generates a waveform from a command value
  %   This is an abstract class for generating a simple waveform (e.g.
  %   sinewave) based on a command value or values.  The principle method
  %   must return an array of samples that can be queued to an NI DAQ.
  %   This is a member of the SignalGenerators property of
  %   HW.DAQCONTROLLER.
  %
  %   Below is a list of some subclasses and their functions:
  %     HW.REWARDVALVECONTROL - Generates an array of voltage samples to
  %     open and close a valve in order to deliver a specified amount of
  %     water based on calibration data
  %     HW.SINEWAVEGENERATOR - Generates a sinewave
  %     HW.PULSESWITCHER - Generates a squarewave pulse train
  %     HW.DIGITALONOFF - Generates a simple TTL pulse
  %
  %   Example: Setting up laser shutter reward in a Signals behavour task
  %     %Load the romote rig's hardware.mat
  %       load('hardware.mat');
  %     %Add a new channel
  %       daqController.ChannelNames{end+1} = 'laserShutter';
  %     %Define the channel ID to output on
  %       daqController.DaqChannelIds{end+1} = 'ai1';
  %     %As it is an analogue output, set the AnalogueChannelsIdx to true
  %       daqController.AnalogueChannelIdx(end+1) = true;
  %     %Add a signal generator that will return the correct samples for a
  %     %specified train of pulses
  %       daqController.SignalGenerators(1) = hw.PulseSwitcher(duration,
  %       nPulses, freq);
  %     %Save your hardware file
  %       save('hardware.mat', 'daqController', '-append');
  %
  % See also HW.DAQCONTROLLER
  %
  % Part of Rigbox
  
  % 2013 CB created
  
  properties
    DefaultCommand %optional, for generating a default control waveform
    DefaultValue %default voltage value
  end
  
  methods (Abstract)
    samples = waveform(obj, command)
  end
  
end

