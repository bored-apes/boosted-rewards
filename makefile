-include .env

stake_deploy:
	forge script script/StakeDeploy.s.sol --rpc-url $(LOCAL_RPC) --private-key $(LOCAL_PRIVATE_KEY) --broadcast
stake_script:
	forge script script/Stake.s.sol --rpc-url $(LOCAL_RPC) --private-key $(LOCAL_PRIVATE_KEY) --broadcast
	