Setting up Rigbox
=================
Below is a walk-through for setting up your experiment rig after `installing <Installing.html>`_.

Configuring Paths
-------------------
The first thing to set up are the paths.  Rigbox uses the :mod:`+dat` package for determining where to things such as experiment data and configuration files are located.  The paths are set by :func:`+dat.paths()`.  A template of this file can be found in ``docs\setup\paths_template.m``.  Running :func:`addRigboxPaths` should automatically copy this template to the :mod:`+dat` folder, otherwise copy it manually.

.. autofunction:: +dat.paths()

For more information on using the :mod:`+dat` package, see :scpt:`using_dat_package` (found in ``docs``).

Configuring the hardware
--------------------
The next step is to create a hardware file, which contains all rig specific hardware settings (device IDs, PsychToolbox parameteres, etc.)  A step-by-step guide can be found in ``docs\setup\``:scpt:`hardware_config`