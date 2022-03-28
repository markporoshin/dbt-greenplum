#!/usr/bin/env python
from setuptools import find_namespace_packages, setup

package_name = "dbt-greenplum"
package_version = "0.0.1"
description = """The greenplum adapter plugin for dbt"""

setup(
    name=package_name,
    version=package_version,
    description=description,
    long_description=description,
    author='Mark Poroshin',
    author_email='mark.poroshin@yandex.ru',
    packages=find_namespace_packages(include=['dbt', 'dbt.*']),
    include_package_data=True,
    install_requires=[
        "dbt-core==1.0.4"
    ]
)
