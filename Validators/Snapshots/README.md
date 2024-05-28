### Restoring from a snapshot for Validators
::warning:: The below is out of date, please refer to [Ledger Snapshots](https://github.com/Radix-Live/Guides/tree/main/LedgerSnapshots) guide!



<details>
  <summary>Olympia stuff</summary>


##### 1. Prepare
```shell
sudo apt update
sudo apt install zstd
```

##### 2. Stop the node
```shell
# if you are running via Docker
radixnode docker stop -f radix-fullnode-compose.yml

# if you are running via systemd
sudo systemctl stop radixdlt-node
```

##### 3. Download the latest snapshot


<details> 
  <summary>3a. Fast Download from multiple sources <b>(recommended)</b></summary>

Run [this script](https://snapshots.radix.live/latest-validator.sh) to download the snapshot from up to 3 available mirrors.  
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

</details>

<details>
  <summary>3b. In case the above link doesn't open</summary>

Here is an example script, but you would need to put the current date in UTC,
and manually check whether the files actually exist (e.g. `wget <file url>`).

```shell
#!/bin/bash

sudo apt install -y aria2

FILE=2023-08-15/RADIXDB-no-api.tar.zst

aria2c -x3 -s16 -k4M --piece-length=4M --disk-cache=256M --lowest-speed-limit=500k \
       ftp://snapshots.radix.live/$FILE \
       ftp://u306644-sub1:S4yNVUFpRfWABrgP@u306644.your-storagebox.de/$FILE \
       https://radix-snapshots.b-cdn.net/$FILE

```
</details>

<details> 
  <summary>3c. From CDN (legacy)</summary>

1. Browse the [Latest Snapshots on CDN](https://snapshots.radix.live/Validators-Latest/).  
    Usually the latest backup would have the today's date (they are uploaded daily at ~00:15 UTC).  
2. Set the date to a variable, for example:
    ```shell
    DIR=2023-08-15
    ```
3. Download with curl or wget:
    ```shell
    curl -O https://radix-snapshots.b-cdn.net/$DIR/RADIXDB-no-api.tar.zst
    ```
This should give you the fastest download speed. For some weird reason, in some locations this is very, very slow.  
If you see that the download speed is less than 25MB/sec - try cancelling the download and using option `b`.

</details>

<details> 
  <summary>3d. From a server in Germany (legacy)</summary>

1. Set connection details to a variable
    ```shell
    SSH_HOST=u306644-sub1@u306644.your-storagebox.de
    ```
2. Get the latest available backup and write it into a variable
    ```shell
    DIR=$(echo "ls -1 ????-??-??" | sftp $SSH_HOST | grep -v "sftp> " | sed 's/.$//' | tail -n 1)
    ```
   You might need to confirm adding the server to known hosts.  
   When prompted for password, enter: `S4yNVUFpRfWABrgP`.  
3. Make sure that it was set properly: `echo $DIR`.
4. Download the snapshot
    ```shell
    scp -P 23 $SSH_HOST:$DIR/RADIXDB-no-api.tar.zst ./
    ```
   You might need to confirm adding to known hosts again and enter the same password one more time.

</details>


##### 4. Unpack
Here `/RADIXDB` is the directory where Node's ledger DB resides. Change it if needed.
```shell
LEDGER_DIR=/RADIXDB
rm -rf $LEDGER_DIR/*
tar --use-compress-program=zstdmt -xvf RADIXDB-no-api.tar.zst --exclude=./address_book -C $LEDGER_DIR/
```
Update permissions
```shell
# if you are running via Docker
sudo chown -R systemd-coredump:systemd-coredump $LEDGER_DIR

# if you are running via systemd
sudo chown -R radixdlt:radixdlt $LEDGER_DIR
```

##### 5. Start the node
```shell
# if you are running via Docker
radixnode docker start -f radix-fullnode-compose.yml -t radix://rn1qthu8yn06k75dnwpkysyl8smtwn0v4xy29auzjlcrw7vgduxvnwnst6derj@54.216.99.177

# if you are running via systemd
sudo systemctl start radixdlt-node
```

#### Troubleshooting
It didn't work? Make sure that:
1. You have changed the directory's owner (step 4).
2. The validator is running with `RADIXDLT_TRANSACTIONS_API_ENABLE=false`
```shell
# Docker
docker logs -t radixdlt_core_1 2>&1 | head -n 200 | grep "TRANSACTIONS_API_ENABLE"

# systemd
cat /etc/radixdlt/node/default.config | grep "api.transactions.enable"
```

</details>
