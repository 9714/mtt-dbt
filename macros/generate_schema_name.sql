{% macro generate_schema_name(custom_schema_name, node) %}

    {% set schema = custom_schema_name | trim if custom_schema_name else target.schema %}
    {% set client = var('client_name') %}

    {% if node.resource_type == 'seed' %}
        {# seed: dev/stg/prd は別 GCP プロジェクトのため mtt_raw 固定 #}
        {{ var('raw_dataset') }}

    {% elif target.name == 'prd' %}
        {# prd は suffix なし: {client_name}_{schema} #}
        {{ client }}_{{ schema }}

    {% else %}
        {# dev / stg / 個人: {client_name}_{schema}_{target.schema} #}
        {{ client }}_{{ schema }}_{{ target.schema }}

    {% endif %}

{% endmacro %}
