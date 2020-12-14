pragma solidity ^0.6.0;

import '@openzeppelin/contracts-ethereum-package/contracts/utils/Address.sol';
import '@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol';
import '@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol';
import '@openzeppelin/contracts-ethereum-package/contracts/GSN/Context.sol';
import '@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol';


/**
 * @title StakingWallet
 */
contract StakingWallet is Initializable, ContextUpgradeSafe, OwnableUpgradeSafe {
    using SafeMath for uint256;
    using Address for address;

    event Staked(address beneficiary, uint256 index, uint256 amount);
    event Released(address beneficiary, uint256 index, uint256 amount);
    event DailyBonused(address beneficiary, uint256 index, uint256 amount);

    struct StakingBalance {
        uint256 id;
        uint256 amount;
        uint256 bonusAmount;
        uint256 startDate;
        uint256 endDate;
        uint256 releaseDurationInDays;
        uint256 lastReleaseDate;
        uint256 totalBonusReleased;
        bool isExist;
    }

    uint256 internal totalStakingBalance;
    mapping(address => StakingBalance[]) internal stakingBalances;
    uint256 internal sequenceId;

    function __StakingWallet_init() internal initializer {
        __Context_init_unchained();
        __StakingWallet_init_unchained();
    }

    function __StakingWallet_init_unchained() internal initializer {
        __Ownable_init_unchained();
    }

    function totalStaking(address _user) public view returns(uint256 total) {
        total = totalStakingBalance;
    }

    function countStakingBalance(address _user) public view returns(uint256 count) {
        count = stakingBalances[_user].length;
    }
  
    function stakingBalanceInfo(address _user, uint256 _index) public view returns(
        uint256 id,
        uint256 amount,
        uint256 bonusAmount,
        uint256 startDate,
        uint256 endDate,
        uint256 releaseDurationInDays,
        uint256 lastReleaseDate,
        uint256 totalBonusReleased) {
        id = stakingBalances[_user][_index].id;
        amount = stakingBalances[_user][_index].amount;
        bonusAmount = stakingBalances[_user][_index].bonusAmount;
        startDate = stakingBalances[_user][_index].startDate;
        endDate = stakingBalances[_user][_index].endDate;
        releaseDurationInDays = stakingBalances[_user][_index].releaseDurationInDays;
        lastReleaseDate = stakingBalances[_user][_index].lastReleaseDate;
        totalBonusReleased = stakingBalances[_user][_index].totalBonusReleased;
    }

    function staking(address _beneficiary, uint256 _amount, uint256 _bonus, uint256 _durationDays) public onlyOwner {
        require(_beneficiary != address(0), 'invalid beneficiary address');
        require(_amount > 0, 'staking amount should be greater than zero');
        require(_bonus > 0, 'bonus amount should be greater than zero');

        _stakingBalance(_beneficiary, _amount);
        totalStakingBalance = totalStakingBalance.add(_amount);
        sequenceId = sequenceId.add(1);
        stakingBalances[_beneficiary].push(StakingBalance(sequenceId, _amount, _bonus, now, now.add(_durationDays.mul(86400)), _durationDays, now, 0, true));
        emit Staked(_beneficiary, stakingBalances[_beneficiary].length - 1, _amount);
    }
  
    function release(address _beneficiary, uint256 _index) public onlyOwner {
        require(_beneficiary != address(0), 'invalid beneficiary address');
        require(stakingBalances[_beneficiary][_index].isExist, 'beneficiary has no staking balance');
        require(stakingBalances[_beneficiary][_index].endDate <= now, 'still on staking period');
        
        //check bonus
        if (stakingBalances[_beneficiary][_index].bonusAmount > stakingBalances[_beneficiary][_index].totalBonusReleased) {
            _transferBonus(_beneficiary, stakingBalances[_beneficiary][_index].bonusAmount.sub(stakingBalances[_beneficiary][_index].totalBonusReleased));
        }

        uint256 balanceReleased = stakingBalances[_beneficiary][_index].amount;
        _releaseStakingBalance(_beneficiary, balanceReleased);
        for(uint256 index = _index; index < stakingBalances[_beneficiary].length; index++) {
            if (index >= stakingBalances[_beneficiary].length - 1) {
                delete stakingBalances[_beneficiary][index];
            } else {
                stakingBalances[_beneficiary][index] = stakingBalances[_beneficiary][index + 1];
            }
        }
        emit Released(_beneficiary, _index, balanceReleased);
    }
  

    function dailybonus(address _beneficiary, uint256 _index) public onlyOwner {
        require(_beneficiary != address(0), 'invalid beneficiary address');
        require(stakingBalances[_beneficiary][_index].isExist, 'beneficiary has no staking balance');
        require(stakingBalances[_beneficiary][_index].totalBonusReleased 
                    < stakingBalances[_beneficiary][_index].bonusAmount, 'user has no bonus');

        uint256 dailyBonusAmount = calculateDailyBonus(_beneficiary, _index, now);

        if (now >= stakingBalances[_beneficiary][_index].endDate) {
            dailyBonusAmount = stakingBalances[_beneficiary][_index].bonusAmount
                .sub(stakingBalances[_beneficiary][_index].totalBonusReleased);
        }

        _transferBonus(_beneficiary, dailyBonusAmount);
        stakingBalances[_beneficiary][_index].lastReleaseDate = now;
        stakingBalances[_beneficiary][_index].totalBonusReleased = stakingBalances[_beneficiary][_index].totalBonusReleased.add(dailyBonusAmount);
        emit DailyBonused(_beneficiary, _index, dailyBonusAmount);
    }

    function calculateDailyBonus(address _beneficiary, uint256 _index, uint256 dateReleased) view public returns (uint256) {
        uint256 dailyBonusAmount = stakingBalances[_beneficiary][_index].bonusAmount
            .div(stakingBalances[_beneficiary][_index].releaseDurationInDays);
        uint256 day = uint(dateReleased.sub(stakingBalances[_beneficiary][_index].lastReleaseDate).div(86400));
        return dailyBonusAmount.mul(day);
    }

    function _stakingBalance(address _payer, uint256 _amount) internal virtual { }
    function _releaseStakingBalance(address _beneficiary, uint256 _amount) internal virtual { }
    function _transferBonus(address _beneficiary, uint256 _amount) internal virtual { }


    uint256[49] private __gap;
}

