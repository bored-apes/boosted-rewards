// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Multicall3 } from "../libraries/Multicall3.sol";
import { IStake } from "../interfaces/IStake.sol";
import { Time } from "../libraries/Time.sol";
import { Errors } from "../libraries/Errors.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "forge-std/console.sol";

contract Stake is Ownable, Multicall3, IStake, ReentrancyGuard {

    uint256 private _totalDeposit;
    uint256 private _total_claimed_tokens;
    address[] public accessors;
    Pool[] private _poolList;

    mapping(address => uint256) public balances;
    mapping(uint256 => mapping(address => User)) private _userInfo; // user info for perticular pool

    constructor() Ownable(msg.sender) {
        _poolList.push(Pool(Time.ONE_YEAR, 50000, Time.ONE_WEEK, 5));
        accessors.push(msg.sender);
    }

    modifier onlyAccessors() {
        require(_accessorContains(msg.sender), Errors.ACCESS_RESTRICTED);
        _;
    }

    receive() external payable {}

    /********************************************** STAKE & CLAIM ********************************************** */

    function stake(uint256 _pId, uint256 _stakeDuration) external payable override returns (bool) {
        require(msg.value > 0, Errors.AMOUNT_ZERO);
        require(_poolList.length != 0, Errors.POOL_NOT_CREATED);
        Pool storage _pool = _poolList[_pId];

        // check if alredy staked in this pool
        User storage _user = _userInfo[_pId][msg.sender];
        require(_user.capital == 0, Errors.USER_ALREADY_EXISTS);
        _user.capital = msg.value;
        _user.reward_booster = (_pool.max_booster * _stakeDuration)/_pool.duration;

        (uint256 rpy, uint256 rpd, uint256 rps) = _calcStakeReward(_user.capital, _pool.apr, _stakeDuration);

        _user.max_reward = rpy + (rpy*_user.reward_booster);
        _user.reward_per_day = rpd;
        _user.reward_per_second = rps;
        _user.checkpoint = block.timestamp;
        _user.endpoint = _stakeDuration + (block.timestamp);

        emit Stake(msg.sender, msg.value);

        return true;
    }

    function claim(uint256 _pId) public override returns (bool) {
        address account = msg.sender;

        User storage _user = _userInfo[_pId][account];
        require(!_user.isDisabled, Errors.USER_IS_DISABLED);

        Pool memory _pool = _poolList[_pId];

        (uint256 stake_claim_amount, uint256 total_time_passed) = checkClaimable(_pId, account);
        require(total_time_passed > _pool.claim_delay, Errors.NOT_CLAIMABLE_YET);

        uint256 current_claim = stake_claim_amount * _user.reward_booster;

        require(address(this).balance >= current_claim, Errors.LOW_BALANCE_IN_CONTRACT);

        payable(account).transfer(current_claim);
        _user.last_claimed_at = block.timestamp;
        _user.total_claimed += current_claim;
        _user.left_reward -= current_claim;
        emit Claim(account, current_claim);

        return true;
    }

    /********************************************** INFO & DATA (Helpers) ********************************************** */

    function poolInfo(uint256 index) public view returns (Pool memory pool) {
        return (_poolList[index]);
    }

    function userInfo(uint256 pId, address account) public view returns (User memory) {
        return _userInfo[pId][account];
    }

    function checkClaimable(uint256 _pId, address account) public view returns (uint256, uint256){
        User memory _user = _userInfo[_pId][account];
        Pool memory _pool = _poolList[_pId];
        uint256 total_time_passed = block.timestamp - _user.last_claimed_at;
        uint256 claimable_reward = total_time_passed * _user.reward_per_second;
        return (claimable_reward, total_time_passed);
    }

    function _calcStakeReward(uint256 _user_capital, uint256 _apr, uint256 _duration) private pure returns (uint256, uint256, uint256) {
        uint256 reward_per_year = _user_capital + (_apr*_user_capital)/100;
        uint256 reward_per_day = reward_per_year/_duration;
        uint256 reward_per_second = reward_per_day/24/60/60;
        return (reward_per_year, reward_per_day, reward_per_second);
    }

    /********************************************** ACCESSORS & OWNERS ********************************************** */

    function _accessorContains(address _acc) private view returns (bool) {
        for (uint256 i = 0; i < accessors.length; i++) {
            if (_acc == accessors[i]) {
                return true;
            }
        }
        return false;
    }

    function createPool(Pool calldata pooldatas) external onlyAccessors returns (bool) {
        _poolList.push(
            Pool(
                pooldatas.duration,
                pooldatas.apr,
                pooldatas.claim_delay,
                pooldatas.max_booster
            )
        );
        return true;
    }

    function updatePoolApr(uint256 _pId, uint256 apr) external onlyAccessors {
        Pool storage _pool = _poolList[_pId];
        _pool.apr = apr;
    }

    function updatePoolDuration(uint256 _pId, uint256 duration) external onlyAccessors {
        Pool storage _pool = _poolList[_pId];
        _pool.duration = duration;
    }

    function updateMaxBooster(uint256 _pId, uint256 booster) external onlyAccessors {
        Pool storage _pool = _poolList[_pId];
        _pool.max_booster = booster;
    }

    function updateClaimDelay(uint256 _pId, uint256 claimDelay) external onlyAccessors {
        Pool storage _pool = _poolList[_pId];
        _pool.claim_delay = claimDelay;
    }

    function addAccessors(address _acc) public onlyOwner returns (address[] memory) {
        accessors.push(_acc);
        return accessors;
    }

    function removeAccessor(uint256 index) public onlyOwner returns (address[] memory) {
        if (index >= accessors.length) revert(Errors.AOB); // array out of bounds

        accessors[index] = accessors[accessors.length - 1];
        accessors.pop();

        return accessors;
    }

    function claim(address token, uint256 amount) external onlyAccessors {
        if (token == address(0)) {
            require(address(this).balance >= amount, Errors.LOW_BALANCE_IN_CONTRACT);
            payable(msg.sender).transfer(amount);
        } else {
            require(IERC20(token).balanceOf(address(this)) >= amount, Errors.LOW_TOKEN);
            IERC20(token).transfer(msg.sender, amount);
        }
    }
}
