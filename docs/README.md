This `docs` folder contains information relevant to Rigbox's organization and useful for learning how to set up and use Rigbox. To view the docs in HTML, open `docs/html/index.html` in a web browser. E.g. to do so within MATLAB:
```matlab
root = fileparts(which('addRigboxPaths'));
url = ['file:///', fullfile(root, 'docs', 'html', 'index.html')];
web(url)
```

## Contents:

- `index.m` - information on the organization of the Rigbox repository. To view this information in HTML, open `docs/html/index.html` in a web browser. 
- `setup/` - information on how to set up and customize Rigbox on a new rig after installation.
- `html/` - .html files that correspond to files in `setup/`
- `Troubleshooting_and_FAQ.m` - information on troubleshooting errors which arise in Rigbox, and frequently asked questions.
- `maintainers/` - files for maintainers which specify how to standardize maintenance and development of Rigbox.
- `Rigbox UML.pdf` - a UML diagram of Rigbox.