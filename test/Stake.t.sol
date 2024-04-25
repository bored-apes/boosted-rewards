// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Test, console } from "forge-std/Test.sol";
import { Stake } from "../src/contracts/Stake.sol";
import { Time } from "../src/libraries/Time.sol";

contract StakeTest is Test {
    Stake public stake;

    function setUp() public {
        stake = new Stake();
        deal(address(this), 100000000000000 ether);
    }

    function testFuzzStake_ValidInput_ReturnsTrue(uint256 amount) public {
        vm.assume(amount < address(this).balance);
        vm.assume(amount > 0);
        uint256 stakeDuration = Time.ONE_WEEK;
        bool success = stake.stake{value: amount}(0, stakeDuration);
        assert(success == true);
    }

    function testZero_Amount_ReturnsFalse() public {
        uint256 stakeDuration = Time.ONE_YEAR;
        vm.expectRevert('AMOUNT_SHOULD_BE_GREATER_THAN_ZERO');
        bool success = stake.stake{value: 0}(0, stakeDuration);
        assert(success == false);
    }

    function testUser_Already_Exists_ReturnsFalse() public {
        uint256 stakeDuration = Time.ONE_YEAR;
        bool success = stake.stake{value: 1 ether}(0, stakeDuration);
        assert(success == true);
        vm.expectRevert('USER_ALREADY_EXISTS');
        success = stake.stake{value: 2 ether}(0, stakeDuration);
        assert(success == false);
    }

}