pragma solidity ^0.4.24;

import "../installed_contracts/math.sol";
import "./MEHAccessControl.sol";
// import "openzeppelin-solidity/contracts/math/SafeMath.sol";

contract Accounting is DSMath, MEHAccessControl {

    // Accounting
    mapping(address => uint) public balances;

// ** PAYMENT PROCESSING ** //

    function withdraw() external whenNotPaused {
        address payee = msg.sender;
        uint256 payment = balances[payee];

        require(payment != 0);
        assert(address(this).balance >= payment);

        balances[payee] = 0;

        payee.transfer(payment);
        // emit Withdrawn(_payee, payment);
    }

    function operatorTransferFunds(
        address _payer, 
        address _recipient, 
        uint _amount) 
    external 
    onlyBalanceOperators
    whenNotPaused
    {
        require(balances[_payer] >= _amount);
        _deductFrom(_payer, _amount);
        _depositTo(_recipient, _amount);
    }

    function depositFunds() internal whenNotPaused {
        _depositTo(msg.sender, msg.value);
        // emit deposit
    }

    function _depositTo(address _recipient, uint _amount) internal {
        balances[_recipient] = add(balances[_recipient], _amount);
    }

    function _deductFrom(address _payer, uint _amount) internal {
        balances[_payer] = sub(balances[_payer], _amount);
    }

// ** ADMIN ** //

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
}