#!/bin/bash

echo Run the following
curl -X GET -H 'Content-Type: application/json' http://elasticsearch-es-http/_ilm/policy/vector-logs-ilm