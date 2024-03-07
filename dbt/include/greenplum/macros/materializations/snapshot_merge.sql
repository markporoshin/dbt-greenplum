
{% macro greenplum__snapshot_merge_sql(target, source, insert_cols) -%}
  {{ return(postgres__snapshot_merge_sql(target, source, insert_cols)) }}
{% endmacro %}
