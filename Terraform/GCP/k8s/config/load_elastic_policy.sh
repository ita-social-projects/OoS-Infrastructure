#!/bin/bash

echo Run the following
curl -X GET -H 'Content-Type: application/json' -u $USERNAME:$PASSWORD -k https://elasticsearch-es-http:9200/_ilm/policy/vector-logs-ilm