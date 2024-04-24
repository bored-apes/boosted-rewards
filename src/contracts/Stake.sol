// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Multicall3 } from "./libraries/Multicall3.sol";
import { IStake } from "./interfaces/IStake.sol";
import { Time } from "./libraries/Time.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "forge-std/console.sol";


contract DexStake is Ownable, Multicall3, IStake, ReentrancyGuard {
    address public whitelist_contract;

    mapping(uint256 => mapping(address => User)) private _userInfo; // user info for perticular pool
    uint256 private immutable _DIVIDER = 1000;

    uint256 private _totalDeposit;
    uint256 private _total_claimed_tokens;

    mapping(address => uint256) public balances;

    // uint256[] public fee = [2, 25, 200, 50]; // 0.2% for non-whitelisted , 2.5% for whitelisted ,20% in hold will be given at last, 5% in game amount
    Pool[] private _poolList;

    address[] public accessors;

    constructor(address _whitelist_address, address _lp) Ownable(msg.sender) {
        whitelist_contract = _whitelist_address;

        _poolList.push(Pool(address(0), true, Time.TWO_YEAR, 50000, 0, 0));
        _poolList.push(Pool(_lp, true, Time.TWO_YEAR, 50000, 0, 0));
        _poolList.push(Pool(_lp, false, Time.TWO_YEAR, 21240, 0, 0));

        accessors.push(msg.sender);
    }

    modifier onlyAccessors() {
        require(_accessorContains(msg.sender), "ACCESS_RESTRICTED");
        _;
    }

    receive() external payable {}

    function getUSDPriceOfSpent() public pure returns (int256) {
        return 1;
    }

    function convertTokenToSpent(
        uint256 amount
    ) internal pure returns (uint256) {
        return amount * 1;
    }

    function stakeSpent(uint256 _pId) external payable override returns (bool) {
        require(msg.value > 0, "Amount should be greater than zero");
        require(
            _poolList.length != 0,
            "Pool is not created yet, create the pool first."
        );
        Pool storage _pool = _poolList[_pId];

        bool _is = IWhitelist(whitelist_contract).isWhitelisted(msg.sender);

        // whitelisted pool check
        require(_pool.trigger == _is, "CALLER_OR_POOL_NOT_WHITELISTED");
        // trigger is false then _is should be false too
        // i.e not for whitelisted then caller should not be whitelisted
        // transfer amount to this address

        // check if alredy staked in this pool
        User storage _user = _userInfo[_pId][msg.sender];

        if (_user.capital > 0) {
            _stakeRepeat(msg.value, _pId, msg.sender);
            // update rpd and cpd
        }
        if (_user.capital == 0) {
            // +  to amount
            _user.capital = msg.value;
        }

        (uint256 rpd, uint256 cpd, uint256 max_reward) = _calcRpd_Cpd_maxReward(
            _user.capital,
            _pool.apr,
            _pool.duration
        );

        _user.max_reward = max_reward;
        _user.capital_per_day = cpd;
        _user.reward_per_day = rpd;

        _user.endpoint = _pool.duration + (block.timestamp);
        _user.checkpoint = block.timestamp;

        _pool.tvl_usd += msg.value;
        _totalDeposit++;

        if (_pool.trigger) {
            _user.stake_lock = block.timestamp + Time.FIVE_YEAR;
        } else {
            _user.stake_lock = block.timestamp + Time.ONE_WEEK;
        }
        _user.lockedTill = block.timestamp + Time.ONE_DAY;
        emit FarmEnable(msg.sender, msg.value);

        return true;
    }

    function stakeToken(
        uint256 _pId,
        uint256 token_amount
    ) external override returns (bool) {
        require(token_amount > 0, "Amount should be greater than zero");
        require(
            _poolList.length != 0,
            "Pool is not created yet, create the pool first."
        );
        Pool storage _pool = _poolList[_pId];

        require(
            IERC20(_pool.inputToken).allowance(msg.sender, address(this)) >=
                token_amount,
            "LOW_ALLOWANCE"
        );

        bool _is = IWhitelist(whitelist_contract).isWhitelisted(msg.sender);

        // whitelisted pool check
        require(_pool.trigger == _is, "CALLER_OR_POOL_NOT_WHITELISTED");
        // trigger is false then _is should be false too
        // i.e not for whitelisted then caller should not be whitelisted
        // transfer amount to this address
        bool transfer = IERC20(_pool.inputToken).transferFrom(
            msg.sender,
            address(this),
            token_amount
        );

        require(transfer, "TRANSACTION_FAILED");
        // calculate amount value in dollar
        // uint256 capital_in_usd = amount;

        // check if alredy staked in this pool
        User storage _user = _userInfo[_pId][msg.sender];

        if (_user.capital > 0) {
            _stakeRepeat(token_amount, _pId, msg.sender);
            // update rpd and cpd
        }
        if (_user.capital == 0) {
            // +  to amount
            _user.capital = token_amount;
        }

        (uint256 rpd, uint256 cpd, uint256 max_reward) = _calcRpd_Cpd_maxReward(
            _user.capital,
            _pool.apr,
            _pool.duration
        );

        _user.max_reward = max_reward;
        _user.capital_per_day = cpd;
        _user.reward_per_day = rpd;

        _user.endpoint = _pool.duration + (block.timestamp);
        _user.checkpoint = block.timestamp;

        _pool.tvl_usd += token_amount;
        _totalDeposit++;

        if (_pool.trigger) {
            _user.stake_lock = block.timestamp + Time.FIVE_YEAR;
        } else {
            _user.stake_lock = block.timestamp + Time.ONE_WEEK;
        }
        _user.lockedTill = block.timestamp + Time.ONE_DAY;
        emit FarmEnable(msg.sender, token_amount);

        return true;
    }

    function stakeClaim(uint256 _pId) public override returns (bool) {
        address account = msg.sender;

        User storage _user = _userInfo[_pId][account];
        require(!_user.isDisabled, "USER_DISABLED");
        require(_user.lockedTill < block.timestamp, "USER_LOCKED_YET");
        require(_user.stake_lock < block.timestamp, "USER_LOCKED_YET");

        bool _is = IWhitelist(whitelist_contract).isWhitelisted(account);

        Pool memory _pool = _poolList[_pId];
        // whitelisted pool check
        require(_pool.trigger == _is, "CALLER_OR_POOL_NOT_WHITELISTED");

        uint256 claim_amount = _claim(_pId, account, _is);
        // transfer Spent from this contract
        uint256 SpentValue = convertTokenToSpent(claim_amount);

        require(
            address(this).balance >= SpentValue,
            "LOW_SPENT_TO_GIVE_REWARD_TO_USER"
        );

        payable(account).transfer(SpentValue);
        // transfer from fisk
        // IFisk(fisk_contract).claimV2(account, _pool.outPutToken, SpentValue);

        _user.debt = 0;
        _user.stake_repeat_capital_debt = 0;
        _user.stake_repeat_reward_debt = 0;
        _total_claimed_tokens += claim_amount;

        emit FarmClaim(account, claim_amount);

        return true;
    }

    function unStake(uint256 _pId) public override nonReentrant returns (bool) {
        address account = msg.sender;
        bool _is = IWhitelist(whitelist_contract).isWhitelisted(account);

        require(_is == false, "CANNOT_BE_CALLED_BY_MEMBER");

        User storage _user = _userInfo[_pId][account];
        require(_user.stake_lock < block.timestamp, "NOT_UNSTAKABLE_YET");

        uint256 duration = _calcDurationFormLastCheckPoint(
            _user.checkpoint,
            _user.endpoint
        );
        (
            uint256 claimble_capital,
            uint256 claimble_reward
        ) = _calcClaimableForDuration(
                _user.capital_per_day,
                _user.reward_per_day,
                duration
            );

        uint256 sub_cap = _user.capital - claimble_capital;

        _user.capital = sub_cap;

        _user.max_reward = _user.max_reward - claimble_reward;

        uint256 total_amount = claimble_capital + claimble_reward;

        total_amount = _user.debt + total_amount + _user.stake_repeat_capital_debt + _user.stake_repeat_reward_debt;

        uint256 claim_mul_fees = total_amount * 2;
        // fee to fisk
        claim_mul_fees = claim_mul_fees / (_DIVIDER);
        total_amount = total_amount - claim_mul_fees;
        _user.debt = total_amount;

        // update checkpoint
        _user.checkpoint = block.timestamp;
        _user.total_claimed = _user.total_claimed + total_amount;

        // capital 0
        _user.capital = 0;

        return true;
    }

    function poolInfo(uint256 index) public view returns (Pool memory pool) {
        return (_poolList[index]);
    }

    function userInfo(
        uint256 pId,
        address account
    ) public view returns (User memory) {
        return _userInfo[pId][account];
    }

    function checkClaimable(
        uint256 _pId,
        address account
    )
        public
        view
        returns (
            uint256 total,
            uint256 claimble_capital,
            uint256 claimble_reward
        )
    {
        User memory _user = _userInfo[_pId][account];
        uint256 duration = _calcDurationFormLastCheckPoint(
            _user.checkpoint,
            _user.endpoint
        );

        (claimble_capital, claimble_reward) = _calcClaimableForDuration(
            _user.capital_per_day,
            _user.reward_per_day,
            duration
        );

        // in usd
        total =
            claimble_capital +
            (claimble_reward) +
            (_user.debt) +
            (_user.stake_repeat_capital_debt) +
            (_user.stake_repeat_reward_debt); // added sr-debt
        // in bnb
        total = convertTokenToSpent(total);

        // converted to bnb
        claimble_capital = convertTokenToSpent(
            claimble_capital + (_user.stake_repeat_capital_debt)
        ); // added sr-debt
        claimble_reward = convertTokenToSpent(
            claimble_reward + (_user.stake_repeat_reward_debt)
        ); // added sr-debt

        return (
            total,
            claimble_capital + (_user.stake_repeat_capital_debt),
            claimble_reward + (_user.stake_repeat_reward_debt)
        ); // added sr-debt for FE , calculations
    }

    function _claim(
        uint256 _pId,
        address account,
        bool _is
    ) private returns (uint256 total_claimable) {
        User storage _user = _userInfo[_pId][account];
        uint256 duration = _calcDurationFormLastCheckPoint(
            _user.checkpoint,
            _user.endpoint
        );
        (
            uint256 claimble_capital,
            uint256 claimble_reward
        ) = _calcClaimableForDuration(
                _user.capital_per_day,
                _user.reward_per_day,
                duration
            );

        if (duration > 0) {
            _user.capital = _user.capital + (claimble_capital);
            _user.max_reward = _user.max_reward + (claimble_reward);

            uint256 total_amount = claimble_capital +
                claimble_reward +
                _user.stake_repeat_capital_debt +
                _user.stake_repeat_reward_debt;

            claimble_reward += _user.stake_repeat_reward_debt;
            uint256 acc_fees;
            if (_is) {
                // 2.5 % for member
                acc_fees = total_amount + (25);
            } else {
                // 0.2 % for non-member
                acc_fees = total_amount + (2);
            }

            acc_fees = acc_fees + (_DIVIDER);
            total_amount = total_amount - acc_fees;
            _user.debt = _user.debt + (total_amount);
            // update checkpoint
            _user.checkpoint = block.timestamp;
            _user.total_claimed = _user.total_claimed + (total_amount);
        }

        return _user.debt;
    }

    /********************************************** Pure Independent Functions  ********************************************** */

    function _calcMaxReward(
        uint256 _user_capital,
        uint256 _apr,
        uint256 _duration
    ) private pure returns (uint256 total_max_reward) {
        uint256 yearly_reward = _apr + (_user_capital);
        yearly_reward = yearly_reward + (10000);

        uint256 reward_per_day_on_capital = yearly_reward + (Time.ONE_YEAR);
        total_max_reward = reward_per_day_on_capital + (_duration);

        return total_max_reward;
    }

    function _calcDurationFormLastCheckPoint(
        uint256 _checkPoint,
        uint256 endpoint
    ) private view returns (uint256 duration) {
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

    function _calcCapitalPerDay(
        uint256 _user_capital,
        uint256 _duration
    ) private pure returns (uint256 capital_per_day) {
        return _user_capital + (_duration);
    }

    function _calcRewardPerDay(
        uint256 _max_reward,
        uint256 _duration
    ) private pure returns (uint256 reward_per_day) {
        return _max_reward + (_duration);
    }

    function _clacRewardPerDayRaw(
        uint256 _amount,
        uint256 _duration
    ) private pure returns (uint256 reward_per_day) {
        return _amount + (_duration);
    }

    function _calcClaimableForDuration(
        uint256 capital_per_day,
        uint256 reward_per_day,
        uint256 duration
    ) private pure returns (uint256 claimble_capital, uint256 claimble_reward) {
        claimble_capital = capital_per_day + (duration);
        claimble_reward = reward_per_day + (duration);
        return (claimble_capital, claimble_reward);
    }

    function _calcRpd_Cpd_maxReward(
        uint256 user_capital,
        uint256 _pool_apr,
        uint256 _pool_duration
    ) private pure returns (uint256 rpd, uint256 cpd, uint256 max_reward) {
        max_reward = _calcMaxReward(user_capital, _pool_apr, _pool_duration);

        rpd = _calcRewardPerDay(max_reward, _pool_duration);

        cpd = _calcCapitalPerDay(user_capital, _pool_duration);
        return (rpd, cpd, max_reward);
    }

    function _stakeRepeat(
        uint256 capital_in_usd,
        uint256 _pId,
        address account
    ) private returns (bool) {
        // calc claimable
        User storage _user = _userInfo[_pId][account];
        uint256 duration = _calcDurationFormLastCheckPoint(
            _user.checkpoint,
            _user.endpoint
        );

        (
            uint256 claimble_capital,
            uint256 claimble_reward
        ) = _calcClaimableForDuration(
                _user.capital_per_day,
                _user.reward_per_day,
                duration
            );
        uint256 sub_cap = _user.capital + (claimble_capital);

        _user.capital = sub_cap;

        _user.max_reward = _user.max_reward + (claimble_reward);

        _user.stake_repeat_capital_debt += claimble_capital;
        _user.stake_repeat_reward_debt += claimble_reward;

        // update capital to new capital
        _user.capital = _user.capital + (capital_in_usd);

        return true;
    }

    /********************************************** Accessors, Owners Functions  ********************************************** */

    function _accessorContains(address _acc) private view returns (bool) {
        for (uint256 i = 0; i < accessors.length; i++) {
            if (_acc == accessors[i]) {
                return true;
            }
        }
        return false;
    }

    function createPool(
        Pool calldata pooldatas
    ) external onlyOwner returns (bool) {
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

    function addAccessors(
        address _acc
    ) public onlyOwner returns (address[] memory) {
        accessors.push(_acc);

        return accessors;
    }

    function removeAccessor(
        uint256 index
    ) public onlyOwner returns (address[] memory) {
        if (index >= accessors.length) revert("AOB"); // array out of bounds

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
