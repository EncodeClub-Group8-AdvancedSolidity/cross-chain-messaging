############################# HELP MESSAGE #############################
# Make sure the help command stays first, so that it's printed by default when `make` is called without arguments
.PHONY: help tests
help:
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

PRIV_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
USER_ADDR=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
RPC_L1=http://localhost:8545
RPC_A=http://localhost:9545
RPC_B=http://localhost:9546
SUPERCHAIN_TOKEN_BRIDGE=0x4200000000000000000000000000000000000028
VAULT_CONTRACT_ADDRESS=$(shell jq -r '.deployedAddress' deployment-erc4626.json)
TOKEN_CONTRACT_ADDRESS=0x6d9657d9A35A467019627E7F0a89e67fbaBFD1aF
PING_PONG_CONTRACT_ADDRESS=0x9A4C1F19dA9EAD10EF26a08061B38BA7227156ae

-----------------------------: ## 

___Setup___: ## 

init: ## Initialize .env files and install dependencies
	npm run init:env && npm i
run-dev: ## Run dev environment
	npm run dev

-----------------------------: ## 

___MAIN___: ## 

run-supersim: ## Run supersim in vanilla mode
	supersim --interop.autorelay
deploy-token: ## deploy SuperchainERC20 token to ChainA and ChainB
	npm run deploy:token
deploy-vault: ## deploy SuperchainVault to ChainA and ChainB
	npm run deploy:vault
mint-token: ## Mint 1000 tokens to the user address on ChainA
	cast send ${TOKEN_CONTRACT_ADDRESS} "mintTo(address _to, uint256 _amount)"  ${USER_ADDR} 1000 --rpc-url ${RPC_A} --private-key ${PRIV_KEY}
approve-token: ## Approve 1000 tokens to the vault contract on ChainA
	cast send ${TOKEN_CONTRACT_ADDRESS} "approve(address,uint256)" ${VAULT_CONTRACT_ADDRESS} 1000 --rpc-url ${RPC_A} --private-key ${PRIV_KEY}
deposit-token: ## Deposit 100 tokens to the vault contract on ChainA
	cast send ${VAULT_CONTRACT_ADDRESS} "deposit(uint256,address)" 100 ${USER_ADDR} --rpc-url ${RPC_A} --private-key ${PRIV_KEY}
bridge-shares: ## Bridge 50 tokens to ChainB
	cast send ${SUPERCHAIN_TOKEN_BRIDGE} "sendERC20(address _token, address _to, uint256 _amount, uint256 _chainId)" ${VAULT_CONTRACT_ADDRESS} ${USER_ADDR} 50 902 --rpc-url ${RPC_A} --private-key ${PRIV_KEY}
rebalance-vault: ## Initiate a rebalance to chain 902
	cast send ${VAULT_CONTRACT_ADDRESS} "initiateRebalance(address,uint256,uint256)" ${TOKEN_CONTRACT_ADDRESS} 50 902 --rpc-url ${RPC_A} --private-key ${PRIV_KEY}
balance-of-vault: ## Check the balance of the vault contract on ChainA and ChainB
	@echo "ChainA - `cast balance --erc20 ${TOKEN_CONTRACT_ADDRESS} ${VAULT_CONTRACT_ADDRESS} --rpc-url ${RPC_A}`"
	@echo "ChainB - `cast balance --erc20 ${TOKEN_CONTRACT_ADDRESS} ${VAULT_CONTRACT_ADDRESS} --rpc-url ${RPC_B}`"
balance-of-share-token: ## Check the balance of the user address on ChainA and ChainB
	@echo "User_ChainA - `cast balance --erc20 ${VAULT_CONTRACT_ADDRESS} ${USER_ADDR} --rpc-url ${RPC_A}`"
	@echo "User_ChainB - `cast balance --erc20 ${VAULT_CONTRACT_ADDRESS} ${USER_ADDR} --rpc-url ${RPC_B}`"

-----------------------------: ## 

___EXAMPLES___: ## 

deploy-greeter: ## test deploy Greeter contract to ChainB
	$(eval GREETER_B_ADDR=$(shell forge create --rpc-url ${RPC_B} --private-key ${PRIV_KEY} Greeter --broadcast | awk '/Deployed to:/ {print $$3}'))
	@echo "Greeter deployed to: ${GREETER_B_ADDR}"
	@echo "GREETER_B_ADDR=${GREETER_B_ADDR}"

deploy-greetingsender: deploy-greeter ## test deploy GreetingSender contract to ChainA
	$(eval GREETER_A_ADDR=$(shell forge create --rpc-url ${RPC_A} --private-key ${PRIV_KEY} --broadcast GreetingSender --constructor-args ${GREETER_B_ADDR} 902 | awk '/Deployed to:/ {print $$3}'))
	@echo "GreetingSender deployed to: ${GREETER_A_ADDR}"
	@echo "GREETER_A_ADDR=${GREETER_A_ADDR}"

send-greeter-message: deploy-greetingsender ## send message from GreetingSender to Greeter
	cast call --rpc-url ${RPC_B} ${GREETER_B_ADDR} "greet()" | cast --to-ascii
	cast send --private-key ${PRIV_KEY} --rpc-url ${RPC_A} ${GREETER_A_ADDR} "setGreeting(string)" "Hello from chain A, with a CrossDomainSetGreeting event"
	sleep 2
	cast call --rpc-url ${RPC_B} ${GREETER_B_ADDR} "greet()" | cast --to-ascii

read-greeter-logs: send-greeter-message ## read logs from Greeter contract (expected output: 901)
	cast logs --rpc-url ${RPC_B} 'CrossDomainSetGreeting(address,uint256,string)'
	echo ${GREETER_A_ADDR}
	echo 0x385 | cast --to-dec

deploy-pingpong: ## deploy PingPong contract to ChainA and ChainB
	npm run deploy:ping
hit-ball: ## hit the ball from PingPong contract on ChainA
	cast send ${PING_PONG_CONTRACT_ADDRESS} "hitBallTo(uint256)" 902 --rpc-url ${RPC_B} --private-key ${PRIV_KEY}
