// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Script } from "forge-std/Script.sol";
import { Stake } from "../src/contracts/Stake.sol";
import { console } from "forge-std/console.sol";

contract StakeScript is Script {
    function run() external {
        vm.startBroadcast();

        // Stake stake = Stake(payable(0xd01C3c488F54c918A0765C36Be4B9ce572b7647d));

        vm.stopBroadcast();
    }
}
