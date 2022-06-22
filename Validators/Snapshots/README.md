### Restoring from a snapshot for Validators
This is an excerpt of the [Ledger Snapshots](https://github.com/Radix-Live/Guides/tree/main/LedgerSnapshots) guide
that briefly describes the commands you need to execute to restore the database of the Validator Node.  
Please refer to the original guide for detailed explanations.

##### 1. Prepare
```shell
apt install zstd
```
```shell
SSH_USER=u306644-sub1
SSH_HOST=u306644.your-storagebox.de
```

##### 2. Stop the node
```shell
# if you are running via Docker
radixnode docker stop -f radix-fullnode-compose.yml

# if you are running via systemd
sudo systemctl stop radixdlt-node
```

##### 3. Pick the latest snapshot
```shell
DIR=$(echo "ls -1 ????-??-??" | sftp $SSH_USER@$SSH_HOST | grep -v "sftp> " | sed 's/.$//' | tail -n 1)
```
You might need to confirm adding the server to known hosts.  
When prompted for password, enter: `S4yNVUFpRfWABrgP`.  

```shell
echo $DIR
```
##### 4. Download the snapshot
```shell
scp -P 23 $SSH_USER@$SSH_HOST:$DIR/RADIXDB-no-api.tar.zst ./
```
You might need to confirm adding to known hosts again and enter the same password one more time.

##### 5. Unpack
Here `/RADIXDB` is the directory where Node's ledger DB resides. Change it if needed.
```shell
rm -rf /RADIXDB/*
tar --use-compress-program=zstdmt -xvf RADIXDB-no-api.tar.zst -C /RADIXDB/
```

##### 6. Start the node
```shell
# if you are running via Docker
radixnode docker start -f radix-fullnode-compose.yml -t radix://rn1qthu8yn06k75dnwpkysyl8smtwn0v4xy29auzjlcrw7vgduxvnwnst6derj@54.216.99.177

# if you are running via systemd
sudo systemctl start radixdlt-node
```

