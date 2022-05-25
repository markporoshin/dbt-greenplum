from typing import Optional, Set, List, Any
from dbt.adapters.base.meta import available
from dbt.adapters.greenplum import GreenplumConnectionManager
from dbt.adapters.greenplum.relation import GreenplumColumn
from dbt.adapters.greenplum.relation import GreenplumRelation
from dbt.adapters.postgres.impl import PostgresIndexConfig, PostgresConfig, PostgresAdapter
from dbt.adapters.postgres import impl

# note that this isn't an adapter macro, so just a single underscore
impl.GET_RELATIONS_MACRO_NAME = "greenplum_get_relations"


class GreenplumIndexConfig(PostgresIndexConfig):
    pass


class GreenplumConfig(PostgresConfig):
    pass


class GreenplumAdapter(PostgresAdapter):
    Relation = GreenplumRelation
    ConnectionManager = GreenplumConnectionManager
    Column = GreenplumColumn

    AdapterSpecificConfigs = GreenplumConfig

    @available
    def parse_index(self, raw_index: Any) -> Optional[GreenplumIndexConfig]:
        return GreenplumIndexConfig.parse(raw_index)