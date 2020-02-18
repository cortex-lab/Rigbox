## Documentation:
This 'docs' folder contains files that are useful for learning how to use and set up Rigbox. To view the docs in HTML open `docs/html/index.html` in the MATLAB browser or visit [cortex-lab.github.io/Rigbox](https://cortex-lab.github.io/Rigbox/):
```matlab
root = fileparts(which('addRigboxPaths'));
url = ['file:///', fullfile(root, 'docs', 'html', 'index.html')];
web(url)
```

### Contents:
The docs directory contains three things:

- `scripts/` - The scripts used to generate the html files.  These are useful if you wish to run some of the code in the docs, particularly `hardware_config.m`.
- `html/` - The html docs and source images.
- `Rigbox UML.pdf` - A UML diagram of the Rigbox class structure.