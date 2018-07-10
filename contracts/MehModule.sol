pragma solidity ^0.4.18;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/ownership/HasNoEther.sol";
import "openzeppelin-solidity/contracts/lifecycle/Destructible.sol";
import "openzeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "./MEH.sol";

contract MehModule is Ownable, Pausable, Destructible, HasNoEther {

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
}