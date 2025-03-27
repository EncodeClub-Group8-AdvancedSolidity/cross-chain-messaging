# Superchain Vault Connector

Superchain Vault Connector is an intermediary between user accounts and SuperchainERC-4626 compliant vaults across the Superchain.

## What is this project?

This project implements an ERC4626 vault  that can hold SuperchainERC20 tokens as its underlying asset. And allows a rebalancing of the underlying assets on the superchain cluster.


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
- make: For simple execution scripts

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
3. `jq` if it's not already installed
  ```bash
  sudo apt-get install jq  # For Ubuntu/Debian
  brew install jq          # For macOS
  ```

Add `supersim` to path: For Bash at `$HOME/.bashrc`. `$HOME/.zshrc` for Zsh.

```bash
# Add supersim PATH
export PATH="$PATH:$HOME/supersim"
```
## Running via make

### Initialize the env and dependencies
```bash
make init
```
### Option 1: Run the project in mprocs

Runs multiple commands in parallel.
```bash
make run-dev 
```

### Option 2: Detailed commands

```bash
# To view the full list of commands available 
make
```

1. Start Supersim in a separate terminal:
```bash
make run-supersim
```
2. Deploy the underlying asset (SuperchainERC20) to ChainA and ChainB
```bash
make deploy-token 
```

3. Deploy the ERC4626-vault (Superchain compatible) to ChainA and ChainB
```bash
make deploy-vault
```

4. Mint 1000 SuperchainTokens to a User on ChainA
```bash
make mint-token
```

5. Approve the ERC4626-vault to spend the SuperchainToken(underlying asset)
```bash
make approve-token
```

6. Deposit the uderlying asset to recieve vault shares from the ERC4626-vault
```bash
make deposit-token
```

```bash
# Check the balance of the user
make balance-of-share-token  
```

7. Bridge half of the shares recieved from step-5 to ChainB
```bash
make bridge-shares
```
```bash
# Check the balance of the user
make balance-of-share-token 

# Check the balance of the underlying asset
make balance-of-vault 
```

8. Rebalance the vault underlying asset between ChainA and ChainB

```bash
make rebalance-vault
```
```bash
# Check the balance of the underlying asset
make balance-of-vault 
```

### Examples

1. Crosschain Ping Pong
```bash
# Deploy the contracts
make deploy-pingpong
# Hit the ball on ChainA
make hit-ball
# Inspect the logs from L2ToL2CrossDomainMessenger
cast logs --address 0x4200000000000000000000000000000000000023 --rpc-url http://127.0.0.1:9545
```

2. Crosschain greeter

```bash
# Send a greeting message from ChainA to ChainB
make send-greeter-message 
# Returns a message "Hello from chain A, with a CrossDomainSetGreeting event"

# Read a log of a greeting sent crosschain
make read-greeter-logs
# Expected return is 901
```


## 🚀 Getting Started with Greeter

### Supersim Vanilla

```shell
$ supersim --interop.autorelay
```

Supersim creates three anvil blockchains:

1. L1 at http://127.0.0.1:8545
2. OPChainA at http://127.0.0.1:9545
3. OPChainB at http://127.0.0.1:9546

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

> Note: This project uses `soldeer`, therefore use `forge soldeer install` to resolve dependency issues.

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

