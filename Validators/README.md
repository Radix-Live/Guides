### I. Validator switching procedure (Dockerized setup, using *babylonnode*) 
Tested on Ubuntu 22.04 (which is the recommended version per official docs).  
`stop-validator.sh` is based on FPieper's script for systemd setup.  

##### Prerequisites 
0. The Validator / Full Node running as a Docker container, installed with BabylonNode CLI (https://docs.radixdlt.com/main/node-and-gateway/cli-install.html)
1. Install the tools required to run the scripts on the servers: `apt install -y expect jq`.
2. Copy [scripts](scripts) to your user's home directory (where you have `docker-compose.yml`)
3. `chmod u+x *.sh`
4. Each server needs to have two keystores in `/root/babylon-node-config/` directory:
    - keystore of your validator  e.g. `node-keystore.validator.ks`
    - any non-validator keystore, e.g. `node-keystore.blank.ks`

   The keystores need to use the same password.  
   These keystore names are used in the `stop-validator.sh`, so if you choose different names - make sure to update it.
5. Make sure that you have `$NGINX_ADMIN_PASSWORD` and `$NGINX_SUPERADMIN_PASSWORD` set (as per official doc).


##### Switchover sequence

0. ssh to both servers.
1. Backup Node - if you have changed any container versions in the `docker-compose.yml` - make sure to pull them beforehand:
    ```
    docker compose -f /root/docker-compose.yml pull
    ```
2. Backup Node - switch to using Validator keystore (you can also just copy, but I choose to move, so I know which KS is used atm)
    ```shell
    mv -f /root/babylon-node-config/node-keystore.ks /root/node-config/babylon-node-keystore.blank.ks 
    mv -f /root/babylon-node-config/node-keystore.validator.ks /root/babylon-node-config/node-keystore.ks 
    ```
3. Validator Node - run `./stop-validator.sh` and wait until it finishes<sup>*</sup>.
4. Backup Node - run `./start.sh`


<sup>*</sup> The `stop-validator.sh` script switches the node to using the non-validator KS, but doesn't start the node itself. You can do it manually, or just adapt the script to your needs.


### II. Validator upgrade procedure (Dockerized setup, using *babylonnode*)

##### Prerequisites
Check the "Prerequisites" section above 👆

##### Upgrade sequence
0. ssh to the Validator's server.
1. Update `docker-compose.yml` - put updated container versions and make sure to apply other required changes (like `JAVA_OPTS: --enable-preview`).
2. Run `./upgrade.sh`.

### III. Restoring the Validator node database from a snapshot
See [Snapshots](Snapshots).
