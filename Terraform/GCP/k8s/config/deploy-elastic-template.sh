#!/bin/bash

# It's terraform template file

set -o pipefail  # trace ERR through pipes
set -o errtrace  # trace ERR through 'time command' and other functions
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value

apt update && apt-get -y install jq curl

# Initialize endpoint list. Array comes from terraform variable
declare -ra es_endpoints_list=(${
  join(" ", [
    for s in array : "'${replace(s, "'", "'\\''")}'"
  ])
})

echo "Starting loading script..."

for s in "$${es_endpoints_list[@]}"; do

  echo ---------- Starting loading elasticsearch template/policy: "$${s}" ----------
  # Get endpoint
  output=$(curl --silent -X GET -H 'Content-Type: application/json' \
    -u $USERNAME:$PASSWORD -k https://$ES_ENDPOINT:$ES_PORT/"$${s}")

  echo -e "Get endpoint output: \n"
  result_get=$(echo $output | jq -r '.error // empty')

  echo $output | jq .

    if [[ -z "$result_get" ]]; then
    echo -e "Updating elasticsearch template/policy: $s \n"
  else
    echo -e "Creating elasticsearch template/policy: $s \n"
  fi

  load_file=$(basename "$${s}")

  echo -e "Output elasticsearch template/policy file: $load_file.json \n"
  cat $MOUNT_PATH/$load_file.json | jq .

  output=$(curl --silent -X PUT -H 'Content-Type: application/json' \
    -u $USERNAME:$PASSWORD -k https://$ES_ENDPOINT:$ES_PORT/"$${s}" \
    -d @$MOUNT_PATH/$load_file.json)

  echo -e "Update endpoint output: \n"
  result_put=$(echo $output | jq -r '.acknowledged')

  if [ "$result_put" = "true" ]; then
    echo -e "\e[32mOK\e[0m"  # Green color for "OK"
    echo $output | jq .
  else
    echo -e "\e[31mERROR\e[0m"  # Red color for "ERROR"
    echo $output | jq .
  fi
done

