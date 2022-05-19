#!/usr/bin/env python
from setuptools import find_namespace_packages, setup

package_name = "dbt-greenplum"
package_version = "1.0.4.1"
description = """The greenplum adapter plugin for dbt"""

setup(
    name=package_name,
    version=package_version,
    description=description,
    long_description=description,
    author='Mark Poroshin',
    author_email='mark.poroshin@yandex.ru',
    packages=find_namespace_packages(include=['dbt', 'dbt.*']),
    url="https://github.com/markporoshin/dbt-greenplum",
    include_package_data=True,
    install_requires=[
        "dbt-core>=1.0.4"
    ],
    classifiers=[
        'Development Status :: 4 - Beta',      # Chose either "3 - Alpha", "4 - Beta" or "5 - Production/Stable" as the current state of your package
        'Intended Audience :: Developers',      # Define that your audience are developers
        'Topic :: Software Development :: Build Tools',
        'License :: OSI Approved :: MIT License',   # Again, pick a license
        'Programming Language :: Python :: 3',      #Specify which pyhton versions that you want to support
        'Programming Language :: Python :: 3.4',
        'Programming Language :: Python :: 3.5',
        'Programming Language :: Python :: 3.6',
      ],
)
