pragma solidity ^0.4.24;    

import "../Rentals.sol";

/// Not for production. Functionality added for testing and cleanup purposes only. 
contract RentalsDisposable is Rentals {
    constructor(address _mehAddress) Rentals(_mehAddress) {}
    
    function fastforwardRent(uint16 _blockId) public {
        uint numberOfPeriods = blockIdToRentDeal[_blockId].numberOfPeriods;
        uint expiredRentedFrom = now - rentPeriod * numberOfPeriods -1;
        blockIdToRentDeal[_blockId].rentedFrom = expiredRentedFrom;
    }
}