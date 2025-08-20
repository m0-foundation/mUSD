# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env

# dapp deps
update:; forge update


# Run slither
slither :; FOUNDRY_PROFILE=production forge build --build-info --skip '*/test/**' --skip '*/script/**' --force && slither --compile-force-framework foundry --ignore-compile --sarif results.sarif --config-file slither.config.json .

# Common tasks
profile ?=default

build:
	@./build.sh -p production

tests:
	@./test.sh -p $(profile)

fuzz:
	@./test.sh -t testFuzz -p $(profile)

integration:
	@./test.sh -d test/integration -p $(profile)

invariant:
	@./test.sh -d test/invariant -p $(profile)

coverage:
	FOUNDRY_PROFILE=$(profile) forge coverage --report lcov && lcov --extract lcov.info -o lcov.info 'src/*' --ignore-errors inconsistent && genhtml lcov.info -o coverage

gas-report:
	FOUNDRY_PROFILE=$(profile) forge test --force --gas-report > gasreport.ansi

sizes:
	@./build.sh -p production -s

clean:
	forge clean && rm -rf ./abi && rm -rf ./bytecode && rm -rf ./types

# Deployment helpers
deploy:
	FOUNDRY_PROFILE=production PRIVATE_KEY=$(PRIVATE_KEY) \
	ADMIN=$(ADMIN) PAUSER=$(PAUSER) \
	YIELD_RECIPIENT=$(YIELD_RECIPIENT) YIELD_RECIPIENT_MANAGER=$(YIELD_RECIPIENT_MANAGER) \
	FREEZE_MANAGER=$(FREEZE_MANAGER) FORCED_TRANSFER_MANAGER=$(FORCED_TRANSFER_MANAGER) \
	forge script script/deploy/DeployMUSD.s.sol:DeployMUSD \
	--rpc-url $(RPC_URL) \
	--private-key $(PRIVATE_KEY) \
	--skip test --slow --non-interactive --broadcast --verify

deploy-local: RPC_URL=$(LOCALHOST_RPC_URL)
deploy-local: deploy

deploy-mainnet: RPC_URL=$(MAINNET_RPC_URL)
deploy-mainnet: deploy

deploy-linea: RPC_URL=$(LINEA_RPC_URL)
deploy-linea: deploy

deploy-sepolia: RPC_URL=$(SEPOLIA_RPC_URL)
deploy-sepolia: deploy

deploy-linea-sepolia: RPC_URL=$(LINEA_SEPOLIA_RPC_URL)
deploy-linea-sepolia: deploy

# Upgrade helpers
upgrade:
	FOUNDRY_PROFILE=production PRIVATE_KEY=$(PRIVATE_KEY) \
	forge script script/upgrade/UpgradeMUSD.s.sol:UpgradeMUSD \
	--rpc-url $(RPC_URL) \
	--private-key $(PRIVATE_KEY) \
	--skip test --slow --non-interactive --broadcast --verify

upgrade-local: RPC_URL=$(LOCALHOST_RPC_URL)
upgrade-local: upgrade

upgrade-mainnet: RPC_URL=$(MAINNET_RPC_URL)
upgrade-mainnet: upgrade

upgrade-linea: RPC_URL=$(LINEA_RPC_URL)
upgrade-linea: upgrade
