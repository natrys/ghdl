#!/bin/sh

clean() {
  git clean -f -d -x -e 'setup.py.base'
}

setup() {
  sed -i -E "/^version = /s/\".*\"/$(grep -o -P '__version__ \K.*\"' ghdl/__init__.hy)/" pyproject.toml
  # Since poetry doesn't support non-python scripts
  # https://github.com/python-poetry/poetry/pull/1504
  poetry build
  tar xvf dist/ghdl-*.tar.gz
  git merge-file --union --theirs -p -- setup.py setup.py.base ghdl-*/setup.py | sponge setup.py
  clean
}

release() {
  python setup.py sdist bdist_wheel
  twine upload --repository-url https://test.pypi.org/legacy/ dist/*
}

"$@"
