{{ config(
    materialized='incremental',
    unique_key='_dlt_id',
    incremental_strategy='merge'
) }}

with source as (
    select * from {{ source('raw_esios', 'esios_readings') }}

    {% if is_incremental() %}
    -- On incremental runs, only process rows newer than the latest ts_utc we already have
    where cast(datetime_utc as timestamp) > (
        select max(ts_utc) from {{ this }}
    )
    {% endif %}
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