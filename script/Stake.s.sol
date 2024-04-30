// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Script } from "forge-std/Script.sol";
import { Stake } from "../src/contracts/Stake.sol";
import { console } from "forge-std/console.sol";
import { Time } from "../src/libraries/Time.sol";

contract StakeScript is Script {
    function run() external {
        vm.startBroadcast();

        Stake stake = Stake(payable(0xFF05395dC2855Fb13aA962DD52e377F2c79633F4));
        // stake.stake{value : 10**16}(0, Time.ONE_DAY * 300);
        // payable(stake).transfer(10**17);
        // stake.checkClaimable(0, msg.sender);
        // stake.userInfo(0, msg.sender);
        // stake.poolInfo(0);
        // stake.claim(0);
        // stake.checkClaimable(0, msg.sender);

        vm.stopBroadcast();
    }
}
// 