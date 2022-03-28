from dbt.adapters.greenplum.connections import GreenplumConnectionManager
from dbt.adapters.greenplum.connections import GreenplumCredentials
from dbt.adapters.greenplum.impl import GreenplumAdapter

from dbt.adapters.base import AdapterPlugin
from dbt.include import greenplum


Plugin = AdapterPlugin(
    adapter=GreenplumAdapter,
    credentials=GreenplumCredentials,
    include_path=greenplum.PACKAGE_PATH)
