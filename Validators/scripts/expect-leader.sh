#!/usr/bin/expect -f
# apt install -y expect jq

# Waits until text `leader=<address>` (matching both `leader` and `next_leader`) appears in logs, then exits.

set log_command [lindex $argv 0]
set validator [lindex $argv 1]
set timeout 500
spawn bash -c "$log_command"

expect "leader=$validator"

#send \x03
#expect eof
