# Ethereum Vault Connector (EVC) Playground

To start a local node 

```bash
anvil
```

You will need to set MNEMONIC

i.e. if you are using Anvil you can type 
```bash
export MNEMONIC="test test test test test test test test test test test junk"
```

```bash
forge script script/01_Deployment.s.sol:Deployment --rpc-url "http://127.0.0.1:8545" --broadcast
```

You will receive a list of addresses

  Deployer 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
  EVC 0x5FbDB2315678afecb367f032d93F642f64180aa3
  IRM 0xa513E6E4b8f2a923D98304ec87F64353C4D5C853
  Price Oracle 0x8A791620dd6260079BF849Dc5567aDC3F2FdC318
  Asset 1 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
  Asset 2 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
  Asset 3 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9
  Vault Asset 1 0x0DCd1Bf9A1b36cE34237eEaFef220932846BCD82
  Vault Asset 2 0x9A676e781A523b5d0C0e43731313A708CB607508
  Vault Asset 3 0x0B306BF915C4d645ff596e518fAf3F9669b97016
  Lens 0x4A679253410272dd5232B3Ff7cF5dbB88f295319


To interact with the Vault you can run the VaultOp script 

```bash
sh vaultOp.sh
```

You may need to update the Parameters in the script

ASSET_ADDRESS="0x..."
VAULT_ADDRESS="0x..."
EVC_ADDRESS="0x..."

The script support the following operations:

1) Approve tokens
2) Deposit tokens    
3) Check balance
4) Withdraw tokens
5) Exit