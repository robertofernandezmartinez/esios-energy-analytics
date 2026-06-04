import requests
import os
from dotenv import load_dotenv
import json

load_dotenv()

TOKEN = os.getenv("ESIOS_TOKEN")

headers = {
    "Authorization": f"Token token={TOKEN}",
    "Accept": "application/json",
    "Content-Type": "application/json"
}

# Demanda real — indicador 1293
url = "https://api.esios.ree.es/indicators/1293"
params = {
    "start_date": "2025-04-28T00:00:00",
    "end_date": "2025-04-28T23:59:59",
    "time_trunc": "hour"
}

response = requests.get(url, headers=headers, params=params)
print(f"Status: {response.status_code}")
print(json.dumps(response.json(), indent=2))