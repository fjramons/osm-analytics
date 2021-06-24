:: Cleans the output of all Jupyter Notebooks in the current folder, to normalize them before committing to Git
jupyter nbconvert --clear-output *.ipynb */*.ipynb
