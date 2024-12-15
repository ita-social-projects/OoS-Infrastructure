#!/bin/bash

# It's terraform template file

set -o pipefail  # trace ERR through pipes
set -o errtrace  # trace ERR through 'time command' and other functions
set -o nounset   # set -u : exit the script if you try to use an uninitialised variable
set -o errexit   # set -e : exit the script if any statement returns a non-true return value

apt update && apt-get -y install jq curl

# Initialize endpoint list. Array comes from terraform variable
declare -ra kibana_rules_list=(${
  join(" ", [
    for s in array : "'${replace(s, "'", "'\\''")}'"
  ])
})

echo "Starting deploy..."

for s in "$${kibana_rules_list[@]}"; do
  printf '%.0s-' {1..64}; echo
  echo "Starting Kibana rule: $${s}"

  echo "Getting rule: $${s}"
  output=$(curl --silent -X GET -H 'kbn-xsrf: true' -H 'Content-Type: application/json' \
    -u $USERNAME:$PASSWORD -k $KIBANA_ENDPOINT/api/alerting/rule/"$${s}")

  echo "Output Getting rule: $${s}"
  echo $output | jq .

  result_code=$(echo $output | jq -r '.statusCode // empty')
  result_id=$(echo $output | jq -r '.id // empty')

  if [[ "$result_code" == 404 ]] # Not found
  then # Creat
    echo "============================ CREATE RULE: $${s} ===================================="
    output=$(curl --silent -X POST -H 'kbn-xsrf: true' -H 'Content-Type: application/json' \
      -u $USERNAME:$PASSWORD -k $KIBANA_ENDPOINT/api/alerting/rule/"$${s}" \
      -d @$MOUNT_PATH/"$${s}.json")

    echo $output | jq .
  elif [[ ! -z "$result_id" ]] # Not null
  then # Update
    echo "============================ UPDATE RULE: $${s} ===================================="
    rule=$(cat "$MOUNT_PATH/$${s}.json" | jq 'del(.rule_type_id, .consumer)')
    output=$(curl -X PUT -H 'kbn-xsrf: true' -H 'Content-Type: application/json' \
      -u $USERNAME:$PASSWORD -k $KIBANA_ENDPOINT/api/alerting/rule/"$${s}" \
      -d "$rule")
    echo $output | jq .
  else
    echo Other error occurred!!!
  fi
done
