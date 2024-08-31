#!/bin/bash

set -o pipefail  # trace ERR through pipes
set -o errtrace  # trace ERR through 'time command' and other functions
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value

# Declare endpoints
endpoints=(
  "_ilm/policy/vector-logs-ilm"
  "_component_template/vector-logs-settings"
  "_component_template/vector-geoip-mappings"
  "_index_template/vector-logs-template"
  "_ingest/pipeline/geoip-nginx"
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

echo "Starting loading script..."

for s in ${endpoints[@]}; do
  printf '%.0s-' {1..64}; echo
  echo Starting loading elasticsearch template/policy: $s
  # Get endpoint
  output=$(curl --silent -X GET -H 'Content-Type: application/json' \
    -u $USERNAME:$PASSWORD -k $ES_ENDPOINT/$s)

  echo -e "Get endpoint output: \n"
  result_get=$(echo $output | jq -r '.error // empty')

  echo $output | jq .

  if [[ -z "$result_get" ]]; then
    echo -e "Updating elasticsearch template/policy: $s \n"
  else
    echo -e "Creating elasticsearch template/policy: $s \n"
  fi

  load_file=$(basename $s)

  echo -e "Output elasticsearch template/policy file: $load_file.json \n"
  cat $load_file.json | jq .

  output=$(curl --silent -X PUT -H 'Content-Type: application/json' \
    -u $USERNAME:$PASSWORD -k $ES_ENDPOINT/$s \
    -d @$load_file.json)

  echo -e "Update endpoint output: \n"
  result_put=$(echo $output | jq -r '.acknowledged')

  if [ "$result_put" = "true" ]; then
    echo -e "\e[32mOK\e[0m"  # Green color for "OK"
    echo $output | jq .
  else
    echo -e "\e[31m${output}\e[0m"  # Red color for the value of output
  fi
done



