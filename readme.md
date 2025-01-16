# Quickstart - Fairblock Module Integration with Cosmos Chains

Welcome to the Fairblock <> Cosmos Integration Tutorial. Please note that the App Quickstart within the [Fairblock docs](https://docs.fairblock.network/docs/welcome/quickstart/cosmos_chain) is the exact same content as this README. They are placed in different locations for convenience to the reader.

> ‼️ All code within this tutorial is purely educational, and it is up to the readers discretion to build their applications following industry standards, practices, and applicable regulations.

Fairblock is a dynamic confidentiality network that delivers high performance, low overhead, and custom confidential execution to blockchain applications. Dynamic confidentiality unlocks the encrypted economy — onchain applications designed for real-world use cases, like optimizable financial markets, competitive PVP markets like auctions, predictions, and gaming, and privacy-preserving inference.

V1 is live on testnet with bespoke MPEC and threshold identity-based encryption (tIBE), which offer conditional confidentiality dependent on users’ needs.

A walk through of this tutorial, alongside context on Fairblock, EVMs, and Comsos Chains is provided in the video below. If you prefer learning by reading on your own, feel free to skip it and continue onward in this README!

[![Fairblock tIBE with EVMs - Orbit Chain Integration Tutorial](https://img.youtube.com/vi/gIzPgSw11uU&ab_channel=FairblockNetwork/0.jpg)](TODO: record and paste new video here)

The core elements of Fairblock are:

1. Fairyring - A dynamic and decentralized network that hosts app-specific secure and performant confidential computing.
2. Fairykit - A module that enables confidential computing for applications within our native ecosystem or across external chains.

The first goal of this tutorial is to showcase the high level options to integrate Fairblock into Cosmos Chains using the respective Fairykit. 

## Cosmos Integration Options

The Cosmos Fairykit integrates using the following one or more of the following methods:

1. Module Integration
2. Smart Contract Integration
3. Co-Processing Integration

The schematic below shows a high-level overview on how Cosmos Chains integrate with Fairblock. A key aspect to note is that all of these integration methods provide the functionality to interact with Fairyring, and there can be underlying application logic working with these integrations.

<!-- TODO: Get schematic -->

## An Intro to `privgov`

Module Integration refers to integrating Fairblock modules, such as `x/pep`, which is used for general encryption functionality.

Smart Contract Integration refers to deploying smart contracts into an environment, WASM, etc., such that it communicates with the Fairyring network for confidential computation.

<!-- TODO: Describe co-processing -->

In today's tutorial, we will be covering the usage of `privgov`, a blockchain built using Cosmos SDK and Tendermint, and a mixture of the `x/pep` module created with [Ignite CLI](https://ignite.com/cli). It is a basic working cosmos chain that uses the Fairblock/cosmos-sdk to enable private governance. 

<!-- TODO: need to fact check the below with apocalypse -->
<!-- This was chosen as the easiest path for other projects to adopt since Cosmos SDK chains have their own initial `gov` module. The core logic is essentially a fork of the `gov` module with added functionality. -->

Governance is an important aspect within blockchains. In the Cosmos ecosystems, we can see challenges with today's solutions including:

- Colluding parties
- Social and monetary pressures for people to vote a certain way

The `privgov` repo was created to showcase an easy-to-use solution to incorporate truly fair, and credible governance systems. Using `privgov` in a Cosmos chain enable encrypted voting, getting these systems closer to true democracy.

> The core code outlined in the next section can be incorporated into your own Cosmos chain such that `privgov` enables encrypted voting.

## Integrating `privgov` into a Cosmos SDK Project

The core logic for `privgov` can be incorporated into your own Cosmos SDK project by following these steps.

1. Add the following in the `replace` clause of your `go.mod` file:

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

2. The custom `gov` module has to be registered with the IBC router. To do that, simply add the route in the `app/ibc.go` file:

```go
    // Add gov module to IBC Router
    govIBCModule := ibcfee.NewIBCMiddleware(gov.NewIBCModule(app.GovKeeper), app.IBCFeeKeeper)
    ibcRouter.AddRoute(govtypes.ModuleName, govIBCModule)

    app.IBCKeeper.SetRouter(ibcRouter)
```

> The route must be added to the `ibcrouter` before calling the `SetRouter()` function

That's it! You now should have the `privgov` functionality incorporated into your cosmos chain. Now we will continue with the tutorial to test and showcase the `privgov` in action.

## Setting up the test environment

To setup the testing environment, simply run the `priv_gov_setup.sh` file and follow along with the prompts. The script does the following things:

1. Sets up and starts the fairying chain (with all its bells and whistles)
2. Sets up and starts the `privgov` chain
3. Creates a IBC channel between the fairyring chain and privgov chain and starts the Hermes relayer

> It is recommended to use a short time frame for quick iterative tests, such as 3min or so.

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

So to start the governance process, make a governance proposal by running the following command:

```bash
privgovd tx gov submit-proposal draft_proposal.json --from fred --chain-id privgov
```

> ℹ️ When specifying the from user, or users in general throughout this tutorial, do not use `bob`. This user has some problematic aspects that can cause the tutorial to not run, and has been seen in other cosmos sdk chain tests.

Once the proposal is created, query the proposal to assess its details. You can now get the unique identity and pubkey for the proposal.

```bash
privgovd q gov proposals
```

<!-- TODO: HASH GET A SCREENSHOT OF WHAT THE OUTPUT COULD LOOK LIKE -->

You can then use the `encrypt-vote` functionality to encrypt your vote. Use the bash command and details from querying the proposal, such as the `identity`, and `pubkey` to submit the tx:

```bash
fairyringd encrypt-vote yes <identity> <random salt> <pubkey>
```

An example of the command you would use should look like this, but with different identities, salts, and pubkeys.

```bash
fairyringd encrypt-vote yes 1/rq 1234 b5b8a299700e44ae0b0ffb54903a253555f60babdf0d3ceddac4253840a92ac9511d8a236efe2db2d518e9dbb50ea973
```

<!-- TODO: Write up a brief blurb on submitting the encrypted vote -->
Now that you have encrypted your 'yes' vote, and have a resultant ciphertext, you can now vote on the respective proposal. Run the following command with appropriate vars from your proposal query.

```bash
privgovd tx gov vote-encrypted [proposal-id] [encrypted data]
```

An example of the command you would use should look like this, but with different proposal-ids, and encrypted data.

```bash
privgovd tx gov vote-encrypted 1 6167652d656e6372797074696f6e2e6f72672f76310a2d3e20646973744942450a6939617a7438786859522f464758624a6d3853506d5a5867447250756d4a416e4e3531773573694b2b316866554b6d655139463562454e79363962696755414e0a62583137734c4a71444643394b5035766a5245363267495a5252444531744d77384c384f6b524e33636267344d442b3547666553765a6d3058692b4c2b6165410a784c4e74642b47303439725554623449684d717144770a2d2d2d2053324f6e484236794463387a4c44796f4c684142375079736e6a66786a4f634a41304e5446577a4b694b550aba5083c1b3ac61036b29e97e67cbf04a10d799fdf1a54e649ea15b7e2c6aa52c2f1feaedad --from alice
 --chain-id privgov
```

Once the vote is submitted, wait for the voting period to be over and the votes to be tallied. You can query the proposal whenever to see the proposal status, again by using:

```bash
privgovd q gov proposals
```

Once the voting period has ended, the proposal final status will be hit. It will either be FAIL or SUCCESS. If you voted 'yes', then the proposal should have passed.

<!-- TODO: show image of a successful vote -->

## Congratulations

You have successfully carried out a private governance proposal, submitted an encrypted vote, and saw that it successfully passed!

Let's recap what you've accomplished through this quickstart:

- Shown and understood how to implement the `privgov` functionality, using Fairblock, in your own Cosmos SDK chain.
- Ran a successful private governance proposal
- Submitted successful encrypted votes to said proposal

Now that you have gone through the quickstart, feel free to dig into other tutorials or build with fellow Fairblock devs!

For more specific questions, please reach out either on [Discord](TODO-GET-LINK) or our [open issues repo](TODO-GET-LINK).

