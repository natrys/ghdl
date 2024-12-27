#!/bin/sh

build() {
  # sed -i -E "/^version = /s/\".*\"/$(grep -o -P '__version__ = \K.*\"' ghdl/__init__.py)/" pyproject.toml
  uv build
}

release() {
  # python setup.py sdist bdist_wheel
  # uv run twine upload --repository-url https://test.pypi.org/legacy/ dist/*
  # uv run twine upload dist/*
  uv publish
}

clean() {
  rm -rf dist/ ghdl.egg-info/
}

upgrade() {
  uv lock --upgrade
  uv sync
}

update() {
  bin/ghdl -f $(grep -Po 'repo \"\K[^"]*' ~/.config/ghdl/config | fzf)
}

"$@"
