// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Script } from "forge-std/Script.sol";
import { Stake } from "../src/contracts/Stake.sol";
import { console } from "forge-std/console.sol";
import { Time } from "../src/libraries/Time.sol";

contract StakeScript is Script {
    function run() external {
        vm.startBroadcast();

        Stake stake = Stake(payable(0x9E545E3C0baAB3E08CdfD552C960A1050f373042));
        stake.stake{value : 1 ether}(0, Time.ONE_DAY * 100);
        stake.checkClaimable(0, msg.sender);
        stake.userInfo(0, msg.sender);
        stake.poolInfo(0);
        vm.stopBroadcast();
    }
}
