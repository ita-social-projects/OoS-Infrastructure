#!/bin/bash




echo Run the following

#curl -X GET -H 'Content-Type: application/json' -u $USERNAME:$PASSWORD -k https://elasticsearch-es-http:9200/_ilm/policy/vector-logs-ilm

# arrays endpoints #
# declare endpoints
# endpoints[0]="_component_template/vector-geoip-mappings"
# endpoints[1]="_ilm/policy/vector-logs-ilm"
# endpoints[2]="ingest/pipeline/geoip-nginx"
# endpoints[3]="_component_template/vector-logs-settings"
# endpoints[4]="_index_template/vector-logs-template"

echo "Starting elasticsearch deployment..."

for s in ${endpoints[@]}; do
  echo $s
done

