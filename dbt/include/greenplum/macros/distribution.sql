{% macro distribution(distributed_by, distributed_replicated) %}
    {% set distribution %}
        {% if distributed_by is not none %}
            DISTRIBUTED BY ({{ distributed_by }})
        {% elif distributed_replicated %}
            DISTRIBUTED REPLICATED
        {% else %}
            DISTRIBUTED RANDOMLY
        {% endif %}
    {% endset %}

    {{ return(distribution) }}
{% endmacro %}