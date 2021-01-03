# Documentation:
This 'docs' folder contains files that are useful for learning how to use and set up Rigbox. To view the docs in HTML open `docs/html/index.html` in the MATLAB browser or visit [cortex-lab.github.io/Rigbox](https://cortex-lab.github.io/Rigbox/):
```matlab
root = fileparts(which('addRigboxPaths'));
url = ['file:///', fullfile(root, 'docs', 'html', 'index.html')];
web(url)
```

## Contents:
The docs directory contains three things:

- `scripts/` - The scripts used to generate the html files.  These are useful if you wish to run some of the code in the docs, particularly `hardware_config.m`.
- `html/` - The html docs and source images.
- 'maintainers/' - Guidelines for code maintainers.
- `Rigbox UML.pdf` - A UML diagram of the Rigbox class structure.
 

## Contributing
If you wish to make changes to the documentation, please follow the below steps:
1. Make your changes to the documentation scripts on the `documentation` branch.  
2. Export your changed files by running the `fixFiles` function.
3. Once committed to the `documentation` branch, merge this branch onto the `gh-pages` branch and copy the files from `docs/scripts/html` to the repository's root directory.  Commit these changes to the `gh-pages` branch.  They will now show up on the documentation Website.
