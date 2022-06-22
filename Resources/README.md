### Resources
Just a list of publicly available resources that can help with developing on Radix.

1. [Java client for the Gateway API](https://github.com/Radix-Live/radix-java-common) - you can generate one yourself,
but it's more convenient to have it in Maven Central.
2. [radixdlt-java-common](https://github.com/Radix-Live/radix-java-common) - ripped off from the main Radix repo,
has all cryptography utils needed to sign transactions.
3. Examples of using the above - TBD.
4. A fork of [radixdlt-network-gateway](https://github.com/Radix-Live/radixdlt-network-gateway) with 2 additional endpoints that allow getting transactions for up to 100 different addresses at once.
See the spec on [ReDoc](https://redocly.github.io/redoc/?url=https://raw.githubusercontent.com/Radix-Live/radixdlt-network-gateway/main/gateway-api-spec.yaml&nocors#tag/Batch-Transactions/paths/~1custom~1transactions-batch~1since-account-transactions/post).
5. Publicly available Radix Gateway API cluster at [api.radix.live](https://api.radix.live) that you can use for free.
6. Radix Gateway API DB at [db.radix.live](https://db.radix.live/) that you can connect to, to run ad-hoc queries or reports, etc.
7. Daily snapshots of Radix Node database and Gateway API database at [snapshots.radix.live](https://snapshots.radix.live/).
See the [Guide](https://github.com/Radix-Live/Guides/tree/main/LedgerSnapshots).




