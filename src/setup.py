#!/usr/bin/env python

import os
from setuptools import setup
import pyabf

# load the descripntion
PATH_HERE = os.path.abspath(os.path.dirname(__file__))
with open(os.path.abspath(PATH_HERE+"/README.md")) as f:
    long_description = f.read()
    print("loaded description: (%s lines)"%(long_description.count("\n")))

setup(
    name='pyibt',
    version='0.0.2',
    author='Perry Sprat',
    author_email='perrywespratt@gmail.com',
    url='https://github.com/pspratt/pyibt',
    packages=['pyibt'],
    license='MIT License',
    platforms='any',
    description='Python module for analyzing electrophysiological data',
    long_description=long_description,
    long_description_content_type="text/markdown",
    install_requires=[
        'matplotlib>=2.1.0',
        'numpy>=1.13.3',
    ],
    )
