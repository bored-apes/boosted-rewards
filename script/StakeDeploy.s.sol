// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Script } from "forge-std/Script.sol";
import { Stake } from "../src/contracts/Stake.sol";
import { console } from "forge-std/console.sol";

contract StakeScript is Script {
    function run() external {
        vm.startBroadcast();

        Stake stake = new Stake();
        console.log("Contract Address : ", address(stake));
        console.log("Owner Address : ", msg.sender);

        vm.stopBroadcast();
    }
}
