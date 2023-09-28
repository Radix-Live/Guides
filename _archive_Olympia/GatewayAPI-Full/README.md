# Radix Gateway API setup (Full)

## Introduction
The setup includes: Radix Full Node + Data Aggregator + Gateway API + Postgres DB used by Aggregator + Read-only Replica used by the Gateway API itself, all running on the same dedicated server.
I used `Intel Xeon W-2145, 8/16x 3.70GHz, 128Gb RAM, 4x 480 Gb SSD` but half of RAM/CPU should be more than enough for a single consumer (to separate Porsgres from Node DB we still need at least 3 SSDs for the scenario with replica or 2 SSDs without it).

See also a simpler version of installation where [everything runs in Docker](../GatewayAPI-Dockerized).

The result of this setup is Gateway API running on `http://<server_ip>:5308`, Core/System API - on `https://<server_ip>:443` (requires authentication with admin/superadmin passwords).

This doc is based on Radix [Node](https://docs.radixdlt.com/main/node-and-gateway/node-introduction.html) and [Network Gateway](https://docs.radixdlt.com/main/node-and-gateway/network-gateway.html) setup guides.

Closing all internal ports - TBD.


## Hardware requirements
Minimum - 3/6x 2.5GHz+ CPU, 32 Gb RAM, 2x 240Gb SSD  
Recommended - 4/8x 3.0GHz+ CPU, 64 Gb RAM, 3x 240Gb+ SSD  
Preferred - 8/16x 3.0GHz+ CPU, 128 Gb RAM, 3x 500Gb NVMe

If you go with only two SSDs - skip creating the Postgres Replica and just use the main DB with enough cache.

## Setup
OS - Ubuntu 20.04.3 LTS
#### 1. Mounting the SSDs
``` shell
apt update
apt upgrade -y

mkdir /RADIXDB
mkdir /WRITEDB
mkdir /READDB

mount /dev/sdb /RADIXDB
mount /dev/sdc /WRITEDB
# If you have 4 physical disks you can mount /READDB separately, otherise - just skip it and leave on the primary disk
mount /dev/sdd /READDB
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
Append entries for respective drives, e.g.:
``` 
UUID=f57d50bc-e7ec-46d0-aa40-c949a72ba776 /RADIXDB ext4 defaults 0 0
UUID=52fca22b-b741-4e11-9142-f7bb63ad6e2a /WRITEDB ext4 defaults 0 0
UUID=19cb11b0-5605-47c7-ad0e-e2a4ef8433d6 /READDB  ext4 defaults 0 0
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

rm -rf /RADIXDB/lost+found/
rm -rf /WRITEDB/lost+found/
rm -rf /READDB/lost+found/
```

#### 2. Installing Docker via Radix CLI (Command-Line Interface)

```
mkdir /radixdlt
cd /radixdlt

wget -O radixnode https://github.com/radixdlt/node-runner/releases/download/1.3.0/radixnode-ubuntu-20.04
chmod +x radixnode
sudo mv radixnode /usr/local/bin

radixnode docker configure
```
Exit ssh login and relogin back for user addition to group "docker" to take effect.

#### 3. Installing Postgres

```
apt install postgresql postgresql-contrib
nano /etc/environment
```
Append "/usr/lib/postgresql/12/bin/" to PATH
```
sudo -u postgres nano /var/lib/postgresql/.profile
```
Paste `export PATH="$PATH:/usr/lib/postgresql/12/bin/"`

```
reboot # never hurts
```
#### 4. Configuring Postgres + Replica
> *ssh to the node*
```
cd /radixdlt

sudo chown -R postgres:postgres /WRITEDB
sudo chown -R postgres:postgres /READDB
sudo chown -R systemd-coredump:systemd-coredump /RADIXDB

sudo -i -u postgres
mkdir -p /READDB/data
mkdir -p /WRITEDB/data

pg_createcluster -d /WRITEDB/data 12 writer -- -D /WRITEDB/data
```

> if you've got an error "move_conffile: required configuration file .. does not exist" - do:
> ```
> mkdir -p /var/lib/postgresql/12/writer/ 
> cp /WRITEDB/data/postgresql.conf /var/lib/postgresql/12/writer/postgresql.conf
> cp /WRITEDB/data/pg_hba.conf /var/lib/postgresql/12/writer/pg_hba.conf
> cp /WRITEDB/data/pg_ident.conf /var/lib/postgresql/12/writer/pg_ident.conf
> 
> rm -rf /WRITEDB/data/*
> ```
> then try again

``` shell
exit             # logout from postgres user
pg_ctlcluster 12 writer start # or restart
ps aux | grep postgres
```
You should see two clusters up and running (`main` and `writer`), 7 processes in each. Alternative: `pg_lsclusters`

``` shell
sudo -i -u postgres
psql -p 5433
```
``` sql
CREATE ROLE replicant WITH REPLICATION PASSWORD 'any_pass_really' LOGIN;
\q
```
```
nano /etc/postgresql/12/writer/pg_hba.conf
```
Alter rule `local   replication     all` from "peer" to "trust".

``` shell
exit             # logout from postgres user
systemctl restart postgresql

sudo -i -u postgres
pg_basebackup -p 5433 -U replicant -D /READDB/data/ -Fp -Xs -R -P -v -s 1
exit
```

``` shell
nano /etc/postgresql/12/main/postgresql.conf
# -> update "data_directory" to point to "/READDB/data" 
systemctl restart postgresql
```

> Run `pg_lsclusters` to check that it started correctly. main cluster should have Status "online,recovery".
> I had an error "data directory "/READDB/data" has invalid permissions",
> solved by: `chmod 750 -R /READDB/data` and then restarting the postgres again: `systemctl restart postgresql`. 

```
reboot # never hurts
```

> *ssh to the server*

Run `pg_lsclusters` to check that it started after reboot.
``` shell
cd /radixdlt

sudo -u postgres psql -p 5433
```
Set the password for postgres user (replace `p_myPassword` with your password).
``` sql
CREATE DATABASE radix_ledger;
GRANT CONNECT ON DATABASE radix_ledger TO postgres;
ALTER USER postgres PASSWORD 'p_myPassword';
exit
```
```
nano /etc/postgresql/12/main/pg_hba.conf
```
Append: `host    all             postgres        samehost                md5`.
Then do the same for `/etc/postgresql/12/writer/pg_hba.conf`

```
systemctl restart postgresql
```
Run `pg_lsclusters` to check that it started correctly.

> Tune memory on both main and replica Postgres instances: https://pgtune.leopard.in.ua/#/ 
> (DB Type=oltp, use 1/3 of server's RAM, 16-32 Gb should be more than enough; CPUs - half of server's threads)
> just copy settings and  append to the bottom the conf files (`/etc/postgresql/12/writer/postgresql.conf` and `/etc/postgresql/12/main/postgresql.conf`).
> Stop postgres (`pg_ctlcluster 12 main stop` and `pg_ctlcluster 12 writer stop`), then update the above files, then bring up writer first, then bring up main.

Increase archive storage on the writer cluster. This will allow replica to resync even after prolonged downtime but will consume some disk space (around 10-15Gb). Use smaller value if this is a concern. Add to the conf file:
```
wal_level = archive
wal_keep_segments = 1024
```

#### 5. Configuring Radix services
This section is a short essence of the [official guide](https://docs.radixdlt.com/main/node-and-gateway/cli-install-node-docker.html),
please refer to it in case you have any questions.

```
cd /radixdlt
radixnode docker setup -n fullnode -t radix://rn1qthu8yn06k75dnwpkysyl8smtwn0v4xy29auzjlcrw7vgduxvnwnst6derj@54.216.99.177
```
Configure the node password, as the data directory for the ledger put: `/RADIXDB`  
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

Upload all 4 files from this Guide to `/radixdlt`:
```shell
GH_URL="https://raw.githubusercontent.com/Radix-Live/Guides/main/GatewayAPI-Full/files"
wget -O .env $GH_URL/.env
wget -O data-aggregator-fixed-configuration.json $GH_URL/data-aggregator-fixed-configuration.json
wget -O gateway-api-fixed-configuration.json $GH_URL/gateway-api-fixed-configuration.json
wget -O radix-fullnode-compose.yml $GH_URL/radix-fullnode-compose.yml
```

Edit the `.env` file and set your passwords for `RADIXDLT_NODE_KEY_PASSWORD` and `POSTGRES_SUPERUSER_PASSWORD`.

#### 6. Starting everything
```
radixnode docker start -f radix-fullnode-compose.yml -t radix://rn1qthu8yn06k75dnwpkysyl8smtwn0v4xy29auzjlcrw7vgduxvnwnst6derj@54.216.99.177
docker ps -a
```

That's it!
The Node should start syncing, Aggregator aggregating, Gateway node responds with "NotSyncedUpError".
Sync takes around 12-24 hours, Aggregating up to 36-48 hrs, meanwhile try to `reboot` and see if all containers start properly afterward.

To check the node sync progress you can run `radixnode api core network-status | grep version` 
several times - the version should increase between invocations.

Also, you can check both Node Sync and Data Aggregation progress with:
```
sudo -u postgres psql -d radix_ledger -c $'select * from ledger_status;'
```

#### 7. Optional

##### SSL certificates
If you need SSL certs for Core or System API (port 443 served by nginx) - upload them to `/radixdlt` and add to the nginx service:
```
volumes:
  - ./server.key:/etc/nginx/secrets/server.key
  - ./server.pem:/etc/nginx/secrets/server.pem
```
