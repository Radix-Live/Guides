# Guides

### Integrating with Radix Network
1. [Introduction](Integration)

### Gateway API Setup
1. [Fully Dockerized Setup](GatewayAPI)
2. [Using snapshots to speed up sync](LedgerSnapshots) (both Node and Gateway API)

### Validators
1. [Validator switching procedure](Validators) (Dockerized setup, using *radixnode*)
2. [Restoring the Validator node database from a snapshot](Validators/Snapshots)

# Resources
Just a list of stuff we provide that can help with developing on Radix.

1. [Java client for the Gateway API](https://github.com/Radix-Live/radix-java-common) - you can generate one yourself,
but it's more convenient to have it in Maven Central.
2. ~~[radixdlt-java-common](https://github.com/Radix-Live/radix-java-common) - ripped off from the main Radix repo,
has all cryptography utils needed to sign transactions.~~
3. Examples of using the above - TBD.
4. ~~A fork of [radixdlt-network-gateway](https://github.com/Radix-Live/radixdlt-network-gateway) with 2 additional endpoints that allow getting transactions for up to 100 different addresses at once.
See the spec on [ReDoc](https://redocly.github.io/redoc/?url=https://raw.githubusercontent.com/Radix-Live/radixdlt-network-gateway/main/gateway-api-spec.yaml&nocors#tag/Batch-Transactions/paths/~1custom~1transactions-batch~1since-account-transactions/post).~~
5. Publicly available Radix Gateway API cluster at [gateway.radix.live](https://gateway.radix.live) that you can use for free.
6. Radix Gateway API DB at [db.radix.live](https://db.radix.live/) that you can connect to, to run ad-hoc queries or reports, etc.
7. Daily snapshots of Radix Node database and Gateway API database at [snapshots.radix.live](https://snapshots.radix.live/).
See the [Guide](https://github.com/Radix-Live/Guides/tree/main/LedgerSnapshots).
8. Mainnet:
    - Gateway API: [gateway.radix.live](https://gateway.radix.live)
    - Core API: [core.radix.live/core](https://core.radix.live/core)
    - Gateway DB (`postgresql://radix:radix@db.radix.live/radix_ledger`):
        - Host: db.radix.live
        - Port: default (5432)
        - User: radix
        - Password: radix
        - Database: radix_ledger
9. Stokenet:
    - Gateway API: [stokenet-gateway.radix.live](https://stokenet-gateway.radix.live)
    - Core API: [stokenet-core.radix.live/core](https://stokenet-core.radix.live/core)
    - Gateway DB (`postgresql://radix:radix@stokenet-db.radix.live/radix_ledger`):
      - Host: stokenet-db.radix.live
      - Port: default (5432)
      - User: radix
      - Password: radix
      - Database: radix_ledger
10. Olympia:
    - Gateway API: [olympia-gateway.radix.live](https://olympia-gateway.radix.live) [[API docs](https://redocly.github.io/redoc/?url=https://raw.githubusercontent.com/radixdlt/radixdlt-network-gateway/main/gateway-api-spec.yaml)]
    - Core API: [olympia-core.radix.live](https://olympia-core.radix.live) [[API docs](https://redocly.github.io/redoc/?url=https://raw.githubusercontent.com/radixdlt/radixdlt/main/radixdlt-core/radixdlt/src/main/java/com/radixdlt/api/core/api.yaml)]
    - Gateway DB (`postgresql://radix:radix@olympia-db.radix.live/radix_ledger`): 
      - Host: olympia-db.radix.live
      - Port: default (5432)
      - User: radix
      - Password: radix
      - Database: radix_ledger

