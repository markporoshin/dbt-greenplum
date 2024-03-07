from dbt.adapters.base import AdapterPlugin
from dbt.adapters.greenplum.connections import (GreenplumConnectionManager,
                                                GreenplumCredentials)
from dbt.adapters.greenplum.impl import GreenplumAdapter
from dbt.include import greenplum

Plugin = AdapterPlugin(
    adapter=GreenplumAdapter,  # Type: ignore
    credentials=GreenplumCredentials,
    include_path=greenplum.PACKAGE_PATH,
    dependencies=["postgres"],
)
