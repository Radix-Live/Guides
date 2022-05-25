#!/usr/bin/expect -f

spawn radixnode docker start -f radix-fullnode-compose.yml -t "$::env(RADIXDLT_NETWORK_NODE)"

expect "Enter the password of the existing keystore file"
send -- "$::env(RADIXDLT_NODE_KEY_PASSWORD)"
send -- "\n"

interact
