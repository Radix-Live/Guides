### Restoring from a snapshot for Validators
This is an excerpt of the [Ledger Snapshots](https://github.com/Radix-Live/Guides/tree/main/LedgerSnapshots) guide
that briefly describes the commands you need to execute to restore the database of the Validator Node.  
Please refer to the original guide for detailed explanations.

##### 1. Prepare
```shell
apt install zstd
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
  <summary>3a. From CDN  </summary>

1. Browse the [Latest Snapshots on CDN](https://snapshots.radix.live/Validators-Latest/).  
    Usually the latest backup would have the today's date (they are uploaded daily at ~00:15 UTC).  
2. Set the date to a variable, for example:
    ```shell
    DIR=2022-06-15
    ```
3. Download with curl or wget:
    ```shell
    curl -O https://radix-snapshots.b-cdn.net/$DIR/RADIXDB-no-api.tar.zst
    ```
This should give you the fastest download speed. For some weird reason, in some locations this is very, very slow.  
If you see that the download speed is less than 25MB/sec - try cancelling the download and using option `b`.

</details>

<details> 
  <summary>3b. From a server in Germany</summary>

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
tar --use-compress-program=zstdmt -xvf RADIXDB-no-api.tar.zst -C $LEDGER_DIR/
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


