with source as (
    select * from {{ source('raw_esios', 'esios_readings') }}
),

renamed as (
    select
        -- identifiers
        indicator_id,
        indicator_name,

        -- geography
        geo_id,
        geo_name,

        -- timestamps
        -- we use datetime_utc as the canonical timestamp to avoid DST issues
        cast(datetime_utc as timestamp)                         as ts_utc,
        cast(datetime_local as timestamp)                       as ts_local,
        date(cast(datetime_utc as timestamp))                   as date_utc,
        extract(hour from cast(datetime_utc as timestamp))      as hour_utc,

        -- value
        cast(value as float64)                                  as value_mw,

        -- metadata
        _dlt_load_id,
        _dlt_id

    from source
)

select * from renamed