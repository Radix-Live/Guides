## Ledger Snapshots

### Introduction
After the initial Node installation, there is quite a long period (atm around 18-30 hours)
when it fetches the ledger state from the network and is not operational.  
To avoid a long wait, you can restore the state from one of the recent snapshots.  
You can browse the snapshots [here](https://snapshots.radix.live), but it is better to actually download them from different locations (see below).   

The snapshot directory for each day contains 3 files:
1. `RADIXDB-api.tar.zst` - Ledger state used by the Radix Node software.  
The `api` suffix means that it contains all the necessary data for querying raw transactions
(i.e. for nodes running with flag `RADIXDLT_TRANSACTIONS_API_ENABLE=true`), necessary to run the Gateway API.
2. `RADIXDB-no-api.tar.zst` - The same ledger state but lacking the raw transactions' data (e.g. for Validators).
3. `radix_ledger.tar.zst` - The dump of the Postgres DB with aggregated ledger 
data used by the Gateway API.


### Restoring from a snapshot
##### 0. Prepare
```shell
sudo apt update
sudo apt install aria2 zstd
```
We need `aria2` to download the archives, and `zstd` to uncompress them.
##### 1. Stop the services:
```shell
radixnode docker stop -f radix-fullnode-compose.yml
```
##### 2. Download the snapshot
You can find the script to download the latest snapshots here: [Validator](https://snapshots.radix.live/latest-validator.sh)
or [Gateway](https://snapshots.radix.live/latest-gateway.sh)
or [Postgres(broken atm)](https://snapshots.radix.live/latest-postgres.sh).  
It will take up to a minute for the download to reach max speed, and it is OK
if aria2c drops some of the slowest servers at the start.  
You can see the number of active connections under "CN:".  
The progress is saved even if you kill/restart the download.

<details>
  <summary>In case the above link doesn't open</summary>

Here is an example script, but you would need to put the current date in UTC,
and manually check whether the files actually exist (e.g. `wget &lt;file url&gt;`)

```shell
#!/bin/bash

sudo apt install -y aria2

FILE=2023-08-15/RADIXDB-api.tar.zst

aria2c -x3 -s16 -k4M --piece-length=4M --disk-cache=256M --lowest-speed-limit=500k \
       ftp://snapshots.radix.live/$FILE \
       ftp://u306644-sub1:S4yNVUFpRfWABrgP@u306644.your-storagebox.de/$FILE

```
</details>

<details>
  <summary>In case you need an older snapshot</summary>

You can check available files in [StorageBox](https://snapshots.radix.live/Storage-Box/) 
and [Archive](https://snapshots.radix.live/archive/). Then download like this:

```shell
#!/bin/bash

sudo apt install -y aria2

FILE=2023-08-15/RADIXDB-api.tar.zst

aria2c -x2 -s16 -k4M --piece-length=4M --disk-cache=256M --lowest-speed-limit=500k \
       https://snapshots.radix.live/archive/$FILE \
       ftp://u306644-sub1:S4yNVUFpRfWABrgP@u306644.your-storagebox.de/$FILE

```
</details>

##### 3. Extract the contents of the tarballs into the target locations:
- a) Radix Ledger (change to `RADIXDB-no-api` if you do not need the raw historical transactions data).
    ```shell
    rm -rf /RADIXDB/*
    tar --use-compress-program=zstdmt -xvf RADIXDB-api.tar.zst -C /RADIXDB/
    # Ensure proper permissions
    sudo chown -R systemd-coredump:systemd-coredump /RADIXDB
    ```
- b) Postgres - if you are running Postgres in a Docker container ([**GatewayAPI-Dockerized**](../GatewayAPI-Dockerized))
    ```shell
    apt install postgresql-client-12
    rm -rf /WRITEDB/*
    docker-compose -f radix-fullnode-compose.yml up -d radix_db
    tar --use-compress-program=zstdmt -xvf radix_ledger.tar.zst -C ./
    rm -rf radix_ledger.tar.zst
    pg_restore -C -d radix_ledger -v -h 127.0.0.1 -p 50032 -U postgres radix_ledger.dump
    rm -rf radix_ledger.dump
    ```
- c) Postgres - if you are running a standalone Postgres ([**GatewayAPI-Full**](../GatewayAPI-Full))
    ```shell
    # *not tested, so actual steps might differ a bit, but you get the idea
    pg_ctlcluster 12 main stop
    pg_ctlcluster 12 writer stop
    rm -rf /WRITEDB/data/*
    rm -rf /READDB/data/*
    tar --use-compress-program=zstdmt -xvf radix_ledger.tar.zst -C ./
    rm -rf radix_ledger.tar.zst
    pg_restore -C -d radix_ledger -v -h 127.0.0.1 -p 5433 -U postgres radix_ledger.dump
    rm -rf radix_ledger.dump
    ```

##### 4. Start the services:
```shell
# if you are running a standalone Postgres - start it first
pg_ctlcluster 12 writer start
pg_ctlcluster 12 main start

radixnode docker start -f radix-fullnode-compose.yml -t radix://rn1qthu8yn06k75dnwpkysyl8smtwn0v4xy29auzjlcrw7vgduxvnwnst6derj@54.216.99.177
```
