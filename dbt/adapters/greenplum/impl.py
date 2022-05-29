from dbt.adapters.greenplum import GreenplumConnectionManager
from dbt.adapters.postgres.impl import PostgresAdapter


class GreenplumAdapter(PostgresAdapter):
    ConnectionManager = GreenplumConnectionManager
