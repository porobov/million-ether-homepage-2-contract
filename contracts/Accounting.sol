pragma solidity ^0.4.24;

// import "../installed_contracts/math.sol";
import "./MEHAccessControl.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

// @title Accounting: Part of MEH contract responsible for eth accounting.
contract Accounting is MEHAccessControl {
    using SafeMath for uint256;

    // Balances of users, admin, charity
    mapping(address => uint256) public balances;

    // Emitted when a user deposits or withdraws funds from the contract
    event LogContractBalance(address payerOrPayee, int balanceChange);

// ** PAYMENT PROCESSING ** //
    
    /// @dev Withdraws users available balance.
    function withdraw() external whenNotPaused {
        address payee = msg.sender;
        uint256 payment = balances[payee];

        require(payment != 0);
        assert(address(this).balance >= payment);

        balances[payee] = 0;

        // reentrancy safe
        payee.transfer(payment);
        emit LogContractBalance(payee, int256(-payment));
    }

    /// @dev Lets external authorized contract (operators) to transfer balances within MEH contract.
    ///  MEH contract doesn't transfer funds on its own. Instead Market and Rentals contracts
    ///  are granted operator access.
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

    /// @dev Deposits eth to msg.sender balance.
    function depositFunds() internal whenNotPaused {
        _depositTo(msg.sender, msg.value);
        emit LogContractBalance(msg.sender, int256(msg.value));
    }

    /// @dev Increases recipients internal balance.
    function _depositTo(address _recipient, uint _amount) internal {
        balances[_recipient] = balances[_recipient].add(_amount);
    }

    /// @dev Increases payers internal balance.
    function _deductFrom(address _payer, uint _amount) internal {
        balances[_payer] = balances[_payer].sub(_amount);
    }

// ** ADMIN ** //

    /// @notice Allows admin to withdraw contract balance in emergency. And distribute manualy
    ///  aftrewards.
    /// @dev As the contract is not designed to keep users funds (users can withdraw
    ///  at anytime) it should be relatively easy to manualy transfer unclaimed funds to 
    ///  their owners. This is an alternatinve to selfdestruct allowing blocks ledger (ERC721 tokens)
    ///  to be immutable.
    function adminRescueFunds() external onlyOwner whenPaused {
        address payee = owner;
        uint256 payment = address(this).balance;
        payee.transfer(payment);
    }

    /// @dev Checks if a msg.sender has enough balance to pay the price needed.
    function canPay(uint needed) internal view returns (bool) {
        return (msg.value.add(balances[msg.sender]) >= needed);
    }
}