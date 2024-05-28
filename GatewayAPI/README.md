# Radix Gateway API setup (Dockerized)

## Introduction
The setup includes: Radix Node + Data Aggregator + Gateway API + Postgres DB, all running on the same dedicated server via Docker Compose.
A Fully Dockerized setup is recommended due to its simplicity and is usually performant enough for private usage of the Gateway API.

The result of this setup is Gateway API running on `http://<server_ip>:5207`, Core/System API - on `https://<server_ip>:443` (requires authentication with admin/superadmin passwords).

For additional security, please make sure that none of the exposed ports are accessible from outside your intranet.

This doc is based on Radix [Node](https://docs.radixdlt.com/docs/node) and [Network Gateway](https://docs.radixdlt.com/docs/network-gateway) setup guides.


## Hardware requirements
The setup requires maintaining two copies of the Radix Ledger (one for the Radix Node DB, and one in Postgres DB, used by the Data Aggregator and Gateway API itself),
so the server needs to have 2 separate SSD/NVMe disks. At the moment of writing this, the Radix Node DB size is ~200Gb, Postgres DB is ~400Gb.

Minimum - 3/6x 2.5GHz+ CPU, 16 Gb RAM  
Recommended - 4/8x 3.0GHz+ CPU, 32 Gb RAM  
Preferred - 8/16x 3.0GHz+ CPU, 64 Gb RAM


## Setup
OS - Ubuntu 22.04.3 LTS

#### 1. Mounting the SSDs
``` shell
apt update
apt upgrade -y

mkdir /RADIXDB
mkdir /PGDB

mount /dev/sdb /PGDB
```
If it doesn't mount - create FS with `mkfs.ext4 /dev/sdb` and try mounting again.  
Now to preserve mount after reboot:

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
UUID=52fca22b-b741-4e11-9142-f7bb63ad6e2a /PGDB ext4 defaults 0 1
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

rm -rf /RADIXDB/*
rm -rf /PGDB/*
```

#### 2. Installing Docker via Radix CLI (Command-Line Interface)
From here on, you should work in your users' home dir.
```shell
cd ~

# Here you can change the version from "22.04" to "20.04" if needed
wget -O babylonnode https://github.com/radixdlt/babylon-nodecli/releases/download/2.2.0/babylonnode-ubuntu-22.04
chmod +x babylonnode
sudo mv babylonnode /usr/local/bin
```
Exit ssh login and re-login for user addition to group "docker" to take effect.


#### 3. Configuring Radix services
This section is a short essence of the [official guide](https://docs.radixdlt.com/docs/node-setup-guided-installing-node),
please refer to it in case you have any questions.
First, we configure `babylonnode` so it can be later used to conveniently start/stop the services:
```shell
cd ~
babylonnode docker config -m CORE
```
Enter network: "1", you can skip all other options, we will have all that in the `docker-compose.yml` and env variables.  
`Okay to update the config file [Y/n]` - Y.

The Radix node setup doc says to run the "install" step with the babylonnode. Do not ever run it! 
This guide suggests to manage the compose file manually while running "install" will overwrite it.  

Download the compose file this Guide to `/<your_user>` dir:
```shell
wget -O docker-compose.yml https://raw.githubusercontent.com/Radix-Live/Guides/main/GatewayAPI/files/docker-compose.yml
```

The compose file depends on a few environment variables. You can put them all to your `~/.bashrc`:
```shell
export NETWORK_NAME=mainnet

# the compose file uses RADIX_NODE_KEYSTORE_PASSWORD but babylonnode needs "RADIXDLT_NODE_KEY_PASSWORD" and "RADIXDLT_NODE_KEYSTORE_PASSWORD".
export RADIXDLT_NODE_KEY_PASSWORD=keystore_password
export RADIXDLT_NODE_KEYSTORE_PASSWORD=keystore_password

export RADIXDLT_NETWORK_SEEDS_REMOTE=radix://node_rdx1qf2x63qx4jdaxj83kkw2yytehvvmu6r2xll5gcp6c9rancmrfsgfw0vnc65@52.212.35.209,radix://node_rdx1qgxn3eeldj33kd98ha6wkjgk4k77z6xm0dv7mwnrkefknjcqsvhuu4gc609@54.79.136.139,radix://node_rdx1qwrrnhzfu99fg3yqgk3ut9vev2pdssv7hxhff80msjmmcj968487uugc0t2@43.204.226.50,radix://node_rdx1q0gnmwv0fmcp7ecq0znff7yzrt7ggwrp47sa9pssgyvrnl75tvxmvj78u7t@52.21.106.232

export POSTGRES_SUPERUSER=postgres
export POSTGRES_SUPERUSER_PASSWORD=p_myPassword
export POSTGRES_DB_NAME=radix_ledger

export NODE_0_NAME=NodeZero
export NODE_0_CORE_API_ADDRESS=http://core:3333/core
```

Update the `docker-compose.yml` - adjust `-Xms`, `-Xmx` of the `core` service according to the machine's specs (recommended - 1/4 of available RAM, but no more than 8Gb).


Setup nginx passwords (one by one, skip if you won't be using nginx):
```shell
babylonnode auth set-admin-password --setupmode DOCKER
babylonnode auth set-metrics-password --setupmode DOCKER
```
Add to `~/.bashrc`:
```shell
export NGINX_ADMIN_PASSWORD="pass1"
export NGINX_METRICS_PASSWORD="pass2"
```

```
. ~/.bashrc
```
#### 3b. [Optional] Download the latest **unofficial** Node DB snapshot to speed up sync.
Syncing the  node from scratch takes time (more than 40h atm).  
To avoid the wait you can download the latest of our daily snapshots.  
See [The Guide](https://github.com/Radix-Live/Guides/tree/main/LedgerSnapshots) for more details, here are all the shell commands, just update the date (remember, it is perfectly fine to observe the errors during download, as long as DL speed is high!):
```shell
sudo apt update
sudo apt install aria2 zstd

TODAY="2024-05-28"
aria2c -x3 -s16 -k4M --piece-length=4M --disk-cache=256M --lowest-speed-limit=250k ftp://snapshots.radix.live/$TODAY/RADIXDB-INDEX.tar.zst.metalink

rm -rf /RADIXDB/*
tar --use-compress-program=zstdmt -xvf RADIXDB-INDEX.tar.zst --exclude=./address_book -C /RADIXDB/
# Ensure proper permissions
sudo chown -R systemd-coredump:systemd-coredump /RADIXDB
# delete the archive after you make sure that the Core Node starts:
rm RADIXDB-INDEX.tar.zst*
```

#### 4. Starting everything
Now, let's test if everything is OK so far. Start everything:
```
babylonnode docker start
docker ps -a
```
Check the core container logs (e.g. `docker logs -t root-core-1 --tail 200`) - it should start ingesting the initial Babylon state: `Committing data ingestion chunk`.  
This will take some time (up to 20 minutes), after which the node should start syncing with the network.  
When the above has finished, run this a few times with an interval of a few seconds:
```
babylonnode api system network-sync-status
```
On a properly running node, you will see that `current_state_version` increases.  
When it catches up with the `target_state_version` - the node is fully synced.

You can check the Data Aggregation progress with:
```
docker exec -it root-radix_db-1 psql -U postgres -d radix_ledger -c $'select state_version from ledger_transactions order by state_version desc limit 1;'
```
You can compare it with the latest state version observed on Radix Ledger (`target_state_version`) to get the overall progress %.

#### 5. Managing the node

If you change the compose file or the env variables (e.g. during an upgrade to a later version) - you need to recreate the containers:
```
babylonnode docker stop
babylonnode docker start
```

`/PGDB` and `/RADIXDB` folders are not suitable for live backups! If you need to make a backup - you need to stop the node software and then perform a backup (or just copy the dirs).


