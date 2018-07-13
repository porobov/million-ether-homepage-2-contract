pragma solidity ^0.4.18;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "openzeppelin-solidity/contracts/ownership/HasNoEther.sol";
import "openzeppelin-solidity/contracts/lifecycle/Destructible.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./MEH.sol";

contract MehModule is Ownable, Pausable, Destructible, HasNoEther {
    using SafeMath for uint256;

    MEH  meh;

    constructor(address _mehAddress) public {
        adminSetMeh(_mehAddress);
    }
    
    modifier onlyMeh() {
        require(msg.sender == address(meh));
        _;
    }

    function adminSetMeh(address _address) internal onlyOwner {
        MEH candidateContract = MEH(_address);
        require(candidateContract.isMEH());
        meh = candidateContract;
    }

    function transferFunds(address _payer, address _recipient, uint _amount) internal {
        return meh.operatorTransferFunds(_payer, _recipient, _amount);
    }

    function exists(uint16 _blockId) internal view  returns (bool) {
        return meh.exists(_blockId);
    }

    function ownerOf(uint16 _blockId) internal view returns (address) {
        return meh.ownerOf(_blockId);
    }
}