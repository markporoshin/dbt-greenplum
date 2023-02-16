{% macro partitions(
    raw_partition,
    partition_type,
    partition_column,
    default_partition_name,
    partition_start,
    partition_end,
    partition_every,
    partition_values
) %}
    {% set partitions_spec %}
        {% if raw_partition is not none %}
            {{ raw_partition }}
        {% else %}
            {{ log("DeprecationWarning: This partition functionality is deprecated, please use `raw_partition` parameter to specify table partitions", info=True) }}
            PARTITION BY {{ partition_type }} ("{{ partition_column }}")
            (
                {% if partition_type == 'LIST' %}
                    {{ partition_values }},
                    DEFAULT PARTITION {{ default_partition_name }}
                {% else %}
                    START ('{{ partition_start }}') INCLUSIVE
                    END ('{{ partition_end }}') EXCLUSIVE
                    EVERY (INTERVAL '{{ partition_every }}'),
                    DEFAULT PARTITION {{ default_partition_name }}
                {% endif %}
            )
        {% endif %}
    {% endset %}

    {{ return(partitions_spec) }}
{% endmacro %}