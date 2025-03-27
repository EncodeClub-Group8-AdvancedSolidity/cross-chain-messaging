#!/bin/bash

# Parameters - Edit these to match your deployment
ASSET_ADDRESS="0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512"
VAULT_ADDRESS="0x0DCd1Bf9A1b36cE34237eEaFef220932846BCD82" 
EVC_ADDRESS="0x5FbDB2315678afecb367f032d93F642f64180aa3"
USER_ADDRESS=${ETH_FROM:-"0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"} # Default or from env
MESSENGER_ADDRESS="0x4200000000000000000000000000000000000007" # L2_TO_L2_CROSS_DOMAIN_MESSENGER

# RPC endpoint - Set this to Chain A's RPC when initiating cross-chain deposits
RPC_ENDPOINT=${RPC_A:-"http://127.0.0.1:9545"} # Default to Chain A's RPC

# Check if PRIVATE_KEY is set
if [ -z "$PRIVATE_KEY" ]; then
  echo "Error: PRIVATE_KEY environment variable not set"
  echo "Please run: export PRIVATE_KEY=your_private_key"
  exit 1
fi

# Amount constants (in wei)
DEFAULT_DEPOSIT_AMOUNT="1000000000000000000"  # 1 token
DEFAULT_BORROW_AMOUNT="500000000000000000"    # 0.5 token

# Function to check if a contract exists
check_contract() {
  local address=$1
  local code=$(cast code $address --rpc-url $RPC_ENDPOINT)
  if [ -z "$code" ] || [ "$code" == "0x" ]; then
    echo "Error: No contract at address $address"
    return 1
  fi
  return 0
}

# Function to approve token spending
approve_tokens() {
  local amount=${1:-$DEFAULT_DEPOSIT_AMOUNT}
  echo "Approving $amount tokens to be spent by vault..."
  cast send $ASSET_ADDRESS "approve(address,uint256)(bool)" $VAULT_ADDRESS $amount --private-key=$PRIVATE_KEY --rpc-url $RPC_ENDPOINT
  echo "Approval successful!"
}

# Function to deposit tokens
deposit_tokens() {
  local amount=${1:-$DEFAULT_DEPOSIT_AMOUNT}
  echo "Depositing $amount tokens into vault..."
  cast send $VAULT_ADDRESS "deposit(uint256,address)(uint256)" $amount $USER_ADDRESS --private-key=$PRIVATE_KEY --rpc-url $RPC_ENDPOINT
  echo "Deposit successful!"
}

# Function to check balance
check_balance() {
  echo "Checking vault share balance..."
  local balance=$(cast call $VAULT_ADDRESS "balanceOf(address)(uint256)" $USER_ADDRESS --rpc-url $RPC_ENDPOINT)
  echo "Your vault share balance: $balance"
  
  echo "Converting to asset value..."
  local asset_value=$(cast call $VAULT_ADDRESS "convertToAssets(uint256)(uint256)" $balance --rpc-url $RPC_ENDPOINT)
  echo "Equivalent asset value: $asset_value"
}

# Function to withdraw tokens
withdraw_tokens() {
  local amount=${1:-$DEFAULT_DEPOSIT_AMOUNT}
  echo "Withdrawing $amount tokens from vault..."
  cast send $VAULT_ADDRESS "withdraw(uint256,address,address)(uint256)" $amount $USER_ADDRESS $USER_ADDRESS --private-key=$PRIVATE_KEY --rpc-url $RPC_ENDPOINT
  echo "Withdrawal successful!"
}

# Function to perform cross-chain deposit
cross_chain_deposit() {
  local amount=${1:-$DEFAULT_DEPOSIT_AMOUNT}
  local target_chain_id=$2
  local target_vault=$3
  
  echo "Initiating cross-chain deposit from Chain A to Chain B..."
  echo "Amount: $amount wei"
  echo "Target Chain ID: $target_chain_id"
  echo "Target Vault: $target_vault"
  
  # First approve the messenger to spend tokens
  echo "Approving messenger to spend tokens on Chain A..."
  cast send $ASSET_ADDRESS "approve(address,uint256)(bool)" $MESSENGER_ADDRESS $amount --private-key=$PRIVATE_KEY --rpc-url $RPC_ENDPOINT
  
  # Encode the deposit message
  local message=$(cast abi-encode "deposit(uint256,address)(uint256)" $amount $USER_ADDRESS)
  
  # Send the cross-chain message
  echo "Sending cross-chain message through Chain A's messenger..."
  cast send $MESSENGER_ADDRESS "sendMessage(uint256,address,bytes)" $target_chain_id $target_vault $message --private-key=$PRIVATE_KEY --rpc-url $RPC_ENDPOINT
  
  echo "Cross-chain deposit initiated! Note: This may take some time to be processed on Chain B."
}

# Main execution
echo "ERC4626 Vault Interaction Script"
echo "==============================="
echo "Operating on Chain A (Source Chain)"
echo "RPC Endpoint: $RPC_ENDPOINT"
echo "Asset: $ASSET_ADDRESS"
echo "Vault: $VAULT_ADDRESS"
echo "User: $USER_ADDRESS"
echo "Messenger: $MESSENGER_ADDRESS"
echo

# Check if contracts exist
check_contract $ASSET_ADDRESS || exit 1
check_contract $VAULT_ADDRESS || exit 1
check_contract $MESSENGER_ADDRESS || exit 1

# Menu
PS3="Select an operation: "
options=("Approve tokens" "Deposit tokens" "Check balance" "Withdraw tokens" "Cross-chain deposit to Chain B" "Exit")
select opt in "${options[@]}"
do
  case $opt in
    "Approve tokens")
      read -p "Amount (in wei, default=$DEFAULT_DEPOSIT_AMOUNT): " amount
      approve_tokens ${amount:-$DEFAULT_DEPOSIT_AMOUNT}
      ;;
    "Deposit tokens")
      read -p "Amount (in wei, default=$DEFAULT_DEPOSIT_AMOUNT): " amount
      deposit_tokens ${amount:-$DEFAULT_DEPOSIT_AMOUNT}
      ;;
    "Check balance")
      check_balance
      ;;
    "Withdraw tokens")
      read -p "Amount (in wei, default=$DEFAULT_DEPOSIT_AMOUNT): " amount
      withdraw_tokens ${amount:-$DEFAULT_DEPOSIT_AMOUNT}
      ;;
    "Cross-chain deposit to Chain B")
      read -p "Amount (in wei, default=$DEFAULT_DEPOSIT_AMOUNT): " amount
      read -p "Target chain ID (Chain B): " target_chain_id
      read -p "Target vault address on Chain B: " target_vault
      cross_chain_deposit ${amount:-$DEFAULT_DEPOSIT_AMOUNT} $target_chain_id $target_vault
      ;;
    "Exit")
      break
      ;;
    *) 
      echo "Invalid option $REPLY"
      ;;
  esac
  echo
done

echo "Script completed!"