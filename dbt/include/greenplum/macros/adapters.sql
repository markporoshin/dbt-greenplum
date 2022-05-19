{% macro greenplum__create_table_as(temporary, relation, sql) -%}
  {%- set unlogged = config.get('unlogged', default=false) -%}
  {%- set sql_header = config.get('sql_header', none) -%}
  {%- set distributed_replicated = config.get('distributed_replicated', default=false) -%}
  {%- set distributed_by = config.get('distributed_by', none) -%}
  {%- set appendonly = config.get('appendonly', default='true') -%}
  {%- set orientation = config.get('orientation', default='column') -%}
  {%- set compresstype = config.get('compresstype', default='ZSTD') -%}
  {%- set compresslevel = config.get('compresslevel', default=4) -%}
  {%- set blocksize = config.get('blocksize', default=32768) -%}

  {%- set raw_partition = config.get('raw_partition', none) -%}
  {%- set fields_string = config.get('fields_string', none) -%}

  {%- set default_partition_name = config.get('default_partition_name', default='other') -%}
  {%- set partition_type = config.get('partition_type', none) -%}
  {%- set partition_column = config.get('partition_column', none) -%}

  {% set partition_spec = config.get('partition_spec', none) %}

  {%- set partition_start = config.get('partition_start', none) -%}
  {%- set partition_end = config.get('partition_end', none) -%}
  {%- set partition_every = config.get('partition_every', none) -%}
  {%- set partition_values = config.get('partition_values', none) -%}

  {%- set is_partition = raw_partition is not none or partition_type is not none -%}

  {{ sql_header if sql_header is not none }}

  {% if is_partition and not temporary %}

    {# CREATING TABLE #}
    create table if not exists {{ relation }} (
        {{ fields_string }}
    )
    with (
        appendonly={{ appendonly }},
        blocksize={{ blocksize }},
        orientation={{ orientation }},
        compresstype={{ compresstype }},
        compresslevel={{ compresslevel }}
    )
    {% if distributed_by is not none %}
    DISTRIBUTED BY ({{ distributed_by }})
    {% elif distributed_replicated %}
    DISTRIBUTED REPLICATED
    {% else %}
    DISTRIBUTED RANDOMLY
    {% endif %}


    {% if is_partition %}
        {% if raw_partition is not none %}
            {{ raw_partition }}
        {% else %}
            PARTITION BY {{ partition_type }} ({{ partition_column }})
            (
                {% if partition_spec is not none %}
                    {{ partition_spec }}
                {% else %}
                    {% if partition_type == 'LIST' %}
                        {{ partition_values }},
                        DEFAULT PARTITION {{ default_partition_name }}
                    {% else %}
                        START ({{ partition_start }}) INCLUSIVE
                        END ({{ partition_end }}) EXCLUSIVE
                        EVERY (INTERVAL '{{ partition_every }}'),
                        DEFAULT PARTITION {{ default_partition_name }}
                    {% endif %}

                {% endif %}
            )
        {% endif %}
    {% endif %}
    ;

    {# INSERT DATA #}
    insert into {{ relation }} (
        {{ sql }}
    );

  {% else %}

      create {% if temporary -%}
        temporary
      {%- elif unlogged -%}
        unlogged
      {%- endif %} table {{ relation }}
      with (
            appendonly={{ appendonly }},
            blocksize={{ blocksize }},
            orientation={{ orientation }},
            compresstype={{ compresstype }},
            compresslevel={{ compresslevel }}
      )
      as (
        {{ sql }}
      )
      {% if distributed_by is not none %}
      DISTRIBUTED BY ({{ distributed_by }})
      {% elif distributed_replicated %}
      DISTRIBUTED REPLICATED
      {% else %}
      DISTRIBUTED RANDOMLY
      {% endif %}
      ;
  {% endif %}
{%- endmacro %}

{% macro greenplum__get_create_index_sql(relation, index_dict) -%}
  {%- set index_config = adapter.parse_index(index_dict) -%}
  {%- set comma_separated_columns = ", ".join(index_config.columns) -%}
  {%- set index_name = index_config.render(relation) -%}

  create {% if index_config.unique -%}
    unique
  {%- endif %} index if not exists
  "{{ index_name }}"
  on {{ relation }} {% if index_config.type -%}
    using {{ index_config.type }}
  {%- endif %}
  ({{ comma_separated_columns }});
{%- endmacro %}

{% macro greenplum__generate_schema_name(custom_schema_name, node) -%}

    {%- set default_schema = target.schema -%}
    {%- if custom_schema_name is none -%}

    {{ default_schema }}

    {%- else -%}

    {{ custom_schema_name | trim }}

    {%- endif -%}

{%- endmacro %}

{% macro greenplum__create_schema(relation) -%}
  {% if relation.database -%}
    {{ adapter.verify_database(relation.database) }}
  {%- endif -%}
  {%- call statement('create_schema') -%}
    create schema if not exists {{ relation.without_identifier().include(database=False) }}
  {%- endcall -%}
{% endmacro %}

{% macro greenplum__drop_schema(relation) -%}
  {% if relation.database -%}
    {{ adapter.verify_database(relation.database) }}
  {%- endif -%}
  {%- call statement('drop_schema') -%}
    drop schema if exists {{ relation.without_identifier().include(database=False) }} cascade
  {%- endcall -%}
{% endmacro %}

{% macro greenplum__get_columns_in_relation(relation) -%}
  {% call statement('get_columns_in_relation', fetch_result=True) %}
      select
          column_name,
          data_type,
          character_maximum_length,
          numeric_precision,
          numeric_scale

      from {{ relation.information_schema('columns') }}
      where table_name = '{{ relation.identifier }}'
        {% if relation.schema %}
        and table_schema = '{{ relation.schema }}'
        {% endif %}
      order by ordinal_position

  {% endcall %}
  {% set table = load_result('get_columns_in_relation').table %}
  {{ return(sql_convert_columns_in_relation(table)) }}
{% endmacro %}


{% macro greenplum__list_relations_without_caching(schema_relation) %}
  {% call statement('list_relations_without_caching', fetch_result=True) -%}
    select
      '{{ schema_relation.database }}' as database,
      tablename as name,
      schemaname as schema,
      'table' as type
    from pg_tables
    where schemaname ilike '{{ schema_relation.schema }}'
    union all
    select
      '{{ schema_relation.database }}' as database,
      viewname as name,
      schemaname as schema,
      'view' as type
    from pg_views
    where schemaname ilike '{{ schema_relation.schema }}'
  {% endcall %}
  {{ return(load_result('list_relations_without_caching').table) }}
{% endmacro %}

{% macro greenplum__information_schema_name(database) -%}
  {% if database_name -%}
    {{ adapter.verify_database(database_name) }}
  {%- endif -%}
  information_schema
{%- endmacro %}

{% macro greenplum__list_schemas(database) %}
  {% if database -%}
    {{ adapter.verify_database(database) }}
  {%- endif -%}
  {% call statement('list_schemas', fetch_result=True, auto_begin=False) %}
    select distinct nspname from pg_namespace
  {% endcall %}
  {{ return(load_result('list_schemas').table) }}
{% endmacro %}

{% macro greenplum__check_schema_exists(information_schema, schema) -%}
  {% if information_schema.database -%}
    {{ adapter.verify_database(information_schema.database) }}
  {%- endif -%}
  {% call statement('check_schema_exists', fetch_result=True, auto_begin=False) %}
    select count(*) from pg_namespace where nspname = '{{ schema }}'
  {% endcall %}
  {{ return(load_result('check_schema_exists').table) }}
{% endmacro %}


{% macro greenplum__current_timestamp() -%}
  now()
{%- endmacro %}

{% macro greenplum__snapshot_string_as_time(timestamp) -%}
    {%- set result = "'" ~ timestamp ~ "'::timestamp without time zone" -%}
    {{ return(result) }}
{%- endmacro %}


{% macro greenplum__snapshot_get_time() -%}
  {{ current_timestamp() }}::timestamp without time zone
{%- endmacro %}

{#
  Greenplum tables have a maximum length off 63 characters, anything longer is silently truncated.
  Temp relations add a lot of extra characters to the end of table namers to ensure uniqueness.
  To prevent this going over the character limit, the base_relation name is truncated to ensure
  that name + suffix + uniquestring is < 63 characters.
#}
{% macro greenplum__make_temp_relation(base_relation, suffix) %}
    {% set dt = modules.datetime.datetime.now() %}
    {% set dtstring = dt.strftime("%H%M%S%f") %}
    {% set suffix_length = suffix|length + dtstring|length %}
    {% set relation_max_name_length = 63 %}
    {% if suffix_length > relation_max_name_length %}
        {% do exceptions.raise_compiler_error('Temp relation suffix is too long (' ~ suffix|length ~ ' characters). Maximum length is ' ~ (relation_max_name_length - dtstring|length) ~ ' characters.') %}
    {% endif %}
    {% set tmp_identifier = base_relation.identifier[:relation_max_name_length - suffix_length] ~ suffix ~ dtstring %}
    {% do return(base_relation.incorporate(
                                  path={
                                    "identifier": tmp_identifier,
                                    "schema": none,
                                    "database": none
                                  })) -%}
{% endmacro %}


{#
  By using dollar-quoting like this, users can embed anything they want into their comments
  (including nested dollar-quoting), as long as they do not use this exact dollar-quoting
  label. It would be nice to just pick a new one but eventually you do have to give up.
#}
{% macro greenplum_escape_comment(comment) -%}
  {% if comment is not string %}
    {% do exceptions.raise_compiler_error('cannot escape a non-string: ' ~ comment) %}
  {% endif %}
  {%- set magic = '$dbt_comment_literal_block$' -%}
  {%- if magic in comment -%}
    {%- do exceptions.raise_compiler_error('The string ' ~ magic ~ ' is not allowed in comments.') -%}
  {%- endif -%}
  {{ magic }}{{ comment }}{{ magic }}
{%- endmacro %}


{% macro greenplum__alter_relation_comment(relation, comment) %}
  {% set escaped_comment = greenplum_escape_comment(comment) %}
  comment on {{ relation.type }} {{ relation }} is {{ escaped_comment }};
{% endmacro %}


{% macro greenplum__alter_column_comment(relation, column_dict) %}
  {% set existing_columns = adapter.get_columns_in_relation(relation) | map(attribute="name") | list %}
  {% for column_name in column_dict if (column_name in existing_columns) %}
    {% set comment = column_dict[column_name]['description'] %}
    {% set escaped_comment = greenplum_escape_comment(comment) %}
    comment on column {{ relation }}.{{ adapter.quote(column_name) if column_dict[column_name]['quote'] else column_name }} is {{ escaped_comment }};
  {% endfor %}
{% endmacro %}