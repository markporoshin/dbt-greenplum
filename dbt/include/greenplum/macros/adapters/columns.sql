{% macro greenplum__alter_relation_add_remove_columns(relation, add_columns, remove_columns) %}

  {% if add_columns is none %}
    {% set add_columns = [] %}
  {% endif %}
  {% if remove_columns is none %}
    {% set remove_columns = [] %}
  {% endif %}

  {% set encoding_params = parse_relation_encoding_params(relation) %}

  {% set sql -%}

     alter {{ relation.type }} {{ relation }}

            {% for column in add_columns %}
               add column {{ column.name }} {{ column.data_type }} {{encoding_params}} {{ ',' if not loop.last }}
            {% endfor %}{{ ',' if add_columns and remove_columns }}

            {% for column in remove_columns %}
                drop column {{ column.name }}{{ ',' if not loop.last }}
            {% endfor %}

  {%- endset -%}

  {% do run_query(sql) %}

{% endmacro %}
