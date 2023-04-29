#!/usr/bin/env python
#!/usr/bin/env python
import os
import re
import sys

if sys.version_info < (3, 7):
    print("Error: dbt does not support this version of Python.")
    print("Please upgrade to Python 3.7 or higher.")
    sys.exit(1)


from setuptools import setup

try:
    from setuptools import find_namespace_packages
except ImportError:
    # the user has a downlevel version of setuptools.
    print("Error: dbt requires setuptools v40.1.0 or higher.")
    print('Please upgrade setuptools with "pip install --upgrade setuptools" ' "and try again")
    sys.exit(1)


PSYCOPG2_MESSAGE = """
No package name override was set.
Using 'psycopg2-binary' package to satisfy 'psycopg2'

If you experience segmentation faults, silent crashes, or installation errors,
consider retrying with the 'DBT_PSYCOPG2_NAME' environment variable set to
'psycopg2'. It may require a compiler toolchain and development libraries!
""".strip()

this_directory = os.path.abspath(os.path.dirname(__file__))
with open(os.path.join(this_directory, "README.md")) as f:
    long_description = f.read()


def _dbt_psycopg2_name():
    # if the user chose something, use that
    package_name = os.getenv("DBT_PSYCOPG2_NAME", "")
    if package_name:
        return package_name

    # default to psycopg2-binary for all OSes/versions
    print(PSYCOPG2_MESSAGE)
    return "psycopg2-binary"


def _get_plugin_version_dict():
    _version_path = os.path.join(this_directory, "dbt", "adapters", "greenplum", "__version__.py")
    _semver = r"""(?P<major>\d+)\.(?P<minor>\d+)\.(?P<patch>\d+)"""
    _pre = r"""((?P<prekind>a|b|rc)(?P<pre>\d+))?"""
    _version_pattern = fr"""version\s*=\s*["']{_semver}{_pre}["']"""
    with open(_version_path) as f:
        match = re.search(_version_pattern, f.read().strip())
        if match is None:
            raise ValueError(f"invalid version at {_version_path}")
        return match.groupdict()


def _get_package_version():
    parts = _get_plugin_version_dict()
    minor = "{major}.{minor}.0".format(**parts)
    pre = parts["prekind"] + "1" if parts["prekind"] else ""
    return f"{minor}{pre}"


def _get_dbt_core_version():
    parts = _get_plugin_version_dict()
    minor = "{major}.{minor}.0".format(**parts)
    pre = parts["prekind"] + "1" if parts["prekind"] else ""
    return f"{minor}{pre}"


package_name = "dbt-greenplum"
package_version = _get_package_version()
dbt_core_version = _get_dbt_core_version()
description = """The greenplum adapter plugin for dbt (data build tool)"""

DBT_PSYCOPG2_NAME = _dbt_psycopg2_name()

setup(
    name=package_name,
    version=package_version,
    description=description,
    long_description=long_description,
    long_description_content_type="text/markdown",
    author="Mark Poroshin",
    author_email="mark.poroshin@yandex.ru",
    url="https://github.com/markporoshin/dbt-greenplum",
    packages=find_namespace_packages(include=["dbt", "dbt.*"]),
    package_data={
        "dbt": [
            "include/greenplum/dbt_project.yml",
            "include/greenplum/sample_profiles.yml",
            "include/greenplum/macros/*.sql",
            "include/greenplum/macros/**/*.sql",
        ]
    },
    install_requires=[
        "dbt-core~={}".format(dbt_core_version),
        "dbt-postgres~={}".format(package_version),
        "{}~=2.8".format(DBT_PSYCOPG2_NAME),
    ],
    zip_safe=False,
    classifiers=[
        "Development Status :: 5 - Production/Stable",
        "License :: OSI Approved :: Apache Software License",
        "Operating System :: Microsoft :: Windows",
        "Operating System :: MacOS :: MacOS X",
        "Operating System :: POSIX :: Linux",
        "Programming Language :: Python :: 3.7",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
    ],
    python_requires=">=3.7",
)

