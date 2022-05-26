from dbt.adapters.greenplum import GreenplumConnectionManager
from dbt.adapters.postgres.impl import PostgresAdapter
from dbt.adapters.postgres import impl

# note that this isn't an adapter macro, so just a single underscore

impl.GET_RELATIONS_MACRO_NAME = "greenplum_get_relations"


class GreenplumAdapter(PostgresAdapter):
    ConnectionManager = GreenplumConnectionManager