Before proceeding with this section, ensure that your `deploy-config.toml` file is fully configured (see the [Deployment config](#deployment-config) section for more details on setup). Additionally, confirm that the `[rpc_endpoints]` section in `foundry.toml` is properly set up.
Deployments are executed through the `SuperchainERC20Deployer.s.sol` script. This script deploys tokens across each specified chain in the deployment configuration using `Create2`, ensuring deterministic contract addresses for each deployment. The script targets the `L2NativeSuperchainERC20.sol` contract by default. If you need to modify the token being deployed, either update this file directly or point the script to a custom token contract of your choice.

To execute a token deployment run:

```sh
npm run deploy:token

```

## How to Relay message

### Using cast

1. Get the log emitted by the `L2ToL2CrossDomainMessenger`, which has an address of `0x4200000000000000000000000000000000000023`
   - `cast logs --address 0x4200000000000000000000000000000000000023 --rpc-url http://127.0.0.1:9545`
   - Get `blockHash` for step-2
   - Get `topic` and `data` for step-3
   - Get `blockNumber`, `logIndex` for step-4
2. Retrieve the block timestamp from the log of step-1
   - `cast block 0xREPLACE_WITH_CORRECT_BLOCKHASH --rpc-url http://127.0.0.1:9545`
   - The timestamp will be used in `step-4` for `relayMessage()`
3. Prepare the message identifier & payload
   - Take the `topic` and `data` from Step-1 of log emitted
   - "0x....the....topic.....+....data"
   - e.g: `0x382409ac69001e11931a28435afef442cbfd20d9891907e8fa373ba7d351f3200000000000000000000000000000000000000000000000000000000000000386000000000000000000000000420beef0000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000420beef00000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000064d9f50046000000000000000000000000f39fd6e51aad88f6f4ce6ab8827279cfffb92266000000000000000000000000f39fd6e51aad88f6f4ce6ab8827279cfffb9226600000000000000000000000000000000000000000000000000000000000003e800000000000000000000000000000000000000000000000000000000`
4. Send the relayMessage transaction
   - REPLACE_WITH_THE_VALUES `relayMessage(L2ToL2CrossDomainMessenger, blocknumber, logIndex, timestamp, chainid)`
   - `cast send 0x4200000000000000000000000000000000000023 --gas-limit 200000 "relayMessage((address, uint256, uint256, uint256, uint256), bytes)" "(0x4200000000000000000000000000000000000023, 4, 1, 1728507703, 901)" 0xTOPIC_AND_DATA_CONCATED --rpc-url http://127.0.0.1:9546 --private-key $PRIV_KEY`

## Cross-Chain Ping Pong

### Deploy the contract to ChainA and ChainB

Have supersim running in autorelay mode

```shell
$ supersim --interop.autorelay
```

Deploy with a script to a determinstic address on both chains

```sh
npm run deploy:ping
```

1. Call Hit ball
   - `cast send 0x9A4C1F19dA9EAD10EF26a08061B38BA7227156ae "hitBallTo(uint256)" 902 --rpc-url http://127.0.0.1:9545 --private-key $PRIV_KEY`

If the relay fails, run a manual relay message call

2. Relay message
   - `cast logs --address 0x4200000000000000000000000000000000000023 --rpc-url http://127.0.0.1:9545`
   - Retrieve block-timestamp: `cast block 0xREPLACE_WITH_CORRECT_BLOCKHASH --rpc-url http://127.0.0.1:9545` E.g `1742907859`
   - Prepare payload `topic & data` concat
   - Send the relayMessage transaction
     - `cast send 0x4200000000000000000000000000000000000023 --gas-limit 200000 "relayMessage((address, uint256, uint256, uint256, uint256), bytes)" "(0x4200000000000000000000000000000000000023, REPLACE_WITH_blocknumber, REPLACE_WITH_logIndex, REPLACE_WITH_timestamp, 901)" 0xTOPIC_AND_DATA_CONCATED --rpc-url http://127.0.0.1:9546 --private-key $PRIV_KEY`

## Cross-chain rebalancing of ERC4626 Vault
### High level steps

Sending an interop message using the `L2ToL2CrossDomainMessenger`:

#### On source chain (OPChainA 901)

1. Invoke `L2ERC4626TokenVault.initiateRebalance` to bridge funds
  - this leverages `L2ToL2CrossDomainMessenger.sendMessage` to make the cross chain call
2. Retrieve the log identifier and the message payload for the `SentMessage` event.

#### On destination chain (OPChainB 902)

3. Relay the message with `L2ToL2CrossDomainMessenger.relayMessage`
  - which then calls `L2ERC4626TokenVault.relayAsset`

### Steps

1. Start the supersim and launch the vault contracts
```sh
supersim --interop.autorelay
npm run deploy:token
npm run deploy:vault
```

Once the `deploy:token` and `deploy:vault` scripts succeed, proceed to the following step.
```shell
VAULT_CONTRACT_ADDRESS=0xREPLACE_WITH_THE_VAULT_ADDRESS_FROM_deployment_erc4626_json
TOKEN_CONTRACT_ADDRESS=0x6d9657d9A35A467019627E7F0a89e67fbaBFD1aF
USER_ADDR=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
PRIV_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
RPC_L1=http://localhost:8545
RPC_A=http://localhost:9545
RPC_B=http://localhost:9546
```

2. Mint tokens to deposit on chain 901

```sh
cast send $TOKEN_CONTRACT_ADDRESS "mintTo(address _to, uint256 _amount)"  $USER_ADDR 1000  --rpc-url $RPC_A --private-key $PRIV_KEY
```

3. Initiate the deposit transaction on chain 901

- <VAULT_CONTRACT_ADDRESS>: The address of the deployed `L2ERC4626TokenVault` contract.
- <ASSET_AMOUNT>: The amount of the underlying asset you want to deposit.
- <RECEIVER_ADDRESS>: The address that will receive the shares.
- `$PRIV_KEY`: The private key of the account making the transaction.

Approve the vault to spend the underlying asset.
```sh
cast send $TOKEN_CONTRACT_ADDRESS "approve(address,uint256)" $VAULT_CONTRACT_ADDRESS 1000 --rpc-url $RPC_A --private-key $PRIV_KEY
```

```sh
cast send $VAULT_CONTRACT_ADDRESS "deposit(uint256,address)" 100 $USER_ADDR --rpc-url $RPC_A --private-key $PRIV_KEY
```

4. Initiate a rebalance to chain 902

```sh
cast send $VAULT_CONTRACT_ADDRESS "initiateRebalance(address,uint256,uint256)" $TOKEN_CONTRACT_ADDRESS 50 902 --rpc-url $RPC_A --private-key $PRIV_KEY
```

5. Check the balanceOf `VAULT` and `UNDERLYING_ASSET` across the opChains

After the rebalancing, the specified underlying asset amount will be distributed between the chains 

```sh
# Chain A underlying asset balance
cast balance --erc20 $TOKEN_CONTRACT_ADDRESS $VAULT_CONTRACT_ADDRESS --rpc-url $RPC_A
# Chain B underlying asset balance
cast balance --erc20 $TOKEN_CONTRACT_ADDRESS $VAULT_CONTRACT_ADDRESS --rpc-url $RPC_B
```
```sh
# Share Token balance of the user on Chain B
cast balance --erc20 $VAULT_CONTRACT_ADDRESS $USER_ADDR --rpc-url $RPC_B
# Share token balance of the user on Chain A
cast balance --erc20 $VAULT_CONTRACT_ADDRESS $USER_ADDR --rpc-url $RPC_A

```

# Cross-Chain Vault System

This project implements a cross-chain vault system that allows users to deposit tokens on one chain and have them available on another chain through Optimism's cross-chain messaging infrastructure.

## Prerequisites

- Foundry installed
- Access to two Optimism chains (Chain A and Chain B)
- Private key with sufficient funds on both chains
- Environment variables set up

## Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd cross-chain-messaging
```

2. Install dependencies:
```bash
forge install
```

3. Set up environment variables:
```bash
# Your private key (same on both chains)
export PRIVATE_KEY=your_private_key_here

# RPC endpoints for both chains
export RPC_A="http://127.0.0.1:9545"  # Chain A RPC endpoint
export RPC_B="http://127.0.0.1:9546"  # Chain B RPC endpoint

# Your wallet address (should be the same on both chains)
export ETH_FROM=your_wallet_address
```

4. Deploy the contracts on both chains:
```bash
# Deploy to Chain A
forge script script/SuperchainERC20Deployer.s.sol --rpc-url $RPC_A --broadcast

# Deploy to Chain B
forge script script/SuperchainERC20Deployer.s.sol --rpc-url $RPC_B --broadcast
```

5. Update the contract addresses in `evc/script/crossChainVaultOp.sh`:
```bash
# Edit these addresses to match your deployment
ASSET_ADDRESS="your_asset_address"
VAULT_ADDRESS="your_vault_address"
EVC_ADDRESS="your_evc_address"
```

## Interacting with the Cross-Chain Vault

### Using the Script

The `crossChainVaultOp.sh` script provides an interactive menu for interacting with the vault system.

1. Make the script executable:
```bash
chmod +x evc/script/crossChainVaultOp.sh
```

2. Run the script:
```bash
./evc/script/crossChainVaultOp.sh
```

### Available Operations

1. **Approve tokens**
   - Approves the vault to spend your tokens
   - Required before depositing

2. **Deposit tokens**
   - Deposits tokens into the vault on the current chain
   - Requires prior approval

3. **Check balance**
   - Shows your current vault share balance
   - Converts shares to asset value

4. **Withdraw tokens**
   - Withdraws tokens from the vault
   - Can be used on either chain

5. **Cross-chain deposit to Chain B**
   - Initiates a cross-chain deposit from Chain A to Chain B
   - Requires:
     - Amount to deposit
     - Target chain ID (Chain B)
     - Target vault address on Chain B

### Example Usage

1. First, approve tokens:
```bash
# Select "Approve tokens" from the menu
# Enter amount (default is 1 token = 1000000000000000000 wei)
```

2. Perform a cross-chain deposit:
```bash
# Select "Cross-chain deposit to Chain B"
# Enter:
# - Amount to deposit
# - Chain B's chain ID
# - Vault address on Chain B
```

3. Check your balance on Chain B:
```bash
# Switch RPC endpoint to Chain B
export RPC_ENDPOINT=$RPC_B
# Run the script again and select "Check balance"
```

## Important Notes

1. **Cross-Chain Messaging**
   - Messages take time to be processed between chains
   - Monitor the transaction status on both chains
   - The messenger contract address is predeployed at `0x4200000000000000000000000000000000000007`

2. **Gas Fees**
   - You need sufficient funds for:
     - Token approval transaction
     - Cross-chain message transaction
     - Gas fees on both chains

3. **Security**
   - Never share your private key
   - Keep your environment variables secure
   - Verify contract addresses before interactions

4. **Troubleshooting**
   - If a transaction fails, check:
     - Gas fees
     - Contract addresses
     - RPC endpoint connectivity
     - Chain synchronization status

## Architecture

The system consists of:
1. SuperchainERC20 token contract (deployed on both chains)
2. Vault contract (deployed on both chains)
3. Cross-chain messenger (predeployed on both chains)
4. EVC (Ethereum Vault Connector) contract

Messages flow from Chain A → Messenger → Chain B, with the messenger handling the cross-chain communication.

## Development

To modify or extend the system:

1. Update contract addresses in the scripts
2. Modify the vault contract for new functionality
3. Update the cross-chain messaging logic if needed
4. Test thoroughly on both chains
