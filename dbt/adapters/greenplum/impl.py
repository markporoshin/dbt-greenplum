from dbt.adapters.greenplum import GreenplumConnectionManager
from dbt.adapters.postgres.impl import PostgresAdapter


class GreenplumAdapter(PostgresAdapter):
    ConnectionManager = GreenplumConnectionManager

    def valid_incremental_strategies(self):
        return ["append", "delete+insert", "truncate+insert"]
