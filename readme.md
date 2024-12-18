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

## Proposal and Voting

A governance proposal can be created by executing the tx `privgovd tx gov submit-proposal [path-to-proposal-file]`. A sample proposal file can be found in `draft_proposal.json`. Once the proposal is created, query the proposal to get the unique identity and pubkey for the proposal.

You can then use the `encrypt-vote` functionality to generate your encrypted vote. To submit the encrypted vote, simply mke the tx `privgovd tx gov vote-encrypted [proposal-id] [encrypted data]`. Once the vote is submitted, wait for the voting period to be over and the votes to be tallied.
