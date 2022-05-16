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

## Installation

Easiest way to start use dbt-greenplum is to install it using pip
`pip install dbt-greenplum==<version>`

Where `<version>` is same as your dbt version

Available versions:
 - 0.19.2 for dbt version 0.19.*
 - 1.0.4 for dbt version 1.0.4

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
 - partitions (see "partition" chapter below)

### Example

Such model definition

```buildoutcfg
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

```buildoutcfg
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

### Partitions

Greenplum does not support partitions with `create table as` [construction](https://gpdb.docs.pivotal.io/6-9/ref_guide/sql_commands/CREATE_TABLE_AS.html), so you need to build model in two steps
 - create table schema
 - insert data

To implement partitions into you dbt-model you need to specify on of the following config parameters:
 - `fields_string` - definition of columns name, type and constraints
 - one of following way to configure partitions
   - `raw_partition` by default
   - `partition_type`, `partition_column`, `partition_spec`
   - `partition_type`, `partition_column`, `partition_start`, `partition_end`, `partition_every`
   - `partition_type`, `partition_column`, `partition_values`
 - `default_partition_name` - name of default partition 'other' by default

Let consider examples of definition model with partitions

 - using `raw_partition` parameter
   ```buildoutcfg
   {% set fields_string %}
        id int4 null,
        incomingdate timestamp NULL
   {% endset %}


   {% set raw_partition %}
       PARTITION BY RANGE (incomingdate)
       (
           START ('2021-01-01'::timestamp) INCLUSIVE
           END ('2023-01-01'::timestamp) EXCLUSIVE
           EVERY (INTERVAL '1 day'),
           DEFAULT PARTITION extra
       );
   {% endset %}

   {{
       config(
           materialized='table',
           distributed_by='id',
           appendonly='true',
           orientation='column',
           compresstype='ZLIB',
           compresslevel=1,
           blocksize=32768,
           fields_string=fields_string,
           raw_partition=raw_partition,
           default_partition_name='other_data'
       )
   }}
   
   with source_data as (
   
       select
           1 as id,
           '2022-02-22'::timestamp as incomingdate
       union all
       select
           null as id,
           '2022-02-25'::timestamp as incomingdate
   )
   select *
   from source_data
   ```
   will produce following sql code
   ```buildoutcfg
   create table if not exists "database"."schema"."my_first_dbt_model__dbt_tmp" (
       id int4 null,
       incomingdate timestamp NULL
   )
   with (
       appendonly=true,
       blocksize=32768,
       orientation=column,
       compresstype=ZLIB,
       compresslevel=1
   )
   DISTRIBUTED BY (id)
   PARTITION BY RANGE (incomingdate)
   (
       START ('2021-01-01'::timestamp) INCLUSIVE
       END ('2023-01-01'::timestamp) EXCLUSIVE
       EVERY (INTERVAL '1 day'),
       DEFAULT PARTITION extra
   );
   
   insert into "database"."schema"."my_first_dbt_model__dbt_tmp" (
       with source_data as (
   
           select
               1 as id,
               '2022-02-22'::timestamp as incomingdate
           union all
           select
               null as id,
               '2022-02-25'::timestamp as incomingdate
       )
       select *
       from source_data
   );
   alter table "dvault"."dv"."my_first_dbt_model" rename to "my_first_dbt_model__dbt_backup";
   drop table if exists "dvault"."dv"."my_first_dbt_model__dbt_backup" cascade;
   alter table "database"."schema"."my_first_dbt_model__dbt_tmp" rename to "my_first_dbt_model";
   ```
 - Same result you can get using `partition_type`, `partition_column`, `partition_spec` parameters
   ```buildoutcfg
   {% set fields_string %}
       id int4 null,
       incomingdate timestamp NULL
   {% endset %}

   {%- set partition_type = 'RANGE' -%}
   {%- set partition_column = 'incomingdate' -%}
   {% set partition_spec %}
       START ('2021-01-01'::timestamp) INCLUSIVE
       END ('2023-01-01'::timestamp) EXCLUSIVE
       EVERY (INTERVAL '1 day'),
       DEFAULT PARTITION extra
   {% endset %}
   
   {{
       config(
           materialized='table',
           distributed_by='id',
           appendonly='true',
           orientation='column',
           compresstype='ZLIB',
           compresslevel=1,
           blocksize=32768,
           fields_string=fields_string,
           partition_type=partition_type,
           partition_column=partition_column,
           partition_spec=partition_spec,
           default_partition_name='other_data'
       )
   }}
   
   with source_data as (
   
       select
           1 as id,
           '2022-02-22'::timestamp as incomingdate
       union all
       select
           null as id,
           '2022-02-25'::timestamp as incomingdate
   )
   select *
   from source_data
   ```
 - also, you can use third way
   ```buildoutcfg
   {% set fields_string %}
       id int4 null,
       incomingdate timestamp NULL
   {% endset %}
   
   
   {%- set partition_type = 'RANGE' -%}
   {%- set partition_column = 'incomingdate' -%}
   {%- set partition_start = "'2021-01-01'::timestamp" -%}
   {%- set partition_end = "'2022-01-01'::timestamp" -%}
   {%- set partition_every = '1 day' -%}
   
   
   {{
       config(
           materialized='table',
           distributed_by='id',
           appendonly='true',
           orientation='column',
           compresstype='ZLIB',
           compresslevel=1,
           blocksize=32768,
           fields_string=fields_string,
           partition_type=partition_type,
           partition_column=partition_column,
           partition_start=partition_start,
           partition_end=partition_end,
           partition_every=partition_every,
           default_partition_name='other_data'
       )
   }}
   
   with source_data as (
   
       select
           1 as id,
           '2022-02-22'::timestamp as incomingdate
       union all
       select
           null as id,
           '2022-02-25'::timestamp as incomingdate
   )
   select *
   from source_data
   ```
 - example of partition_type `LIST` is coming soon

#### Table partition hints

Too check generate sql script use `-d` option:
`dbt -d run <...> -m <models>`

If you want implement complex partition logic with subpartition or something else use `raw_partition` parameter

## Getting started

- [Install dbt](https://docs.getdbt.com/docs/installation)
- Read the [introduction](https://docs.getdbt.com/docs/introduction/) and [viewpoint](https://docs.getdbt.com/docs/about/viewpoint/)

## Join the dbt Community

- Be part of the conversation in the [dbt Community Slack](http://community.getdbt.com/)
- Read more on the [dbt Community Discourse](https://discourse.getdbt.com)

## Reporting bugs and contributing code

- Want to report a bug or request a feature? Let us know on [Slack](http://community.getdbt.com/), or open [an issue](https://github.com/markporoshin/dbt-greenplum/issues/new)
- Want to help us build dbt? Check out the [Contributing Guide](https://github.com/dbt-labs/dbt/blob/HEAD/CONTRIBUTING.md)

## Code of Conduct

Everyone interacting in the dbt project's codebases, issue trackers, chat rooms, and mailing lists is expected to follow the [dbt Code of Conduct](https://community.getdbt.com/code-of-conduct).