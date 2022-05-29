
{% macro greenplum__get_catalog(information_schema, schemas) -%}
  {{ return(greenplum__get_catalog(information_schema, schemas)) }}
{%- endmacro %}
