-include .env

stake_deploy:
	forge script script/StakeDeploy.s.sol --rpc-url $(LOCAL_RPC) --private-key $(LOCAL_PRIVATE_KEY) --broadcast -vvvv
stake_script:
	forge script script/Stake.s.sol --rpc-url $(LOCAL_RPC) --private-key $(LOCAL_PRIVATE_KEY) --broadcast -vvvv

stake_deploy_testnet:
	forge script script/StakeDeploy.s.sol --rpc-url $(TESTNET_RPC) --private-key $(TESTNET_PRIVATE_KEY) --broadcast -vvvv
stake_script_testnet:
	forge script script/Stake.s.sol --rpc-url $(TESTNET_RPC) --private-key $(TESTNET_PRIVATE_KEY) --broadcast -vvvv