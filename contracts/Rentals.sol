pragma solidity ^0.4.24;    

import "./MehModule.sol";

contract Rentals is MehModule {
    
    bool public isRentals = true;

    // deafauls
    /// @notice Nobidy can cancel rent untill rent period is over
    uint public rentPeriod = 1 days;  // and thus min rent period
    uint public maxRentPeriod = 90;  // can be changed in settings 
    uint public numRentStatuses = 0;

    // Rent deals. Any block can have one rent deal.
    struct RentDeal {          
        address renter;  // block renter
        uint rentedFrom;  // time when rent started
        uint numberOfPeriods;  //periods available
    }
    mapping(uint16 => RentDeal) public blockIdToRentDeal;

    // Rent is allowed if price is set (price Per Period)
    mapping(uint16 => uint) public blockIdToRentPrice;

    constructor(address _mehAddress) MehModule(_mehAddress) {  // TODO move to MehModule
    }

// ** RENT AOUT BLOCKS ** //
    
    function rentOutBlocks(address landlord, uint _rentPricePerPeriodWei, uint16[] _blockList) 
        external
        onlyMeh
        whenNotPaused
        returns (uint numRentStatuses)
    {   
        for (uint i = 0; i < _blockList.length; i++) {
            require(landlord == ownerOf(_blockList[i]));
            rentOutBlock(_blockList[i], _rentPricePerPeriodWei);
        }
        numRentStatuses++;
    }

    // Mark block for rent (set a rent price per period).
    // Independent on rent deal. Does not affect current renter in any way.
    function rentOutBlock(uint16 _blockId, uint _rentPricePerPeriodWei) 
        internal
    {   
        blockIdToRentPrice[_blockId] = _rentPricePerPeriodWei;
    }

// ** RENT BLOCKS ** //
    
    function rentBlocks(address renter, uint _numberOfPeriods, uint16[] _blockList) 
        external
        onlyMeh
        whenNotPaused
        returns (uint numRentStatuses)
    {   
        for (uint i = 0; i < _blockList.length; i++) {
            require(renter != ownerOf(_blockList[i]));
            rentBlock(renter, _blockList[i], _numberOfPeriods);   // TODO RentFrom
        }
        numRentStatuses++;
    }

    // what if tries to rent own area
    function rentBlock (address _renter, uint16 _blockId, uint _numberOfPeriods)
        internal
    {   
        require(maxRentPeriod >= _numberOfPeriods);
        uint totalRent = rentPriceAndAvailability(_blockId) * _numberOfPeriods;
        address landlord = ownerOf(_blockId);
        transferFunds(_renter, landlord, totalRent);
        createRentDeal(_blockId, _renter, now, _numberOfPeriods);
    }

    function isForRent(uint16 _blockId) public view returns (bool) {
        return (blockIdToRentPrice[_blockId] > 0);
    }

    function isRented(uint16 _blockId) public view returns (bool) {
        RentDeal memory deal = blockIdToRentDeal[_blockId];
        uint rentedTill = deal.rentedFrom + deal.numberOfPeriods * rentPeriod;
        return (rentedTill > now);
    }

    function rentPriceAndAvailability(uint16 _blockId) internal view returns (uint) {
        require(isForRent(_blockId));
        require(!(isRented(_blockId)));
        return blockIdToRentPrice[_blockId];
    }

    function renterOf(uint16 _blockId) public view returns (address) {
        require(isRented(_blockId));
        return blockIdToRentDeal[_blockId].renter;
    }

    function createRentDeal(uint16 _blockId, address _renter, uint _rentedFrom, uint _numberOfPeriods) private {
        blockIdToRentDeal[_blockId].renter = _renter;
        blockIdToRentDeal[_blockId].rentedFrom = _rentedFrom;
        blockIdToRentDeal[_blockId].numberOfPeriods = _numberOfPeriods;
    }

// ** RENT PRICE ** //

    function blocksRentPrice(uint _numberOfPeriods, uint16[] _blockList) 
        external
        view
        onlyMeh  // TODO is it necessary?
        whenNotPaused  // TODO is it necessary?
        returns (uint totalPrice)
    {   
        totalPrice = 0;
        for (uint i = 0; i < _blockList.length; i++) {
            // TODO need to check ownership here?
            totalPrice += rentPriceAndAvailability(_blockList[i]) * _numberOfPeriods;
        }
    }

// ** ADMIN ** //

    function adminSetMaxRentPeriod(uint newMaxRentPeriod) external onlyOwner {
        require (newMaxRentPeriod > 0);
        maxRentPeriod = newMaxRentPeriod;
    }
}
