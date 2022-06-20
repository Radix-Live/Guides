## Ledger Snapshots

### Introduction
After the initial Node installation, there is quite a long period (atm around 18-30 hours)
when it fetches the ledger state from the network and is not operational.  
To avoid a long wait, you can restore the state from one of the recent snapshots.  
You can browse the snapshots [here](https://snapshots.radix.live) but because of the file size it is better to download 
them via SSH (non-interactive, at port `23`) or FTP from `u306644.your-storagebox.de` (user: `u306644-sub1`, password: `S4yNVUFpRfWABrgP`).

The snapshot directory for each day contains 3 files:
1. `RADIXDB-api.tar.zst` - Ledger state used by the Radix Node software.  
The `api` suffix means that it contains all the necessary data for querying raw transactions
(i.e. the node running with flag `RADIXDLT_TRANSACTIONS_API_ENABLE=true`)
2. `RADIXDB-no-api.tar.zst` - The same ledger state but lacking the raw transactions data.
3. `radix_ledger.tar.zst` - The dump of the Postgres DB with aggregated ledger 
data used by the Gateway API.


### Restoring from a snapshot
##### 0. Set up the shell
Set the connection details to a variables - we will need them later.
```shell
SSH_USER=u306644-sub1
SSH_HOST=u306644.your-storagebox.de
```
When you connect to the above host, use password `S4yNVUFpRfWABrgP` to authenticate.
Run `apt install zstd` to install the utility required to uncompress the archives.

##### 1. Stop the services:
```shell
radixnode docker stop -f radix-fullnode-compose.yml
```
##### 2. Pick the snapshot
Browse [snapshots.radix.live](https://snapshots.radix.live) and pick one with a recent date.  
You can also execute the below command:
```shell
echo "ls -1" | sftp $SSH_USER@$SSH_HOST
```

##### 3. Set that date to a variable, e.g.:
```shell
DIR=2022-06-15
```

##### 4. Download the snapshot(s) you need:
```shell
scp -P 23 $SSH_USER@$SSH_HOST:$DIR/RADIXDB-api.tar.zst ./
# or
scp -P 23 $SSH_USER@$SSH_HOST:$DIR/RADIXDB-no-api.tar.zst ./

scp -P 23 $SSH_USER@$SSH_HOST:$DIR/radix_ledger.tar.zst ./
```

##### 5. Extract the contents of the tarballs into the target locations:
- a) Radix Ledger (change to `RADIXDB-no-api` if you do not need the raw historical transactions data).
    ```shell
    rm -rf /RADIXDB/*
    tar --use-compress-program=zstdmt -xvf RADIXDB-api.tar.zst -C /RADIXDB/
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

##### 6. Start the services:
```shell
# if you are running a standalone Postgres - start it first
pg_ctlcluster 12 writer start
pg_ctlcluster 12 main start

radixnode docker start -f radix-fullnode-compose.yml -t radix://rn1qthu8yn06k75dnwpkysyl8smtwn0v4xy29auzjlcrw7vgduxvnwnst6derj@54.216.99.177
```
