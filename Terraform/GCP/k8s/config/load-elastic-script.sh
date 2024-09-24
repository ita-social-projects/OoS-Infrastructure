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
  "_ilm/policy/.monitoring-8-ilm-policy"
  # APM policies configuration
  # "_ilm/policy/logs-apm.app_logs-default_policy"
  # "_ilm/policy/logs-apm.error_logs-default_policy"
  # "_ilm/policy/metrics-apm.app_metrics-default_policy"
  # "_ilm/policy/metrics-apm.internal_metrics-default_policy"
  # "_ilm/policy/metrics-apm.service_destination_10m_metrics-default_policy"
  # "_ilm/policy/metrics-apm.service_destination_1m_metrics-default_policy"
  # "_ilm/policy/metrics-apm.service_destination_60m_metrics-default_policy"
  # "_ilm/policy/metrics-apm.service_summary_10m_metrics-default_policy"
  # "_ilm/policy/metrics-apm.service_summary_1m_metrics-default_policy"
  # "_ilm/policy/metrics-apm.service_summary_60m_metrics-default_policy"
  # "_ilm/policy/metrics-apm.service_transaction_10m_metrics-default_policy"
  # "_ilm/policy/metrics-apm.service_transaction_1m_metrics-default_policy"
  # "_ilm/policy/metrics-apm.service_transaction_60m_metrics-default_policy"
  # "_ilm/policy/metrics-apm.transaction_10m_metrics-default_policy"
  # "_ilm/policy/metrics-apm.transaction_1m_metrics-default_policy"
  # "_ilm/policy/metrics-apm.transaction_60m_metrics-default_policy"
  # "_ilm/policy/traces-apm.rum_traces-default_policy"
  # "_ilm/policy/traces-apm.traces-default_policy"
)

# Function to check if a command exists
check_command() {
  if ! command -v "$1" &> /dev/null; then
    echo "$1 is not installed. Please install it and try again."
    exit 1
  fi
}

# Checking required commands
check_command jq
check_command curl

echo "Starting loading script..."

for s in ${endpoints[@]}; do
  printf '%.0s-' {1..64}; echo
  echo Starting loading Elasticsearch template/policy: $s

  # Get endpoint
  output=$(curl --silent -X GET -H 'Content-Type: application/json' \
    -u $USERNAME:$PASSWORD -k $ES_ENDPOINT/$s)

  echo -e "Get endpoint output: \n"
  result_get=$(echo $output | jq -r '.error // empty')
  echo $output | jq .

  if [[ -z "$result_get" ]]; then
    echo -e "Updating Elasticsearch template/policy: $s \n"
  else
    echo -e "Creating Elasticsearch template/policy: $s \n"
  fi

  load_file=$(basename $s)

  echo -e "Output Elasticsearch template/policy file: $load_file.json \n"
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



