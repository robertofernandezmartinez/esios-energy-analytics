with readings as (
    select * from {{ ref('stg_esios__readings') }}
),

enriched as (
    select
        -- identifiers
        indicator_id,
        indicator_name,

        -- geography
        geo_id,
        geo_name,

        -- timestamps
        ts_utc,
        ts_local,
        date_utc,
        hour_utc,

        -- value
        value_mw,

        -- enrichment: technology category derived from indicator name
        case indicator_name
            when 'demanda_real'                 then 'demand'
            when 'precio_mercado_spot'          then 'price'
            when 'generacion_eolica'            then 'generation'
            when 'generacion_solar_fotovoltaica' then 'generation'
            when 'generacion_hidraulica'        then 'generation'
            when 'generacion_nuclear'           then 'generation'
            when 'generacion_carbon'            then 'generation'
            when 'generacion_ciclo_combinado'   then 'generation'
            else 'unknown'
        end as data_type,

        -- enrichment: renewable flag
        case indicator_name
            when 'generacion_eolica'            then true
            when 'generacion_solar_fotovoltaica' then true
            when 'generacion_hidraulica'        then true
            when 'generacion_nuclear'           then false
            when 'generacion_carbon'            then false
            when 'generacion_ciclo_combinado'   then false
            else null
        end as is_renewable,

        -- enrichment: human readable technology name
        case indicator_name
            when 'demanda_real'                 then 'Real Demand'
            when 'precio_mercado_spot'          then 'Spot Market Price'
            when 'generacion_eolica'            then 'Wind'
            when 'generacion_solar_fotovoltaica' then 'Solar PV'
            when 'generacion_hidraulica'        then 'Hydro'
            when 'generacion_nuclear'           then 'Nuclear'
            when 'generacion_carbon'            then 'Coal'
            when 'generacion_ciclo_combinado'   then 'Combined Cycle'
            else indicator_name
        end as technology_name,

        -- metadata
        _dlt_load_id,
        _dlt_id

    from readings
)

select * from enriched