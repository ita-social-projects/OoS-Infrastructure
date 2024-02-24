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
def hello_pubsub(cloud_event: CloudEvent) -> None:
  msg = base64.b64decode(cloud_event.data["message"]["data"]).decode()
  decoded_payload = json.loads(msg)
  summary = decoded_payload["incident"]["summary"]
  state = decoded_payload["incident"]["state"]
  if state == "closed":
    sbl = '✅'
  else:
    sbl = '❌'
  send_discord_message('GCP Alerting!' + sbl +' State: ' + state + 'Summary: ' + summary)
