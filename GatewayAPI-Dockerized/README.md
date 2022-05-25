# Radix Gateway API setup (Dockerized)

2022-05-25: A bit outdated, needs updating

## Introduction
The setup includes: Radix Full Node + Data Aggregator + Gateway API + Postres DB, all running on the same dedicated server via Docker Compose.
A Fully Dockerized setup is recommended due to its simplicity and is usually performant enough for private usage of the Gateway API.

See also a variation with the installation of a [standalone Postgres DB + replica](../GatewayAPI-Full)

The result of this setup is Gateway API running on `http://<server_ip>:5308`, Core/System API - on `https://<server_ip>:443` (requires authentication with admin/superadmin passwords).

For additional security, please make sure that none of the exposed ports are accessible from outside your intranet.

This doc is based on Radix [Node](https://docs.radixdlt.com/main/node-and-gateway/node-introduction.html) and [Network Gateway](https://docs.radixdlt.com/main/node-and-gateway/network-gateway.html) setup guides.


## Hardware requirements
The setup requires maintaining two copies of the Radix Ledger (one for the Radix Node DB, and one in Postgres DB, used by the Data Aggregator and Gateway API itself),
so the server needs to have 2 separate SSD drives. At the moment of writing this, the Ledger size is ~80Gb (stored twice).

Minimum - 3/6x 2.5GHz+ CPU, 16 Gb RAM, 2x 240Gb SSD  
Recommended - 4/8x 3.0GHz+ CPU, 32 Gb RAM, 2x 500Gb SSD  
Preferred - 8/16x 3.0GHz+ CPU, 64 Gb RAM, 2x 500Gb NVMe


## Setup
OS - Ubuntu 20.04.3 LTS

#### 1. Mounting the SSDs
``` shell
apt update
apt upgrade -y

mkdir /RADIXDB
mkdir /WRITEDB

mount /dev/sdb /WRITEDB
```
if it doesn't mount - create FS with `mkfs.ext4 /dev/sdb`

```
ls -al /dev/disk/by-uuid/
```
Save the above output somewhere

``` shell
cp /etc/fstab /etc/fstab.original
nano /etc/fstab
```
Append the entry for the second disk, e.g.:
``` 
UUID=52fca22b-b741-4e11-9142-f7bb63ad6e2a /WRITEDB ext4 defaults 0 0
```

``` shell
findmnt --verify
```
Make sure that there are no \[E\]rrors

``` shell
reboot
```
> *ssh to the node*
``` shell
df -h # check that it mounted

rm -rf /WRITEDB/lost+found/
```

#### 2. Installing Docker via Radix CLI (Command-Line Interface)

```
mkdir /radixdlt
cd /radixdlt

wget -O radixnode https://github.com/radixdlt/node-runner/releases/download/1.1.1/radixnode-ubuntu-20.04
chmod +x radixnode
sudo mv radixnode /usr/local/bin

radixnode docker configure
```
Exit ssh and relogin back for user addition to group "docker" to take effect.


#### 3. Configuring Radix services

```
cd /radixdlt
radixnode docker setup -n fullnode -t radix://rn1qthu8yn06k75dnwpkysyl8smtwn0v4xy29auzjlcrw7vgduxvnwnst6derj@54.216.99.177
```
Configure the node password (avoid special characters in the password).  
As the data directory for the ledger, put: `/RADIXDB`.  
Network - `[M]Mainnet`.  
`Okay to start the node [Y/n]` - answer "no".

Setup nginx passwords (one at a time):
```
radixnode auth set-admin-password --setupmode DOCKER
radixnode auth set-superadmin-password --setupmode DOCKER
radixnode auth set-metrics-password --setupmode DOCKER
```
Add to `~/.bashrc`:
```
 export NGINX_ADMIN_PASSWORD="pass1"
 export NGINX_SUPERADMIN_PASSWORD="pass2"
 export NGINX_METRICS_PASSWORD="pass3"
```

```
. ~/.bashrc
```
Start the node, wait a minute, and see if it syncs
```
radixnode docker start -f radix-fullnode-compose.yml -t radix://rn1qthu8yn06k75dnwpkysyl8smtwn0v4xy29auzjlcrw7vgduxvnwnst6derj@54.216.99.177
docker ps -a
radixnode api core network-status | grep version
```
On a properly running node, you will see that `current_state_version` increases between invocations of `radixnode api core network-status | grep version`.  
If the Radix Node software works - great! Now put it down, so we can add additional services.
```
radixnode docker stop -f radix-fullnode-compose.yml
```
Delete `radix-fullnode-compose.yml` and upload the files from this gist (4 ea) to `/radixdlt`
(can do simply `nano <filename>` and then paste).  
Update the files:
- `.env` - change `RADIXDLT_NODE_KEY_PASSWORD` and `POSTGRES_SUPERUSER_PASSWORD`
- `radix-fullnode-compose.yml` - adjust `-Xms`, `-Xmx` and `mem_limit` of the `core` service according to the machine's specs (recommended - 1/4 of available RAM, but no more than 8Gb).

#### 4. Starting everything
```
radixnode docker start -f radix-fullnode-compose.yml -t radix://rn1qthu8yn06k75dnwpkysyl8smtwn0v4xy29auzjlcrw7vgduxvnwnst6derj@54.216.99.177
docker ps -a
```

That's it!   
The Node should start syncing, Aggregator aggregating, Gateway node responds with "NotSyncedUpError".  
Sync takes around 12-18 hours, Aggregating up to 36-48 hrs, meanwhile try to `reboot` and see if all containers start properly afterward.

You can check both Node Sync and Data Aggregation progress with:
```
docker exec -it radixdlt_radix_db_1 psql -U postgres -d radix_ledger -c $'select * from ledger_status;'
```
Here, `sync_status_target_state_version` is the latest state version processed by the Radix Node, and `top_of_ledger_state_version` is the latest state version that was aggregated and available in the API.  
You can compare it with the latest state version observed on Radix Ledger (`target_state_version` from executing `radixnode api core network-status | grep version`) to get the overall progress %.

#### 5. Managing the node
You can start/stop everything (e.g. for server maintenance) by running:
```
docker-compose -f radix-fullnode-compose.yml down
docker-compose -f radix-fullnode-compose.yml up -d
```

If you change the compose file or the env variables (e.g. during an upgrade to a later version) - you need to recreate the containers:
```
radixnode docker start -f radix-fullnode-compose.yml -t radix://rn1qthu8yn06k75dnwpkysyl8smtwn0v4xy29auzjlcrw7vgduxvnwnst6derj@54.216.99.177
```

`/WRITEDB` and `/RADIXDB` folders are not suitable for live backups! If you need to make a backup - you need to stop the node software and then perform a backup (or just copy the dirs).


