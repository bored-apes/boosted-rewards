// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Test, console2 } from "forge-std/Test.sol";
import { Stake } from "../src/contracts/Stake.sol";
import { Time } from "../src/libraries/Time.sol";
import { Errors } from "../src/libraries/Errors.sol";

contract StakeTest is Test {
    Stake public stake;

    function setUp() public {
        stake = new Stake();
        deal(address(this), 1000 ether);
        address bob = makeAddr('bob');
    }

    function testFuzzStake_ValidInput_ReturnsTrue(uint256 amount, uint256 stakeDuration) public {
        vm.assume(amount < address(this).balance);
        vm.assume(amount > 0);
        vm.assume(stakeDuration > 0);
        vm.assume(stakeDuration < Time.ONE_YEAR);
        bool success = stake.stake{value: amount}(0, stakeDuration);
        assert(success == true);

    }

    function testZero_Amount_ReturnsFalse() public {
        uint256 stakeDuration = Time.ONE_YEAR;
        uint256 poolId = 0;
        vm.expectRevert('AMOUNT_SHOULD_BE_GREATER_THAN_ZERO');
        // vm.expectRevert(Errors.AMOUNT_ZERO);
        bool success = stake.stake{value: 0}(poolId, stakeDuration);
        assert(success == false);
    }

    function testUser_Already_Exists_ReturnsFalse() public {
        uint256 stakeDuration = Time.ONE_YEAR;
        uint256 poolId = 0;
        bool success = stake.stake{value: 1 ether}(poolId, stakeDuration);
        assert(success == true);
        vm.expectRevert('USER_ALREADY_EXISTS');
        success = stake.stake{value: 2 ether}(poolId, stakeDuration);
        assert(success == false);
    }

    function testClaim_BeforeClaimDelay_ReturnsFalse() public {
        uint256 stakeDuration = Time.ONE_WEEK;
        uint256 poolId = 0;
        bool success = stake.stake{value: 1 ether}(poolId, stakeDuration);
        assert(success == true);
        vm.warp(block.timestamp + Time.ONE_DAY); // Move time forward by 1 day
        vm.expectRevert('NOT_CLAIMABLE_YET');
        success = stake.claim(poolId);
        assert(success == false);
    }
    
    function test_AddAccessor_NonOwner_Reverts() public {
        vm.prank(address(4));
        vm.expectRevert();
        stake.addAccessors(address(5)); 
    }


    // function testClaimNativeCoin_Owner_ClaimsNativeCoin(uint256 amount) public {
    //     deal(address(stake), 1000 ether);
    //     vm.assume(amount > 1 ether);
    //     vm.assume(amount < address(stake).balance);
    //     uint256 initialBalance = address(stake).balance;
    //     stake.claim(address(0), amount); // address(0) represents native coin
    //     assertGe(address(stake).balance, initialBalance);
    // }

    function testClaim_InsufficientFunds_Reverts(uint256 amount) public {
        vm.assume(amount > 0);
        vm.assume(amount < 1000000000 ether);
        vm.expectRevert('LOW_BALANCE_IN_CONTRACT'); // Or Errors.LOW_TOKEN depending on tokenAddress
        stake.claim(address(0), amount);
    }

}