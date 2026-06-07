{% macro convert_meur_to_eur(column_name) %}
    -- ESIOS API returns price in mEUR/MWh (milieuro per MWh)
    -- Divide by 1000 to convert to EUR/MWh
    round({{ column_name }} / 1000, 2)
{% endmacro %}