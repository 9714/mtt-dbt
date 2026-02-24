{% macro generate_schema_name(custom_schema_name, node) %}

    {% set schema = custom_schema_name | trim if custom_schema_name else target.schema %}
    {% set client = var('client_name') %}

    {% if node.resource_type == 'seed' %}
        {# seed は常に {client_name}_raw（環境 suffix なし） #}
        {{ client }}_raw

    {% elif target.name == 'prd' %}
        {# prd は suffix なし: {client_name}_{schema} #}
        {{ client }}_{{ schema }}

    {% else %}
        {# dev / stg はその他の環境は suffix あり: {client_name}_{schema}_{target.name} #}
        {{ client }}_{{ schema }}_{{ target.name }}

    {% endif %}

{% endmacro %}