contract SampleToken is Initializable, ContextUpgradeSafe, OwnableUpgradeSafe, ERC20UpgradeSafe, StakingWallet {
    using SafeMath for uint256;
    using Address for address;

    address public walletBonus;
    address public oldContract;

    //config
    uint256 private _cap;
    uint256 private _feeNumerator;
    uint256 private _feeDenominator;

    mapping(address => bool) internal isBalancesMigrated;

    /**
     * @dev Sets the value of the `cap`. This value is immutable, it can only be
     * set once during construction.
     */

    function __SampleToken_init(uint256 cap) public initializer {
        __Context_init_unchained();
        __ERC20_init_unchained('Samplecoin', 'Sample');
        __Ownable_init_unchained();
        __StakingWallet_init_unchained();
        __SampleToken_init_unchained(cap);
    }

    function __SampleToken_init_unchained(uint256 cap) internal initializer {

        require(cap > 0, "SampleToken: cap is 0");
        _cap = cap;
        _mint(_msgSender(), _cap);
    }


    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view returns (uint256) {
        return _cap;
    }

    /**
     * @dev Returns the feePercentage for transferFrom.
     */
    function fee() public view returns (uint256 feeNumerator, uint256 feeDenominator) {
        return (_feeNumerator, _feeDenominator);
    }

    /**
     * @dev Setter function for feePercentage.
     */
    function setFee(uint256 feeNumerator, uint256 feeDenominator) public onlyOwner returns (uint256, uint256) {
        _feeNumerator = feeNumerator;
        _feeDenominator = feeDenominator;
        return (_feeNumerator, _feeDenominator);
    }

    function _balanceOf(address account) internal view override returns (uint256) {
        if (isBalancesMigrated[account] || account == owner()) {
            return _balances[account];
        }
        return IERC20(oldContract).balanceOf(account);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        //Migrating balance sender from old contract
        if (!isBalancesMigrated[sender] && sender != owner()
                && sender != address(this)) {
            _balances[sender] = balanceOf(sender);
            _balances[owner()] = _balances[owner()].sub(balanceOf(sender));
            isBalancesMigrated[sender] = true;
        }

        //Migrating balance recipient from old contract
        if (!isBalancesMigrated[recipient] && recipient != owner()
                && sender != address(this)) {
            _balances[recipient] = balanceOf(recipient);
            _balances[owner()] = _balances[owner()].sub(balanceOf(recipient));
            isBalancesMigrated[recipient] = true;
        }

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /**
     * @dev special tranfer only owner can trigger this function
     */
    function sampleTransfer(address sender, address recipient, uint256 amount, uint256 fee) public onlyOwner returns (bool) {
        require(_feeReceiver != address(0), 'fee receiver address not registed');
        _beforeTokenTransfer(sender, recipient, amount.add(fee));
        _transfer(sender, recipient, amount);
        if (fee > 0) {
            _transfer(sender, _feeReceiver, fee);
        }
        return true;
    }

    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - check if balance of sender is sufficient for transfer
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        
        if (from != address(0)) { // When minting tokens
            require(balanceOf(from) >= amount, "SampleToken: insufficient sender balance");
        }
    }

    function setWalletBonus(address _walletBonus) public onlyOwner {
        walletBonus = _walletBonus;
    }

    function setOldContract(address _oldContract) public onlyOwner {
        oldContract = _oldContract;
    }

    function _stakingBalance(address _beneficiary, uint256 _amount) internal override { 
        _transfer(owner(), address(this), _amount);
    }

    function _releaseStakingBalance(address _beneficiary, uint256 _amount) internal override { 
        _transfer(address(this), _beneficiary, _amount);
    }

    function _transferBonus(address _beneficiary, uint256 _amount) internal override { 
        _transfer(walletBonus, _beneficiary, _amount);
    }

    function setName(string memory name) public onlyOwner {
        _setName(name);
    }

    function setFeeReceiver(address feeReceiver) public onlyOwner {
        _feeReceiver = feeReceiver;
        emit UpdateFeeReceiver(_feeReceiver);
    }

    uint256[49] private __gap;
    address private _feeReceiver;
    event UpdateFeeReceiver(address feeReceiver);
}