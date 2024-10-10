import requests
import base64
import functions_framework
from cloudevents.http.event import CloudEvent
import json
import os

webhook = os.getenv('WEBHOOK_URL')

def send_discord_message(msg) -> str:
  r = requests.post(webhook, json={'content': msg})
  if r.status_code == requests.codes.ok:
    return "Success!"
  else:
    return r.text

@functions_framework.cloud_event
def pubsub_event(cloud_event: CloudEvent) -> None:
  msg = base64.b64decode(cloud_event.data["message"]["data"]).decode()
  decoded_payload = json.loads(msg)
  summary = decoded_payload["message"]
  sbl = '🟡'
  send_discord_message(sbl +' KIBANA ALERTING: ' + '\nSummary: ' + summary)
