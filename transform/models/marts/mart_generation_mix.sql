with generation as (
    select * from {{ ref('int_esios__readings_enriched') }}
    where data_type = 'generation'
),

hourly as (
    select
        date_utc,
        hour_utc,
        ts_utc,
        geo_id,
        geo_name,
        technology_name,
        is_renewable,
        value_mw,

        -- total generation across all technologies for this hour
        sum(value_mw) over (
            partition by ts_utc, geo_id
        ) as total_generation_mw,

        -- renewable generation for this hour
        sum(case when is_renewable then value_mw else 0 end) over (
            partition by ts_utc, geo_id
        ) as renewable_generation_mw

    from generation
),

final as (
    select
        date_utc,
        hour_utc,
        ts_utc,
        geo_id,
        geo_name,
        technology_name,
        is_renewable,
        value_mw,
        total_generation_mw,
        renewable_generation_mw,

        -- percentage of total for this technology in this hour
        round(
            safe_divide(value_mw, total_generation_mw) * 100, 2
        ) as pct_of_total,

        -- percentage of renewable in total generation this hour
        round(
            safe_divide(renewable_generation_mw, total_generation_mw) * 100, 2
        ) as pct_renewable

    from hourly
)

select * from final