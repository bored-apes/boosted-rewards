// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStake {

  event Stake(address from, uint256 amount);
  event Claim(address account, uint256 amount);

  struct Pool {
    uint256 duration;
    uint256 apr;
    uint256 claim_delay;
    uint256 max_booster;
  }
  struct User {
    uint256 startpoint; // in timestamp
    uint256 checkpoint; // check point in timestamp
    uint256 endpoint; // end of this / latest deposit reward duration
    uint256 duration; // in timestamp
    uint256 reward_booster;
    uint256 capital; 
    uint256 max_reward;
    uint256 reward_per_day;
    uint256 reward_per_second;
    uint256 total_claimed;
    uint256 left_reward;
    bool isDisabled;
  }

  function stake(uint256 _pId, uint256 _stakeDuration) external payable returns (bool);
  function claim(uint256 _pId) external returns (bool);

}
