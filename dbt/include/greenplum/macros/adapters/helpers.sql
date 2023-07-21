{% macro get_relation_encoding_params(relation) -%}

  {% set sql %}

    with
      reloptions as (
        select unnest(c.reloptions) as options
        from pg_class c
        join pg_namespace pn
          on c.relnamespace = pn.oid
        where
          pn.nspname = '{{ relation.schema }}'
          and c.relname = '{{ relation.identifier }}'
      ),

      parsed_options as (
        select
          max(substring(options, 'compresstype=.*')) as compresstype,
          max(substring(options, 'compresslevel=.*')) as compresslevel
        from
          reloptions
      )

    select
      case when compresslevel is not null and compresstype is not null
        then 'encoding(' || compresstype || ', ' || compresslevel || ')'
      end as encoding_options
    from
      parsed_options

  {% endset -%}

  {{ return(run_query(sql)) }}

{%- endmacro %}


{% macro parse_relation_encoding_params(relation) -%}

  {% set encoding_params = get_relation_encoding_params(relation).rows[0][0] -%}

  {% if encoding_params is none %}
    {% set encoding_params = '' %}
  {% endif %}

  {{ return(encoding_params) }}

{% endmacro -%}
