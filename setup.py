# -*- coding: utf-8 -*-
from setuptools import setup

packages = \
['ghdl']

package_data = \
{'': ['*']}

install_requires = \
['docopt>=0.6.2,<0.7.0',
 'filetype>=1.0.7,<2.0.0',
 'hy>=0.18.0,<0.19.0',
 'python-dateutil>=2.8.1,<3.0.0',
 'xdg>=4.0.1,<5.0.0',
 'xtract>=0.1a3,<0.2']

setup_kwargs = {
    'name': 'ghdl',
    'version': '0.2.1',
    'description': 'Download and keep binaries from Github releases updated',
    'long_description': None,
    'author': 'Imran Khan',
    'author_email': 'imrankhan@teknik.io',
    'maintainer': None,
    'maintainer_email': None,
    'url': None,
    'packages': packages,
    'package_data': package_data,
    'install_requires': install_requires,
    'scripts': ['bin/ghdl', 'bin/ghdl-delete-repo'],
    'python_requires': '>=3.8,<4.0',
}


setup(**setup_kwargs)
