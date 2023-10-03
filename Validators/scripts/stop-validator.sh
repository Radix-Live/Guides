#!/bin/bash

# apt install -y expect jq

# Note that validators get shuffled at the start of each epoch, so better not run this script close to epoch end
# Examples:
# ./stop-validator.sh
# ./stop-validator.sh force
# ./stop-validator.sh keep-key

container="root-core-1"

export DISABLE_VERSION_CHECK="true"

read -r VALIDATOR_ADDRESS CONSENSUS_STATUS < <(echo $(babylonnode api system identity | jq -r '.validator_address, .consensus_status'))

echo "VALIDATOR_ADDRESS: ${VALIDATOR_ADDRESS}"
echo "CONSENSUS_STATUS: ${CONSENSUS_STATUS}"

if [[ $CONSENSUS_STATUS == "VALIDATING_IN_CURRENT_EPOCH" && "$1" != "force" ]]
then
  # Monitors the logs, and doesn't catch all the times the validator was leader, so need to wait for a few minutes!
  # But if leadership was logged - you are guaranteed to have some time before next leadership round.
  # A BUG HERE - when you do Ctrl+C inside - the script continues! (you can quickly Ctrl+C twice to exit completely)
  ./expect-leader.sh "docker logs -t $container --tail 2 -f | grep --line-buffered \"leader=\"" "$VALIDATOR_ADDRESS" | grep -E --color "leader=$VALIDATOR_ADDRESS|$"
  sleep 0.35

  echo "Validator completed proposal - stopping now...."
  babylonnode docker stop
  if [[ "$1" != "keep-key" ]]
  then
    echo "MOVING KEYS...."
    ./use-blank-keystore.sh
  fi
elif [[ "$1" = "force" ]]
then
  echo "Force stopping...."
  babylonnode docker stop
else
  echo "Not stopping a node in CONSENSUS_STATUS: ${CONSENSUS_STATUS}"
fi

echo "Script finished ..."
