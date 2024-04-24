// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStake {

  event FarmEnable(address from, uint256 amountLp);
  event FarmClaim(address account, uint256 amount);
  event DirectAmount(address account, address ref, uint256 direct_amount, uint256 total_amount);
  event DirectClaim(address account, uint256 fee_amount, uint256 final_amount);

  struct Pool {
    address inputToken;
    bool trigger;
    uint256 duration;
    uint256 apr;
    uint256 tvl_usd;
    uint256 total_claimed;
  }
  struct User {
    uint256 checkpoint; // check point in timestamp
    uint256 endpoint; // end of this / latest depoist reward duration
    uint256 capital; // usd amout of asset
    uint256 debt;
    uint256 lockedTill;
    uint256 capital_per_day;
    uint256 max_reward;
    uint256 reward_per_day;
    uint256 total_claimed;
    uint256 hold;
    uint256 stake_repeat_capital_debt;
    uint256 stake_repeat_reward_debt;
    uint256 stake_lock;
    bool isDisabled;
  }

  function stake(uint256 _pId) external payable returns (bool);
  function claim(uint256 _pId) external returns (bool);
  function unstake(uint256 _pId) external returns (bool);

}
