import dlt
import requests
import os
import time
from datetime import date, timedelta
from dateutil.relativedelta import relativedelta
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# API token from environment
TOKEN = os.getenv("ESIOS_TOKEN")

# Headers required by ESIOS API
HEADERS = {
    "Accept": "application/json",
    "Content-Type": "application/json",
    "Host": "api.esios.ree.es",
    "x-api-key": TOKEN
}

# Indicators to extract: id -> descriptive name
INDICATORS = {
    1293: "demanda_real",
    460:  "generacion_eolica",
    541:  "generacion_solar_fotovoltaica",
    544:  "precio_mercado_spot",
    1775: "generacion_hidraulica",
    1776: "generacion_nuclear",
    1777: "generacion_carbon",
    1778: "generacion_ciclo_combinado",
}


# Resource: fetches data for a single indicator and yields one row per value
# write_disposition="append" means new data is added, never replaced
@dlt.resource(name="esios_readings", write_disposition="append")
def esios_readings(start_date: str, end_date: str):
    for indicator_id, indicator_name in INDICATORS.items():
        url = f"https://api.esios.ree.es/indicators/{indicator_id}"
        params = {
            "start_date": f"{start_date}T00:00:00",
            "end_date":   f"{end_date}T23:59:59",
            "time_trunc": "hour"
        }

        # Call the API and raise an error if the response is not 200
        response = requests.get(url, headers=HEADERS, params=params)
        response.raise_for_status()
        data = response.json()

        # Flatten the nested values array into individual rows
        for value in data["indicator"]["values"]:
            yield {
                "indicator_id":   indicator_id,
                "indicator_name": indicator_name,
                "value":          value["value"],
                "datetime_local": value["datetime"],
                "datetime_utc":   value["datetime_utc"],
                "geo_id":         value["geo_id"],
                "geo_name":       value["geo_name"],
            }

        # Pause between API calls to respect REE usage policy
        time.sleep(1)


# Source: wraps the readings resource into a DLT source
@dlt.source
def esios_source(start_date: str, end_date: str):
    return esios_readings(start_date, end_date)


def generate_monthly_ranges(start: date, end: date):
    """Generate (start, end) tuples month by month between two dates."""
    current = start
    while current <= end:
        month_end = current + relativedelta(months=1) - timedelta(days=1)
        # Do not exceed the global end date
        month_end = min(month_end, end)
        yield current.strftime("%Y-%m-%d"), month_end.strftime("%Y-%m-%d")
        current += relativedelta(months=1)

if __name__ == "__main__":
    # Set to True to run Snowflake pipeline
    RUN_SNOWFLAKE = False

    # BIGQUERY PIPELINE
    pipeline_bq = dlt.pipeline(
        pipeline_name="esios_pipeline",
        destination="bigquery",
        dataset_name="raw_esios"
    )

    backfill_start = date(2024, 1, 1)
    backfill_end   = date(2025, 12, 31)

    for month_start, month_end in generate_monthly_ranges(backfill_start, backfill_end):
        print(f"[BigQuery] Loading {month_start} → {month_end}")
        load_info = pipeline_bq.run(
            esios_source(start_date=month_start, end_date=month_end)
        )
        print(load_info)
        time.sleep(2)

    # SNOWFLAKE PIPELINE - set RUN_SNOWFLAKE=True to execute
    if RUN_SNOWFLAKE:
        pipeline_sf = dlt.pipeline(
            pipeline_name="esios_pipeline_snowflake",
            destination="snowflake",
            dataset_name="raw_esios"
        )

        for month_start, month_end in generate_monthly_ranges(date(2025, 1, 1), date(2025, 12, 31)):
            print(f"[Snowflake] Loading {month_start} → {month_end}")
            load_info = pipeline_sf.run(
                esios_source(start_date=month_start, end_date=month_end)
            )
            print(load_info)
            time.sleep(2)