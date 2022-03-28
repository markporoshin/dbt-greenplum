<p align="center">
  <img src="https://raw.githubusercontent.com/dbt-labs/dbt/ec7dee39f793aa4f7dd3dae37282cc87664813e4/etc/dbt-logo-full.svg" alt="dbt logo" width="500"/>
</p>
<p align="center">
  <a href="https://github.com/dbt-labs/dbt-redshift/actions/workflows/main.yml">
    <img src="https://github.com/dbt-labs/dbt-redshift/actions/workflows/main.yml/badge.svg?event=push" alt="Unit Tests Badge"/>
  </a>
  <a href="https://github.com/dbt-labs/dbt-redshift/actions/workflows/integration.yml">
    <img src="https://github.com/dbt-labs/dbt-redshift/actions/workflows/integration.yml/badge.svg?event=push" alt="Integration Tests Badge"/>
  </a>
</p>

**[dbt](https://www.getdbt.com/)** enables data analysts and engineers to transform their data using the same practices that software engineers use to build applications.

dbt is the T in ELT. Organize, cleanse, denormalize, filter, rename, and pre-aggregate the raw data in your warehouse so that it's ready for analysis.

## dbt-greenplum

The `dbt-greenplum` package contains the code enabling dbt to work with Greenplum. This adapter based on [postgres-adapter](https://github.com/dbt-labs/dbt-core/blob/main/plugins/postgres/dbt/include/postgres/profile_template.yml) with a bit difference for a greenplum specific features

## Supported Features

You can specify following preference 
 - distribution
   - `distributed randomly` by defaut
   - `distributed by (column, [ ... ] )` by setting up `distributed_by` parameter in the model config
 - table orientation
   - `orientation=colum` by default
   - `orientation=row` by setting up `orientation` parameter in `row` in the model config
 - compress type, level and blocksize with default values
   ```bash
    blocksize=32768,
    compresstype=ZLIB,
    compresslevel=1
   ``` 
    You can also specify `blocksize`, `compresstype`, `compresslevel` in the model config
 - appendonly preference by default is `true`, also you can override it by setting up `appendonly` field in the model config

### Example

Such model definition

```
{{
    config(
        materialized='table',
        distributed_by='id',
        appendonly='true',
        orientation='column',
        compresstype='ZLIB',
        compresslevel=1,
        blocksize=32768
    )
}}

with source_data as (

    select 1 as id
    union all
    select null as id

)

select *
from source_data
```

will produce following sql code

```
create  table "dvault"."dv"."my_first_dbt_model__dbt_tmp"
with (
    appendonly=true,
    blocksize=32768,
    orientation=column,
    compresstype=ZLIB,
    compresslevel=1
)
as (
  with source_data as (
      select 1 as id
      union all
      select null as id
    )
  select *
  from source_data
)  
distributed by (id);

  
alter table "dvault"."dv"."my_first_dbt_model__dbt_tmp" rename to "my_first_dbt_model";
```

## Getting started

- [Install dbt](https://docs.getdbt.com/docs/installation)
- Read the [introduction](https://docs.getdbt.com/docs/introduction/) and [viewpoint](https://docs.getdbt.com/docs/about/viewpoint/)

## Join the dbt Community

- Be part of the conversation in the [dbt Community Slack](http://community.getdbt.com/)
- Read more on the [dbt Community Discourse](https://discourse.getdbt.com)

## Reporting bugs and contributing code

- Want to report a bug or request a feature? Let us know on [Slack](http://community.getdbt.com/), or open [an issue](https://github.com/dbt-labs/dbt-redshift/issues/new)
- Want to help us build dbt? Check out the [Contributing Guide](https://github.com/dbt-labs/dbt/blob/HEAD/CONTRIBUTING.md)

## Code of Conduct

Everyone interacting in the dbt project's codebases, issue trackers, chat rooms, and mailing lists is expected to follow the [dbt Code of Conduct](https://community.getdbt.com/code-of-conduct).