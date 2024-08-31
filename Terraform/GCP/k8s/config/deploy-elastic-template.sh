#!/bin/bash

# It's terraform template file

set -o pipefail  # trace ERR through pipes
set -o errtrace  # trace ERR through 'time command' and other functions
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value

apt update && apt-get -y install jq

# initialize array terraform variable
declare -ra es_endpoints_list=(${
  join(" ", [
    for s in array : "'${replace(s, "'", "'\\''")}'"
  ])
})

for s in "$${es_endpoints_list[@]}"; do
  echo "--------------------------------"
  echo Starting elasticsearch deployment "$${s}"...
  # Get endpoint
  output=$(curl -X GET -H 'Content-Type: application/json' \
    -u $USERNAME:$PASSWORD -k https://$ES_ENDPOINT:$ES_PORT/"$${s}")

  echo "Get endpoint output: \n"
  echo $output | jq .

  echo "Updating endpoint: \n"
  output=$(curl -X GET -H 'Content-Type: application/json' \
    -u $USERNAME:$PASSWORD -k https://$ES_ENDPOINT:$ES_PORT/"$${s}")

  echo "Update endpoint output: \n"
  echo $output | jq .
done

