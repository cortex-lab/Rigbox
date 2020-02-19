This `docs` folder contains information on setting up and using Rigbox, as well as information on the organization of the repository. After installation, we recommend viewing and following the instructions in the main index page for getting started with Rigbox. To view the main index page, open `docs/html/index.html` in a web browser. E.g. to do so within MATLAB, run:
```matlab
root = fileparts(which('addRigboxPaths'));
url = ['file:///', fullfile(root, 'docs', 'html', 'index.html')];
web(url)
```

## Contents:

- `setup/` - information on how to set up Rigbox on a new rig after installation.
- `usage/` - information on how to use certain Rigbox features after setup.
- `html/` - .html files that correspond to the .m files in `setup/` and `usage/`
- `maintainers/` - files for maintainers which specify design and style choices and how to standardize maintenance and development of Rigbox.
- `index.m` - Rigbox's documentation index page as a .m file. Corresponds to the `html/index.html` file.
- `Rigbox UML.pdf` - a UML diagram of Rigbox.
- `Troubleshooting_and_FAQ.m` - information on troubleshooting errors which arise in Rigbox, and frequently asked questions.