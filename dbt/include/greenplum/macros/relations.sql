{% macro greenplum_get_relations() -%}
  {{ return(postgres_get_relations()) }}
{% endmacro %}
