#!/bin/bash




echo Run the following

#curl -X GET -H 'Content-Type: application/json' -u $USERNAME:$PASSWORD -k https://elasticsearch-es-http:9200/_ilm/policy/vector-logs-ilm

# Declare endpoints
endpoints=(
  "_ilm/policy/vector-logs-ilm"
  "_component_template/vector-logs-settings"
  "_component_template/vector-geoip-mappings"
  "_index_template/vector-logs-template"
  "ingest/pipeline/geoip-nginx"
)

# Checking jq is installed
if ! command -v jq &> /dev/null; then
  echo "jq is not installed. Please install it and try again."
  exit 1
fi

# Checking curl is installed
if ! command -v curl &> /dev/null; then
  echo "curl is not installed. Please install it and try again."
  exit 1
fi

echo "Starting elasticsearch deployment..."

for s in ${endpoints[@]}; do
  echo "--------------------------------"
  echo Starting elasticsearch deployment $s...
  # Get endpoint
  output=$(curl -X GET -H 'Content-Type: application/json' \
    -u $USERNAME:$PASSWORD -k https://$ES_ENDPOINT:$ES_PORT/$s)

  echo -e "Get endpoint output: \n"

  echo "Updating endpoint: \n"
  load_file=$(basename $s)

  echo -e "Listing deploument file: $load_file.json \n"
  cat $MOUNT_PATH/$load_file.json

  output=$(curl -X PUT -H 'Content-Type: application/json' \
    -u $USERNAME:$PASSWORD -k https://$ES_ENDPOINT:$ES_PORT/$s \
    -d @$MOUNT_PATH/$load_file.json)

  echo -e "Update endpoint output: \n"
  echo $output | jq .
done



