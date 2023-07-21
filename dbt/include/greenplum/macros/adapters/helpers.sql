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
        then compresstype || ', ' || compresslevel
      end as encoding_options
    from
      parsed_options

  {% endset -%}

  {{ return(run_query(sql)) }}

{%- endmacro %}


{% macro parse_relation_encoding_params(relation) -%}

  {% set params_raw = get_relation_encoding_params(relation) -%}

  {% if params_raw.rows[0][0] is not none %}
     {% set encoding_params = 'encoding(' + params_raw.rows[0][0] + ')' %}
  {% else %}
    {% set encoding_params = '' %}
  {% endif %}

  {{ return(encoding_params) }}

{% endmacro -%}
