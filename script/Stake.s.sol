// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Script } from "forge-std/Script.sol";
import { Stake } from "../src/contracts/Stake.sol";
import { console } from "forge-std/console.sol";
import { Time } from "../src/libraries/Time.sol";
import { IStake } from "../src/interfaces/IStake.sol";

contract StakeScript is Script {
    function run() external {
        vm.startBroadcast();

        Stake stake = Stake(payable(0xFF05395dC2855Fb13aA962DD52e377F2c79633F4));
        // payable(stake).transfer(1 ether);

        // stake.createPool(IStake.Pool(Time.ONE_YEAR, 50000, Time.ONE_WEEK, 5000));
        // stake.updateClaimDelay(0, Time.ONE_WEEK);
        // stake.updateMaxBooster(0, 6000);
        // stake.updatePoolApr(0, 55000);
        // stake.updatePoolDuration(0, Time.TWO_YEAR);
        // stake.stake{value : 10**16}(0, Time.ONE_DAY * 300);
        // stake.checkClaimable(0, msg.sender);
        // stake.userInfo(0, msg.sender);
        // stake.poolInfo(0);
        // stake.claim(0);
        // stake.checkClaimable(0, msg.sender);
        // stake.addAccessors(0x3bC5d0827b6b80243c8970a3760DFec9b491b3e2);
        // stake.removeAccessor(1);
        // stake.drain(address(0), address(stake).balance);
        
        vm.stopBroadcast();
    }
}
// 