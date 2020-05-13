setup() {
  sed -E "/^version = /s/\".*\"/$(grep -o -P '__version__ \K.*\"' ghdl/__init__.hy)/" pyproject.toml
  poetry build
  tar xvf dist/ghdl-*.tar.gz
  git merge-file --union --theirs -p -- setup.py setup.py.base ghdl-*/setup.py | sponge setup.py
  git clean -f -d -x -e 'setup.py.base'
}

"$@"
