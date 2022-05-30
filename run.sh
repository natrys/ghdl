#!/bin/sh

setup() {
  sed -i -E "/^version = /s/\".*\"/$(grep -o -P '__version__ \K.*\"' ghdl/__init__.hy)/" pyproject.toml
  poetry build
}

release() {
  #python setup.py sdist bdist_wheel
  #twine upload --repository-url https://test.pypi.org/legacy/ dist/*
  twine upload dist/*
}

update() {
  bin/ghdl -f $(grep -Po 'repo \"\K[^"]*' ~/.config/ghdl/config | fzf)
}

"$@"
