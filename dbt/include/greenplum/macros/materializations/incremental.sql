{% macro get_incremental_truncate_insert_sql(arg_dict) %}

  {% do return(greenplum__get_truncate_insert_sql(arg_dict["target_relation"], arg_dict["temp_relation"], arg_dict["dest_columns"])) %}

{% endmacro %}

{% macro greenplum__get_truncate_insert_sql(target, source, dest_columns) -%}

    {%- set dest_cols_csv = get_quoted_csv(dest_columns | map(attribute="name")) -%}

    truncate {{ target }};

    insert into {{ target }} ({{ dest_cols_csv }})
    (
        select {{ dest_cols_csv }}
        from {{ source }}
    )

{%- endmacro %}
