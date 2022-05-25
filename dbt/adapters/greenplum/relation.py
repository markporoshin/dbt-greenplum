from dataclasses import dataclass
from dbt.adapters.postgres import PostgresRelation, PostgresColumn


@dataclass(frozen=True, eq=False, repr=False)
class GreenplumRelation(PostgresRelation):
    pass


class GreenplumColumn(PostgresColumn):
    pass
