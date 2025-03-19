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

## Setting up test networks

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


### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
