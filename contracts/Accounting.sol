pragma solidity ^0.4.24;

import "../installed_contracts/math.sol";
import "./MEHAccessControl.sol";

contract Accounting is DSMath, MEHAccessControl {

    // Accounting
    mapping(address => uint) public balances;

// ** PAYMENT PROCESSING ** //

    function _depositTo(address _recipient, uint _amount) internal {
        // require(a.balanceETH >= _value);
        // require(_to != address(0));
        balances[_recipient] = add(balances[_recipient], _amount);
    }

    function _deductFrom(address _payer, uint _amount) internal {
        balances[_payer] = sub(balances[_payer], _amount);
    }

    function withdraw() external whenNotPaused {
        address payee = msg.sender;
        uint256 payment = balances[payee];

        require(payment != 0);
        require(address(this).balance >= payment);

        balances[payee] = 0;

        assert(payee.send(payment));
    }

    // ** ACCOUNTING ** //

    function operatorDepositTo(address _recipient, uint _amount) external onlyBalanceOperators whenNotPaused {
        _depositTo(_recipient, _amount);
    }

    function operatorDeductFrom(address _payer, uint _amount) external onlyBalanceOperators whenNotPaused {
        _deductFrom(_payer, _amount);
    }

    //TODO function saveTheMoney whenPaused
    /// @dev withdraw contract balance
    /// @notice To be called in emergency. As the contract is not designed to keep users funds
    ///  (users can withdraw at anytime) it should be relatively easy to manualy 
    ///  transfer unclaimed funds to their owners. This is an alternatinve to selfdestruct
    ///  to make blocks ledger immutable.
    function adminRescueFunds() external onlyOwner whenPaused {
        address payee = owner;
        uint256 payment = address(this).balance;
        assert(payee.send(payment));
    }

    function canPay(uint needed) internal view returns (bool) {
        return (msg.value + balances[msg.sender] >= needed);  // TODO safe math
    }

        // https://github.com/seedom-io/seedom-solidity/blob/574e52349755ec9e28111c3a182638e73d4eb635/contract/fundraiser.sol#L482
        // recover() allows the owner to recover ERC20 tokens sent to this contract, for later
    // distribution back to their original holders, upon request
    // function recover(address _token) public onlyOwner {
    //     ERC20 _erc20 = ERC20(_token);
    //     uint256 _balance = _erc20.balanceOf(this);
    //     require(_erc20.transfer(deployment._owner, _balance));
    // }

}