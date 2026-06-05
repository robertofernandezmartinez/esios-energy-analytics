with demand as (
    select
        ts_utc,
        date_utc,
        hour_utc,
        geo_id,
        geo_name,
        value_mw as demand_mw
    from {{ ref('int_esios__readings_enriched') }}
    where indicator_name = 'demanda_real'
),

price as (
    select
        ts_utc,
        -- ESIOS returns price in mEUR/MWh (milieuro), divide by 1000 to get EUR/MWh
        round(value_mw / 1000, 2) as price_eur_mwh
    from {{ ref('int_esios__readings_enriched') }}
    where indicator_name = 'precio_mercado_spot'
),

final as (
    select
        d.date_utc,
        d.hour_utc,
        d.ts_utc,
        d.geo_id,
        d.geo_name,
        d.demand_mw,
        p.price_eur_mwh,

        -- flag anomalous demand drop (below 50% of daily average)
        avg(d.demand_mw) over (
            partition by d.date_utc
        )                                                       as avg_daily_demand_mw,

        round(
            safe_divide(d.demand_mw,
                avg(d.demand_mw) over (partition by d.date_utc)
            ) * 100, 2
        )                                                       as pct_of_daily_avg,

        -- flag negative price hours (excess renewables)
        p.price_eur_mwh < 0                                     as is_negative_price,

        -- flag demand collapse (below 20% of daily average) 
        safe_divide(d.demand_mw,
            avg(d.demand_mw) over (partition by d.date_utc)
        ) < 0.2                                                 as is_demand_collapse

    from demand d
    left join price p
        on d.ts_utc = p.ts_utc
)

select * from final