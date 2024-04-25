// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Script } from "forge-std/Script.sol";
import { Stake } from "../src/contracts/Stake.sol";
import { console } from "forge-std/console.sol";
import { Time } from "../src/libraries/Time.sol";

contract StakeScript is Script {
    function run() external {
        vm.startBroadcast();

        Stake stake = Stake(payable(0x4ed7c70F96B99c776995fB64377f0d4aB3B0e1C1));
        // stake.stake{value : 100 ether}(0, Time.ONE_DAY * 300);
        // payable(stake).transfer(1000 ether);
        // stake.checkClaimable(0, msg.sender);
        stake.userInfo(0, msg.sender);
        // stake.poolInfo(0);
        // stake.claim(0);
        // stake.checkClaimable(0, msg.sender);

        vm.stopBroadcast();
    }
}

// 8962100456621004560  --> 08.96210045
// 69008173515981735112 --> 69.00817351
// 49291552511415525080 --> 49.29155251
// 47499132420091324168 --> 47.49913242
// ----------------------------------------------
// 178345799086757990744 --> 178.3457

// 90517214611872146056 --> 90.5172