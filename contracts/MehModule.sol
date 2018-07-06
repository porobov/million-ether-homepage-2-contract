pragma solidity ^0.4.18;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/ownership/HasNoEther.sol";
import "openzeppelin-solidity/contracts/lifecycle/Destructible.sol";
import "openzeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "./MEH.sol";

contract MehModule is Ownable, Pausable, Destructible, HasNoEther {

    MEH  meh;
    RentalsInterface rentals;

    modifier onlyMeh() {
        require(msg.sender == address(meh));
        _;
    }

    function adminSetMeh(address _address) internal onlyOwner {
        MEH candidateContract = MEH(_address);
        require(candidateContract.isMEH());
        meh = candidateContract;
    }

    // warn: when upgrading rentals, pause everything and update ads.sol reference to rentals first
    function adminSetRentals(address _address) external onlyOwner { //whenPaused {    // TODO 
        // // TODO this.address is not rentals
        RentalsInterface candidateContract = RentalsInterface(_address);
        require(candidateContract.isRentals());
        rentals = candidateContract;
    }
}