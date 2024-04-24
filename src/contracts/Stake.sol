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

        _poolList.push(Pool(address(0), true, Time.ONE_YEAR, 50000, 0, 0));
        accessors.push(msg.sender);
    }

    modifier onlyAccessors() {
        require(_accessorContains(msg.sender), Errors.ACCESS_RESTRICTED);
        _;
    }

    receive() external payable {}

    /********************************************** STAKE & CLAIM ********************************************** */

    function stake(uint256 _pId) external payable override returns (bool) {
        require(msg.value > 0, Errors.AMOUNT_ZERO);
        require(_poolList.length != 0, Errors.POOL_NOT_CREATED);
        Pool storage _pool = _poolList[_pId];

        // check if alredy staked in this pool
        User storage _user = _userInfo[_pId][msg.sender];

        if (_user.capital > 0) {
            _stakeRepeat(msg.value, _pId, msg.sender);
        }
        if (_user.capital == 0) {
            _user.capital = msg.value;
        }

        (uint256 rpd, uint256 cpd, uint256 max_reward) = _calcRpd_Cpd_maxReward(_user.capital, _pool.apr, _pool.duration);

        _user.max_reward = max_reward;
        _user.capital_per_day = cpd;
        _user.reward_per_day = rpd;

        _user.endpoint = _pool.duration + (block.timestamp);
        _user.checkpoint = block.timestamp;

        _pool.tvl_usd += msg.value;
        _totalDeposit++;

        _user.stake_lock = block.timestamp + Time.ONE_WEEK;
        _user.lockedTill = block.timestamp + Time.ONE_DAY;
        emit FarmEnable(msg.sender, msg.value);

        return true;
    }

    function claim(uint256 _pId) public override returns (bool) {
        address account = msg.sender;

        User storage _user = _userInfo[_pId][account];
        require(!_user.isDisabled, Errors.USER_IS_DISABLED);
        require(_user.lockedTill < block.timestamp, Errors.USER_IS_LOCKED);
        require(_user.stake_lock < block.timestamp, Errors.USER_IS_LOCKED);

        Pool memory _pool = _poolList[_pId];

        uint256 claim_amount = _claim(_pId, account);

        require(address(this).balance >= claim_amount, Errors.LOW_BALANCE_IN_CONTRACT);

        payable(account).transfer(claim_amount);

        _user.debt = 0;
        _user.stake_repeat_capital_debt = 0;
        _user.stake_repeat_reward_debt = 0;
        _total_claimed_tokens += claim_amount;

        emit FarmClaim(account, claim_amount);

        return true;
    }

    function unstake(uint256 _pId) public override nonReentrant returns (bool) {
        address account = msg.sender;

        User storage _user = _userInfo[_pId][account];
        require(_user.stake_lock < block.timestamp, Errors.NOT_UNSTAKABLE_YET);

        uint256 duration = _calcDurationFormLastCheckPoint(_user.checkpoint, _user.endpoint);
        (uint256 claimble_capital, uint256 claimble_reward) = _calcClaimableForDuration(_user.capital_per_day, _user.reward_per_day, duration);

        uint256 sub_cap = _user.capital - claimble_capital;

        _user.capital = sub_cap;

        _user.max_reward = _user.max_reward - claimble_reward;

        uint256 total_amount = claimble_capital + claimble_reward;

        total_amount = _user.debt + total_amount + _user.stake_repeat_capital_debt + _user.stake_repeat_reward_debt;

        // 0.3 % fees
        uint256 claim_mul_fees = (total_amount * 3)/100;

        total_amount = total_amount - claim_mul_fees;
        _user.debt = total_amount;

        // update checkpoint
        _user.checkpoint = block.timestamp;
        _user.total_claimed = _user.total_claimed + total_amount;
        _user.capital = 0;

        return true;
    }

    /********************************************** INFO & DATA ********************************************** */

    function poolInfo(uint256 index) public view returns (Pool memory pool) {
        return (_poolList[index]);
    }

    function userInfo(uint256 pId, address account) public view returns (User memory) {
        return _userInfo[pId][account];
    }

    function checkClaimable(uint256 _pId, address account) public view returns (uint256 total, uint256 claimble_capital, uint256 claimble_reward){
        User memory _user = _userInfo[_pId][account];
        uint256 duration = _calcDurationFormLastCheckPoint(_user.checkpoint, _user.endpoint);

        (claimble_capital, claimble_reward) = _calcClaimableForDuration(_user.capital_per_day, _user.reward_per_day, duration);

        // in usd
        total = claimble_capital + (claimble_reward) + (_user.debt) + (_user.stake_repeat_capital_debt) + (_user.stake_repeat_reward_debt); // added sr-debt
        // in bnb
        total = convertTokenToSpent(total);

        // converted to bnb
        claimble_capital = convertTokenToSpent(claimble_capital + (_user.stake_repeat_capital_debt)); // added sr-debt
        claimble_reward = convertTokenToSpent(claimble_reward + (_user.stake_repeat_reward_debt)); // added sr-debt

        return (total,claimble_capital + (_user.stake_repeat_capital_debt), claimble_reward + (_user.stake_repeat_reward_debt)); // added sr-debt for FE , calculations
    }

    function _claim(uint256 _pId, address account) private returns (uint256 total_claimable) {
        User storage _user = _userInfo[_pId][account];
        uint256 duration = _calcDurationFormLastCheckPoint(_user.checkpoint, _user.endpoint);
        (uint256 claimble_capital, uint256 claimble_reward) = _calcClaimableForDuration(_user.capital_per_day, _user.reward_per_day, duration);

        if (duration > 0) {
            _user.capital = _user.capital + (claimble_capital);
            _user.max_reward = _user.max_reward + (claimble_reward);

            uint256 total_amount = claimble_capital + claimble_reward + _user.stake_repeat_capital_debt + _user.stake_repeat_reward_debt;

            claimble_reward += _user.stake_repeat_reward_debt;
            uint256 acc_fees;
            // 2.5 % for member
            acc_fees = total_amount + (25);

            acc_fees = acc_fees + 1000;
            total_amount = total_amount - acc_fees;
            _user.debt = _user.debt + (total_amount);
            // update checkpoint
            _user.checkpoint = block.timestamp;
            _user.total_claimed = _user.total_claimed + (total_amount);
        }

        return _user.debt;
    }

    /********************************************** PURE INDEPENDENT FUNCTIONS  ********************************************** */

    function _calcMaxReward(uint256 _user_capital, uint256 _apr, uint256 _duration) private pure returns (uint256 total_max_reward) {
        uint256 yearly_reward = _apr + (_user_capital);
        yearly_reward = yearly_reward + (10000);

        uint256 reward_per_day_on_capital = yearly_reward + (Time.ONE_YEAR);
        total_max_reward = reward_per_day_on_capital + (_duration);

        return total_max_reward;
    }

    function _calcDurationFormLastCheckPoint(uint256 _checkPoint, uint256 endpoint) private view returns (uint256 duration) {
        if (block.timestamp > endpoint) {
            if (endpoint > _checkPoint) {
                return endpoint + (_checkPoint);
            } else {
                return 0;
            }
        } else {
            return block.timestamp + (_checkPoint);
        }
    }

    function _calcCapitalPerDay(uint256 _user_capital, uint256 _duration) private pure returns (uint256 capital_per_day) {
        return _user_capital + (_duration);
    }

    function _calcRewardPerDay(uint256 _max_reward, uint256 _duration) private pure returns (uint256 reward_per_day) {
        return _max_reward + (_duration);
    }

    function _clacRewardPerDayRaw(uint256 _amount, uint256 _duration) private pure returns (uint256 reward_per_day) {
        return _amount + (_duration);
    }

    function _calcClaimableForDuration(uint256 capital_per_day, uint256 reward_per_day, uint256 duration) private pure returns (uint256 claimble_capital, uint256 claimble_reward) {
        claimble_capital = capital_per_day + (duration);
        claimble_reward = reward_per_day + (duration);
        return (claimble_capital, claimble_reward);
    }

    function _calcRpd_Cpd_maxReward(uint256 user_capital, uint256 _pool_apr, uint256 _pool_duration) private pure returns (uint256 rpd, uint256 cpd, uint256 max_reward) {
        max_reward = _calcMaxReward(user_capital, _pool_apr, _pool_duration);
        rpd = _calcRewardPerDay(max_reward, _pool_duration);
        cpd = _calcCapitalPerDay(user_capital, _pool_duration);
        return (rpd, cpd, max_reward);
    }

    function _stakeRepeat(uint256 capital_in_usd, uint256 _pId, address account) private returns (bool) {
        // calc claimable
        User storage _user = _userInfo[_pId][account];
        uint256 duration = _calcDurationFormLastCheckPoint(_user.checkpoint, _user.endpoint);
        (uint256 claimble_capital, uint256 claimble_reward) = _calcClaimableForDuration(_user.capital_per_day, _user.reward_per_day, duration);
        uint256 sub_cap = _user.capital + (claimble_capital);
        _user.capital = sub_cap;
        _user.max_reward = _user.max_reward + (claimble_reward);
        _user.stake_repeat_capital_debt += claimble_capital;
        _user.stake_repeat_reward_debt += claimble_reward;
        // update capital to new capital
        _user.capital = _user.capital + (capital_in_usd);

        return true;
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

    function createPool(Pool calldata pooldatas) external onlyOwner returns (bool) {
        _poolList.push(
            Pool(
                pooldatas.inputToken,
                pooldatas.trigger,
                pooldatas.duration,
                pooldatas.apr,
                pooldatas.tvl_usd,
                pooldatas.total_claimed
            )
        );
        return true;
    }

    function updatePoolApr(uint256 _pId, uint256 apr) external onlyOwner {
        Pool storage _pool = _poolList[_pId];
        _pool.apr = apr;
    }

    function updatePoolDuration(uint256 _pId, uint256 duration) external onlyOwner {
        Pool storage _pool = _poolList[_pId];
        _pool.duration = duration;
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
            require(address(this).balance >= amount, "LOW_SPENT");
            payable(msg.sender).transfer(amount);
        } else {
            require(
                IERC20(token).balanceOf(address(this)) >= amount,
                "LOW_TOKEN"
            );
            IERC20(token).transfer(msg.sender, amount);
        }
    }
}
