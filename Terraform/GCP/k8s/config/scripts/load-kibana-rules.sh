#!/bin/bash

set -o pipefail  # trace ERR through pipes
set -o errtrace  # trace ERR through 'time command' and other functions
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value

# Declare endpoints
endpoints=(
  "../kibana-rules/node-load5m.json"
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

echo "Starting runnig script..."

for s in ${endpoints[@]}; do
  printf '%.0s-' {1..64}; echo
  echo Starting creating Kibana rule: $s

  # Create rule
  output=$(curl --silent -X POST -H 'Content-Type: application/json' \
    -u $USERNAME:$PASSWORD -k $KIBANA_ENDPOINT:/api/alerting/rule \
    -d @$s)

  echo -e "Greate endpoint output: \n"
  echo $output | jq -r
done



