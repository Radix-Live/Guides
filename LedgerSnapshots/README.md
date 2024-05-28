## Ledger Snapshots

### Introduction
After the initial Node installation, there is quite a long period (atm around 36-48 hours)
when it fetches the ledger state from the network and is not operational.  
To avoid a long wait, you can restore the state from one of the recent snapshots.  
You can browse the snapshots [here](https://snapshots.radix.live), but you should not download them via any http links - to download please use the scripts below!   

The snapshot directory for each day contains 2 files:
1. `RADIXDB-INDEX.tar.zst` - Ledger state used by the Radix Node software.  
The `INDEX` suffix means that it contains all the necessary data for querying raw transactions, necessary to run the Gateway API
(i.e. designed for nodes running with default config flags).
2. `RADIXDB-NO-INDEX.tar.zst` - The same ledger state but lacking the raw transactions' data (i.e. for nodes running with flag `RADIXDLT_DB_LOCAL_TRANSACTION_EXECUTION_INDEX_ENABLE=false` and `RADIXDLT_DB_ACCOUNT_CHANGE_INDEX_ENABLE=false`), e.g. for Validators that decided to disable them.


### Restoring from a snapshot
##### 0. Prepare
```shell
sudo apt update
sudo apt install aria2 zstd
```
We need `aria2` to download the archives, and `zstd` to uncompress them.
##### 1. Stop the services:
```shell
babylonnode docker stop
```
##### 2. Download the snapshot
You can find the script to download the latest snapshots here: [NO-INDEX](https://snapshots.radix.live/latest-snapshot-NO-INDEX.sh)
or [with INDEX](https://snapshots.radix.live/latest-snapshot-INDEX.sh) (if in doubt - choose INDEX).  
It will take up to a minute for the download to reach max speed.  
You can see messages like this:
```
09/04 12:57:35 [ERROR] CUID#17 - Download aborted. URI=ftp://snapshots-us.radix.live/2023-09-04/RADIXDB-no-api.tar.zst
Exception: [AbstractCommand.cc:351] errorCode=5 URI=ftp://snapshots-us.radix.live/2023-09-04/RADIXDB-no-api.tar.zst
  -> [DownloadCommand.cc:309] errorCode=5 Too slow Downloading speed: 149208 <= 256000(B/s), host:snapshots-us.radix.live
```
This is not an issue! It means that `aria2c` drops some of the slowest servers, switching to faster ones instead.    
Just continue download as long as you still have 2-3 or more active connections and/or high (50Mb/s+) download speed.  
You can see the number of active connections under "CN:".  
The progress is saved even if you kill/restart the download.

<details>
  <summary>In case the above link doesn't open</summary>

Here is an example script, but you would need to put the current date in UTC,
and manually check whether the files actually exist (e.g. `wget <file url>`)

```shell
#!/bin/bash

sudo apt install -y aria2 zstd

aria2c -x3 -s16 -k4M --piece-length=4M --disk-cache=256M --lowest-speed-limit=250k ftp://snapshots.radix.live/2024-05-28/RADIXDB-INDEX.tar.zst.metalink
```
</details>

<details>
  <summary>In case you need an older snapshot</summary>

You can check available files in [StorageBox](https://snapshots.radix.live/Storage-Box/) 
and [Archive](https://snapshots.radix.live/archive/). Then download like this:

```shell
#!/bin/bash

sudo apt install -y aria2

FILE=2024-05-28/RADIXDB-INDEX.tar.zst

aria2c -x2 -s16 -k4M --piece-length=4M --disk-cache=256M --lowest-speed-limit=500k \
       https://snapshots.radix.live/archive/$FILE \
       ftp://u306644-sub1:S4yNVUFpRfWABrgP@u306644.your-storagebox.de/$FILE

```
</details>

##### 3. Extract the contents of the tarball into the target location:
- Radix Ledger (change to `RADIXDB-NO-INDEX` if you do not need the raw historical transactions data).
    ```shell
    rm -rf /RADIXDB/*
    tar --use-compress-program=zstdmt -xvf RADIXDB-INDEX.tar.zst --exclude=./address_book -C /RADIXDB/
    # Ensure proper permissions
    sudo chown -R systemd-coredump:systemd-coredump /RADIXDB
    ```

##### 4. Start the services:
```shell
babylonnode docker start
```
