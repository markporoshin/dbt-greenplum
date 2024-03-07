{% macro storage_parameters(appendonly, blocksize, orientation, compresstype, compresslevel) %}
    {% set storage_parameters %}
        with (
            appendonly={{ appendonly }}
        {% if appendonly %}
            , blocksize={{ blocksize }}
            , compresstype={{ compresstype }}
            , compresslevel={{ compresslevel }}
            , orientation={{ orientation }}
        {% endif %}
        )
    {% endset %}

    {{ return(storage_parameters) }}
{% endmacro %}