pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "openzeppelin-solidity/contracts/ownership/HasNoEther.sol";
import "openzeppelin-solidity/contracts/lifecycle/Destructible.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./MEH.sol";

/// @title MehModule: Base contract for MEH modules (Market, Rentals and Ads contracts). Provides
///  communication with MEH contract. 
contract MehModule is Ownable, Pausable, Destructible, HasNoEther {
    using SafeMath for uint256;

    // Main MEH contract
    MEH public meh;

    /// @dev Initializes a module, pairs with MEH contract.
    /// @param _mehAddress address of the main Million Ether Homepage contract
    constructor(address _mehAddress) public {
        adminSetMeh(_mehAddress);
    }
    
    /// @dev Throws if called by any address other than the MEH contract.
    modifier onlyMeh() {
        require(msg.sender == address(meh));
        _;
    }

    /// @dev Pairs a module with MEH main contract.
    function adminSetMeh(address _address) internal onlyOwner {
        MEH candidateContract = MEH(_address);
        require(candidateContract.isMEH());
        meh = candidateContract;
    }

    /// @dev Makes an internal transaction in the MEH contract.
    function transferFunds(address _payer, address _recipient, uint _amount) internal {
        return meh.operatorTransferFunds(_payer, _recipient, _amount);
    }

    /// @dev Check if a token exists.
    function exists(uint16 _blockId) internal view  returns (bool) {
        return meh.exists(_blockId);
    }

    /// @dev Querries an owner of a block id (ERC721 token).
    function ownerOf(uint16 _blockId) internal view returns (address) {
        return meh.ownerOf(_blockId);
    }
}