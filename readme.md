# privgov

**privgov** is a blockchain built using Cosmos SDK and Tendermint and created with [Ignite CLI](https://ignite.com/cli). It is a basic working cosmos chain that uses the Fairblock/cosmos-sdk to enable private governance.

## Integration

To use the Fairblock/cosmos-sdk in your project simply add the following in the `replace` clause of your `go.mod` file:

```go
replace (
    cosmossdk.io/api => github.com/FairBlock/cosmossdk-api v0.7.5

    github.com/99designs/keyring => github.com/cosmos/keyring v1.2.0
    // use cosmos fork of keyring
    github.com/CosmWasm/wasmd => github.com/FairBlock/wasmd v0.50.6-fairyring
    github.com/Fairblock/fairyring => github.com/FairBlock/fairyring v0.10.2

    github.com/cosmos/cosmos-sdk => github.com/Fairblock/cosmos-sdk v0.50.8-fairyring-2
    // dgrijalva/jwt-go is deprecated and doesn't receive security updates.
    github.com/dgrijalva/jwt-go => github.com/golang-jwt/jwt/v4 v4.4.2
    // Fix upstream GHSA-h395-qcrw-5vmq and GHSA-3vp4-m3rf-835h vulnerabilities.
    github.com/gin-gonic/gin => github.com/gin-gonic/gin v1.9.1
    github.com/gogo/protobuf => github.com/regen-network/protobuf v1.3.3-alpha.regen.1
)
```

Finally, the custom `gov` module has to be registered with the IBC router. To do that, simply add the route in the `app/ibc.go` file:

```go
    // Add gov module to IBC Router
    govIBCModule := ibcfee.NewIBCMiddleware(gov.NewIBCModule(app.GovKeeper), app.IBCFeeKeeper)
    ibcRouter.AddRoute(govtypes.ModuleName, govIBCModule)

    app.IBCKeeper.SetRouter(ibcRouter)
```

**NOTE:** The route must be added to the `ibcrouter` before calling the `SetRouter()` function

## Setting up the test environment

To setup the testing environment, simply run the `priv_gov_setup.sh` file and follow along with the prompts. The script does the following things:

1. Sets up and starts the fairying chain (with all its bells and whistles)
2. Sets up and starts the privgov chain
3. Creates a IBC channel between the fairyring chain and privgov chain and starts the Hermes relayer

> It is recommended to use a short time frame for quick iterative tests, such as 2min or so.

## ℹ️ For MacOS Systems

If you are operating on a MacOS system, you may need to carry out the following installations to ensure that this tutorial works with your machine:

1. Make sure to install `ignite`, `hermes`, and `rust` onto your machine. Download link and instructions for each are listed below (these assume you have `homebrew` installed):
    - [`ignite`](https://docs.ignite.com/welcome/install) 
    - [`hermes`](https://hermes.informal.systems/quick-start/installation.html#install-by-downloading)
    - [`rust`](https://www.rust-lang.org/tools/install)
2. bash version: this tutorial requires an updated bash version compared to the default MacOS 3.x version. If it’s less than 4.x then the script will exit.
It is up to you to install a higher version in a way that works for you. For example, one of our devs have simply had an updated version of bash installed elsewhere, and used that to run it. For them, they then had to use the updated bash version as per its specific file location:

```bash
/opt/homebrew/bin/bash ./priv_gov_setup.sh
```

instead of just running 

```bash
./priv_gov_setup.sh
```

3. Use `go` version 1.22.10. If you need to have multiple versions of `go` installed on your local machine, check out this [link](https://go.dev/doc/manage-install#installing-multiple) from the `go` docs.

```bash
/opt/homebrew/bin/bash ./priv_gov_setup.sh go1.22.10
```

## Proposal and Voting

A governance proposal can be created by executing the tx `privgovd tx gov submit-proposal [path-to-proposal-file] --from [user] --chain-id privgov`. A sample proposal file can be found in `draft_proposal.json`. 

> ℹ️ When specifying the from user, or users in general throughout this tutorial, do not use `bob`. This user has some problematic aspects that can cause the tutorial to not run, and has been seen in other cosmos sdk chain tests.

```bash
privgovd tx gov submit-proposal draft_proposal.json --from fred --chain-id privgov
```

Once the proposal is created, query the proposal to assess its details. You can now get the unique identity and pubkey for the proposal.

```bash
privgovd q gov proposals
```

<!-- TODO: HASH GET A SCREENSHOT OF WHAT THE OUTPUT COULD LOOK LIKE -->

You can then use the `encrypt-vote` functionality to encrypt your vote. Simply use the bash command to submit the tx:

```bash
fairyringd encrypt-vote yes <identity> <random salt> <pubkey>
```

An example of the command you would use should look like this, but with different identities, salts, and pubkeys.

```bash
fairyringd encrypt-vote yes 1/rq 1234 b5b8a299700e44ae0b0ffb54903a253555f60babdf0d3ceddac4253840a92ac9511d8a236efe2db2d518e9dbb50ea973
```

<!-- TODO: Write up a brief blurb on submitting the encrypted vote -->


```bash
privgovd tx gov vote-encrypted [proposal-id] [encrypted data]
```

An example of the command you would use should look like this, but with different proposal-ids, and encrypted data.

```bash
privgovd tx gov vote-encrypted 1 6167652d656e6372797074696f6e2e6f72672f76310a2d3e20646973744942450a6939617a7438786859522f464758624a6d3853506d5a5867447250756d4a416e4e3531773573694b2b316866554b6d655139463562454e79363962696755414e0a62583137734c4a71444643394b5035766a5245363267495a5252444531744d77384c384f6b524e33636267344d442b3547666553765a6d3058692b4c2b6165410a784c4e74642b47303439725554623449684d717144770a2d2d2d2053324f6e484236794463387a4c44796f4c684142375079736e6a66786a4f634a41304e5446577a4b694b550aba5083c1b3ac61036b29e97e67cbf04a10d799fdf1a54e649ea15b7e2c6aa52c2f1feaedad --from alice
 --chain-id privgov
```

Once the vote is submitted, wait for the voting period to be over and the votes to be tallied.
