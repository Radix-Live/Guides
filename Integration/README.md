## Integrating with Radix network

There are two ways to integrate with the network for sending transactions:
1. Run a Radix Node software on your private Server and use its private key and account (wallet address).
   Interaction with the node can be performed via [Core API and System API](https://docs.radixdlt.com/main/apis/node-apis-introduction.html) endpoints it exposes, or ad-hoc via the command-line interface ([Radix CLI](https://github.com/radixdlt/node-runner)).  
   This limits you to having **only one account**  but saves you from the trouble of implementing cryptography/private key management on the Client.
2. Manage the private keys on the side of the Client and interact via the [Gateway API](https://docs.radixdlt.com/main/apis/gateway-api.html). It provides OpenAPI specifications and closely resembles Rosetta API standards, more details on this in [Radix API Specifications](https://docs.radixdlt.com/main/apis/api-specification.html).
   This allows you to manage **multiple accounts** but requires implementing private key management and transaction signing logic (some examples on this are below).

No matter which API you choose to use, you have an option to generate the client code for the most popular programming languages using [OpenAPI Generators](https://openapi-generator.tech/).
Example command line for Java (API Gateway Client):
```
java -jar openapi-generator-cli.jar generate -g java -i gateway-api-spec.yaml -p "dateLibrary=java8,library=apache-httpclient,apiPackage=radix.api.gateway.client,modelPackage=radix.api.gateway.model,invokerPackage=radix.api.gateway,groupId=radix.api.gateway,artifactId=radix-api-gateway-client,artifactDescription=Radix API Gateway Client,booleanGetterPrefix=is,developerEmail=hello@radixdlt.com,developerName=Radix,developerOrganization=Radix,developerOrganizationUrl=https://radixdlt.com,disallowAdditionalPropertiesIfNotPresent=false,snapshotVersion=false"
```


## Official documentation
You can find details on the available API as subsections of the [API Introduction](https://docs.radixdlt.com/main/apis/introduction.html).
The raw OpenAPI Spec `yaml` files, ReDocly and Postman collections with examples are linked from the [API Spec page](https://docs.radixdlt.com/main/apis/api-specification.html).    
For details about performing requests via the Gateway API, including sending transactions, see the [Gateway API User Guide](https://docs.radixdlt.com/main/apis/making-api-calls.html).

## Running a Radix Node

The simplest option is to run a [Fully Dockerized setup](../GatewayAPI-Dockerized).   
Here is also a guide that includes installing a dedicated Postgres DB with a read-only replica: [link](../GatewayAPI-Full).


## Common use cases
All requests in the examples are made against Radix-run `https://mainnet-gateway.radixdlt.com` (Postman collection uses the old url `https://mainnet.radixdlt.com` that needs to be updated).  
While it is suitable for ad-hoc requests and testing the integration, it is strongly advised to run your own Gateway API.  
Alternatively, you can use any of the [publicly available APIs](https://www.radixscan.io/CommunityGateways.shtml) (rate limits may apply, please check the site of the API you intend to use).

#### 1. Obtaining the latest state version
[ReDocly](https://redocly.github.io/redoc/?url=https://raw.githubusercontent.com/radixdlt/radixdlt-network-gateway/1.1.4/gateway-api-spec.yaml&nocors#tag/Status/paths/~1gateway/post)
| [Postman](https://documenter.getpostman.com/view/14449947/UVXnHaJf#26c0a889-75c4-4a36-9cd3-2d79aa537d99)  
In the response, `gateway.ledger_state.version` is the latest version of the Network State in the node's aggregated data, while `gateway.target_ledger_state.version` is the latest version observed on the Network by the Core API node.

In the response from a properly functioning node they should:
1) match (this means that the Core API node's aggregated data is in sync with the corresponding Radix Full Node).
2) increase at least every couple of seconds (this means that the Radix Full Node is properly synced with the Radix Network).

#### 2. Getting the account balances
[Redocly](https://redocly.github.io/redoc/?url=https://raw.githubusercontent.com/radixdlt/radixdlt-network-gateway/1.1.4/gateway-api-spec.yaml&nocors#tag/Account/paths/~1account~1balances/post)
| [Postman](https://documenter.getpostman.com/view/14449947/UVXnHaJf#2a0fe47c-79af-4c24-9651-33f1e45ebab9)  
Note that all balances in Radix APIs are in `attos`. 1 XRD (or any other asset) is equal to `1 x 10^18` attos, or `1,000,000,000,000,000,000`.

#### 3. Validating account address
Radix account addresses can be validated with RegExp: `^rdx1[02-9AC-HJ-NP-Zac-hj-np-z]{54}[cgqsCGQS]{1}[02-9AC-HJ-NP-Zac-hj-np-z]{6}$`
("rdx1" prefix followed by 61 letters and numbers, excluding `[1, b, i, o]`, 7<sup>th</sup> symbol from right should be one of `[c, g, q, s]`).

#### 4. Getting account transactions
[Redocly](https://redocly.github.io/redoc/?url=https://raw.githubusercontent.com/radixdlt/radixdlt-network-gateway/1.1.4/gateway-api-spec.yaml&nocors#tag/Account/paths/~1account~1transactions/post)
| [Postman](https://documenter.getpostman.com/view/14449947/UVXnHaJf#c6c7cd44-f093-4298-949c-4f757437e864)  
Transactions here are ordered by date (the newest first) and contain full info (no need to request additional details on each transaction specifically).
There are different types of actions a transaction can contain (see data classes of the OpenAPI spec), the most common is `TransferTokens` actions.
A transaction can optionally contain an encoded message (`.metadata.message`), which can be either `encrypted` with the sender's/receiver's public keys (private) or `plaintext` (public) visible to everyone.
Public messages can follow one of the two encoding formats:
- proper encoding - the message is Hex-encoded with two leading bytes prepended to signify schema+version
- legacy - properly encoded as above, plus additionally encoded one more time

Here is an example of how to decode messages in [Java](https://gist.github.com/Mleekko/ba44531b7af7a8af6c3a7b0de27fcf52) and [Python](https://gist.github.com/dhedey/02d23e1ff480e355d68713e201c35f50).
Encrypting/decrypting private messages is outside the scope of this doc.

#### 5. Getting transaction details
[Redocly](https://redocly.github.io/redoc/?url=https://raw.githubusercontent.com/radixdlt/radixdlt-network-gateway/1.1.4/gateway-api-spec.yaml&nocors#tag/Transaction/paths/~1transaction~1status/post)
| [Postman](https://documenter.getpostman.com/view/14449947/UVXnHaJf#645f0327-53b6-439b-bb6f-6bf3fcdb4fcc)  
Note that Radix doesn't have a concept of "network confirmations" - once Validators have voted on the transaction, its status becomes "CONFIRMED" which means that the transaction is final and cannot be reverted.

#### 6. Sending a transaction
Sending the transaction on Radix consists of three steps: Building the TX, Finalizing the TX, and Submitting it to the Network.
##### 6.1. via the Core API
An example of how to send a transaction (in Java) can be found in the [Postman Collection](https://documenter.getpostman.com/view/14449947/UVXnHaJh#fa1c4ac9-345c-4151-adc8-e90153a59a2b) or [ReDocly](https://redocly.github.io/redoc/?url=https://raw.githubusercontent.com/radixdlt/radixdlt/1.2.2/radixdlt-core/radixdlt/src/main/java/com/radixdlt/api/core/api.yaml&nocors#tag/track_xrd_example).

##### 6.2. via the Gateway API
The steps performed will be similar to the example with Core API above, except you would need to sign the TX with your own private keys instead of performing a request to sign it with your Node's keys.  
Here are the endpoints in Gateway API that should be used:
[Redocly](https://redocly.github.io/redoc/?url=https://raw.githubusercontent.com/radixdlt/radixdlt-network-gateway/1.1.4/gateway-api-spec.yaml&nocors#tag/Transaction/paths/~1transaction~1build/post)
| [Postman](https://documenter.getpostman.com/view/14449947/UVXnHaJf#efd465b2-939e-4760-860d-969d45c599a0).

#### 7. Signing the transaction
##### 7.1. via the Core API
Signing is performed via a special endpoint in your Node (see #6.1)

##### 7.2. via the Gateway API
1. Here is an example in Python: https://radixtalk.com/t/how-do-i-locally-sign-a-transaction-with-a-private-key/157
2. NodeJs (using https://www.npmjs.com/package/secp256k1):
```
const s_bytes = utilities.convertToArray(hashOfBlobToSign);
    const privkey_bytes = utilities.convertToArray(privkey);
    const sigObj = secp256k1.ecdsaSign(s_bytes, privkey_bytes)
    const der = utilities.buf2hex(secp256k1.signatureExport(sigObj.signature));

    const response = await api.post('/transaction/finalize', {
        "network_identifier": {
            "network": "mainnet"
        },
        "unsigned_transaction": blob,
        "signature": {
            "bytes": der,
            "public_key": {
                "hex": pubkey
            }
        },
        "submit": true
    });
```
3. Java (requires [radixdlt-java-common](https://github.com/Radix-Live/radix-java-common) library:  https://gist.github.com/Mleekko/92889469ca723a5b3d581ceec66bef1a

#### 8. Getting the native token (XRD) resource identifier
See `/token/native` in the Gateway API:
[Redocly](https://redocly.github.io/redoc/?url=https://raw.githubusercontent.com/radixdlt/radixdlt-network-gateway/1.1.4/gateway-api-spec.yaml&nocors#tag/Token/paths/~1token~1native/post)
| [Postman](https://documenter.getpostman.com/view/14449947/UVXnHaJf#c9f6520b-34c7-48d7-965b-51e1d07e1cdc)

#### 9. Integration Details
At the moment, the APIs used to submit transactions to the Radix Public Network do not support simultaneous spends from the same account address.   
It means that if someone tries to submit two outgoing transactions from the same account within a short timespan - one of them has a high chance of failing.
To avoid this, API clients should prevent the possibility of sending more than one transaction at a time from a single account (e.g. enqueue all transactions per account and poll transactions to send from that queue).


All transactions should be checked for their execution result (success or failure) and retried if needed (for example, after submitting the TX, poll its status with at least 1-second delay, and process it status is any other than `PENDING`).