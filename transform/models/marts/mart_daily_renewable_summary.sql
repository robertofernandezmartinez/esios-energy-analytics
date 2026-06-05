with generation as (
    select * from {{ ref('mart_generation_mix') }}
),

daily as (
    select
        date_utc,
        geo_id,
        geo_name,

        -- total generation
        round(sum(value_mw) / 1000, 2)              as total_generation_gwh,

        -- renewable vs non-renewable
        round(sum(case when is_renewable then value_mw else 0 end) / 1000, 2)
                                                    as renewable_gwh,
        round(sum(case when not is_renewable then value_mw else 0 end) / 1000, 2)
                                                    as non_renewable_gwh,

        -- renewable percentage
        round(
            safe_divide(
                sum(case when is_renewable then value_mw else 0 end),
                sum(value_mw)
            ) * 100, 2
        )                                           as pct_renewable,

        -- peak demand hour
        max(value_mw)                               as peak_generation_mw,

        -- number of hours with data
        count(distinct ts_utc)                      as hours_with_data

    from generation
    group by date_utc, geo_id, geo_name
)

select * from daily
order by date_utc