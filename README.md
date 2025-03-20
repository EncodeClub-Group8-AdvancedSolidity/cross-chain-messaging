## Documentation
1. [InterOp message-passing](https://docs.optimism.io/stack/interop/message-passing)
2. [Message-passing Tutorial](https://docs.optimism.io/stack/interop/tutorials/message-passing)


## Development environment

- Unix-like operating system (Linux, macOS, or WSL for Windows)
- [Node.js version](https://github.com/Schniz/fnm) 16 or higher
- Git for version control

## Required tools
The primary tools:

- Foundry: For smart contract development
- Supersim: For local blockchain simulation
- TypeScript: For implementation
- Viem: For blockchain interaction

Verify your installation:

```bash
forge --version
supersim --version
```
### Installations
1. [Foundry](https://book.getfoundry.sh/getting-started/installation)
2. Supersim
    - [Precompiled binaries](https://github.com/ethereum-optimism/supersim/releases)
    - [Homebrew](https://brew.sh/) (OS X, Linux)
    ```bash
    brew tap ethereum-optimism/tap
    brew install supersim
    ```

Add `supersim` to path: For Bash at `$HOME/.bashrc`. `$HOME/.zshrc` for Zsh. 
```
# Add supersim PATH
export PATH="$PATH:$HOME/supersim"
```

## 🚀 Getting Started with Greeter

### Supersim Vanilla

```shell
$ supersim --interop.autorelay
```
Supersim creates three anvil blockchains:

1. L1 at http://127.0.0.1:8545
2. OPChainA	at http://127.0.0.1:9545
3. OPChainB	at http://127.0.0.1:9546

### Store the configuration in environment variables
In a separate shell,
```shell
USER_ADDR=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
PRIV_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
RPC_L1=http://localhost:8545
RPC_A=http://localhost:9545
RPC_B=http://localhost:9546
```

### Deploy Greeter

```shell
$ GREETER_B_ADDR=`forge create --rpc-url $RPC_B --private-key $PRIV_KEY Greeter --broadcast | awk '/Deployed to:/ {print $3}'`
```

### Deploy GreetingSender to chain A

```shell
$ GREETER_A_ADDR=`forge create --rpc-url $RPC_A --private-key $PRIV_KEY --broadcast GreetingSender --constructor-args $GREETER_B_ADDR 902 | awk '/Deployed to:/ {print $3}'`
```

### Send a message
Send a greeting from chain A to chain B.
```shell
$ cast call --rpc-url $RPC_B $GREETER_B_ADDR "greet()" | cast --to-ascii 
cast send --private-key $PRIV_KEY --rpc-url $RPC_A $GREETER_A_ADDR "setGreeting(string)" "Hello from chain A, with a CrossDomainSetGreeting event"
sleep 2
cast call --rpc-url $RPC_B $GREETER_B_ADDR "greet()" | cast --to-ascii
```

### Read the log entries

```shell
$ cast logs --rpc-url $RPC_B 'CrossDomainSetGreeting(address,uint256,string)'
echo $GREETER_A_ADDR
echo 0x385 | cast --to-dec
```


## 🚀 Getting Started with SuperchainERC20


### 1. Initialize .env files:

```sh
npm run init:env
```
### 2. Install project dependencies:

```sh
npm i
```
### 3. Start the development environment:

This command will:

- Start the `supersim` local development environment
- Deploy the smart contracts to the test networks
- Launch the example frontend application

```sh
npm run dev
```

## 📦 Deploying SuperchainERC20s

### Configuring RPC urls

This repository includes a script to automatically fetch the public RPC URLs for each chain listed in the [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/main/chainList.json) and add them to the `[rpc_endpoints]` configuration section of `foundry.toml`.

The script ensures that only new RPC URLs are appended, preserving any URLs already present in `foundry.toml`. To execute this script, run:

```sh
npm run update:rpcs
```

### Deployment config

The deployment configuration for token deployments is managed through the `deploy-config.toml` file. Below is a detailed breakdown of each configuration section:

#### `[deploy-config]`

This section defines parameters for deploying token contracts.

- `salt`: A unique identifier used for deploying token contracts via [`Create2`]. This value along with the contract bytecode ensures that contract deployments are deterministic.
  - example: `salt = "ethers phoenix"`
- `chains`: Lists the chains where the token will be deployed. Each chain must correspond to an entry in the `[rpc_endpoints]` section of `foundry.toml`.
  - example: `chains = ["op_chain_a","op_chain_b"]`

#### `[token]`

Deployment configuration for the token that will be deployed.

- `owner_address`: the address designated as the owner of the token.
  - The `L2NativeSuperchainERC20.sol` contract included in this repo extends the [`Ownable`](https://github.com/Vectorized/solady/blob/c3b2ffb4a3334ea519555c5ea11fb0e666f8c2bc/src/auth/Ownable.sol) contract
  - example: `owner_address = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"`
- `name`: the token's name.
  - example: `name = "TestSuperchainERC20"`
- `symbol`: the token's symbol.
  - example: `symbol = "TSU"`
- `decimals`: the number of decimal places the token supports.
  - example: `decimals = 18`

### Deploying a token

Before proceeding with this section, ensure that your `deploy-config.toml` file is fully configured (see the [Deployment config](#deployment-config) section for more details on setup). Additionally, confirm that the `[rpc_endpoints]` section in `foundry.toml` is properly set up by following the instructions in [Configuring RPC urls](#configuring-rpc-urls).

Deployments are executed through the `SuperchainERC20Deployer.s.sol` script. This script deploys tokens across each specified chain in the deployment configuration using `Create2`, ensuring deterministic contract addresses for each deployment. The script targets the `L2NativeSuperchainERC20.sol` contract by default. If you need to modify the token being deployed, either update this file directly or point the script to a custom token contract of your choice.

To execute a token deployment run:

```sh
npm run deploy:token

```
