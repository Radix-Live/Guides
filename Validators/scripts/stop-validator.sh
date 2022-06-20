#!/bin/bash

# apt install -y jq

# Examples:
# ./stop-validator.sh
# ./stop-validator.sh force
# ./stop-validator.sh keep-key

HOST="https://localhost"
export DISABLE_VERSION_CHECK="true"

VALIDATOR_ADDRESS=$(curl -u superadmin:$NGINX_SUPERADMIN_PASSWORD -k -s -X POST "$HOST/key/list" -H "Content-Type: application/json" \
                    -d '{"network_identifier": {"network": "mainnet"}}' \
                    | jq -r ".public_keys[0].identifiers.validator_entity_identifier.address")
echo "VALIDATOR_ADDRESS: ${VALIDATOR_ADDRESS}"
IS_VALIDATING=$(curl -u admin:$NGINX_ADMIN_PASSWORD -k -s -X POST "$HOST/entity" -H "Content-Type: application/json" \
                -d "{\"network_identifier\": {\"network\": \"mainnet\"}, \"entity_identifier\":
                    {\"address\": \"$VALIDATOR_ADDRESS\", \"sub_entity\": {\"address\": \"system\"}}}" \
                | jq ".data_objects | any(.type == \"ValidatorBFTData\")")
echo "IS_VALIDATING: ${IS_VALIDATING}"

get_completed_proposals () {
   curl -u admin:$NGINX_ADMIN_PASSWORD -k -s -X POST "$HOST/entity" -H "Content-Type: application/json" \
   -d "{\"network_identifier\": {\"network\": \"mainnet\"}, \"entity_identifier\":
      {\"address\": \"$VALIDATOR_ADDRESS\", \"sub_entity\": {\"address\": \"system\"}}}" \
    | jq ".data_objects[] | select(.type == \"ValidatorBFTData\") | .proposals_completed"
}

check_return_code () {
    if [[ $? -eq 0 ]]
    then
        echo "Successfully stopped validator node and restarted."
    else
        echo "Error: $?"
    fi
}

if [[ $IS_VALIDATING == true && "$1" != "force" ]]
then
  PROPOSALS_COMPLETED=$(get_completed_proposals)
  echo "Wait until node completed proposal to minimise risk of a missed proposal ..."
  while (( $(get_completed_proposals) == PROPOSALS_COMPLETED)) || (( $(get_completed_proposals) == 0))
  do
      echo "Waiting ..."
      sleep 1
  done
  echo "Validator completed proposal - stopping now...."
  radixnode docker stop -f radix-fullnode-compose.yml
  check_return_code
  if [[ "$1" != "keep-key" ]]
  then
    mv -f /root/node-config/node-keystore.ks /root/node-config/node-keystore.validator.ks
    mv -f /root/node-config/node-keystore.blank.ks /root/node-config/node-keystore.ks
  fi
fi

echo "Script finished ..."