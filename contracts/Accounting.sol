pragma solidity ^0.4.24;

import "../installed_contracts/math.sol";
import "./MEHAccessControl.sol";

contract Accounting is DSMath, MEHAccessControl {

    // Accounting
    mapping(address => uint) public balances;

// ** PAYMENT PROCESSING ** //

    function _depositTo(address _recipient, uint _amount) internal {
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
    ///  (funds not locked, withdraw at anytime) it should be relatively easy to manualy 
    ///  transfer unclaimed funds to their owners. This is an alternatinve to selfdestruct
    ///  to make blocks ledger immutable.
    function adminSaveFunds() external onlyOwner whenPaused {
        // require(address(market) == )
        address payee = msg.sender;
        uint256 payment = address(this).balance;
        assert(payee.send(payment));
    }

}