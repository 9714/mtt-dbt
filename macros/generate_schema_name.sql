{% macro generate_schema_name(custom_schema_name, node) %}

    {% set schema = custom_schema_name | trim if custom_schema_name else target.schema %}
    {% set client = var('client_name') %}

    {# suffix: prd はなし、それ以外は target.schema（profile の dataset）を使用 #}
    {% set suffix = '' if target.name == 'prd' else '_' ~ target.schema %}

    {% if node.resource_type == 'seed' %}
        {# seed: {client_name}_raw または {client_name}_raw_{dataset} #}
        {{ client }}_raw{{ suffix }}

    {% elif target.name == 'prd' %}
        {# prd は suffix なし: {client_name}_{schema} #}
        {{ client }}_{{ schema }}

    {% else %}
        {# dev / stg / 個人: {client_name}_{schema}_{dataset} #}
        {{ client }}_{{ schema }}_{{ target.schema }}

    {% endif %}

{% endmacro %}
