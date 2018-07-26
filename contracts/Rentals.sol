pragma solidity ^0.4.24;    

import "./MehModule.sol";

contract Rentals is MehModule {
    
    bool public isRentals = true;

    // deafaults
    /// @notice Nobidy can cancel rent untill rent period is over
    uint public rentPeriod = 1 days;  // and thus min rent period
    uint public maxRentPeriod = 90;  // can be changed in settings 

    // Rent deals. Any block can have one rent deal.
    struct RentDeal {          
        address renter;  // block renter
        uint rentedFrom;  // time when rent started
        uint numberOfPeriods;  //periods available
    }
    mapping(uint16 => RentDeal) public blockIdToRentDeal;

    // Rent is allowed if price is set (price Per Period)
    mapping(uint16 => uint) public blockIdToRentPrice;

    // Counts rent statuses changes.
    uint public numRentStatuses = 0;

    constructor(address _mehAddress) MehModule(_mehAddress) public {  // TODO move to MehModule
    }

// ** RENT AOUT BLOCKS ** //
    
    function rentOutBlocks(address landlord, uint _rentPricePerPeriodWei, uint16[] _blockList) 
        external
        onlyMeh
        whenNotPaused
        returns (uint)
    {   
        // TODO check everywhere. sell price can be any - might overflow
        for (uint i = 0; i < _blockList.length; i++) {
            require(landlord == ownerOf(_blockList[i]));
            rentOutBlock(_blockList[i], _rentPricePerPeriodWei);
        }
        numRentStatuses++;
        return numRentStatuses;
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
        returns (uint)
    {   
        require(_numberOfPeriods > 0);
        for (uint i = 0; i < _blockList.length; i++) {
            rentBlock(renter, _blockList[i], _numberOfPeriods);
        }
        numRentStatuses++;
        return numRentStatuses;
    }

    // what if tries to rent own area
    function rentBlock (address _renter, uint16 _blockId, uint _numberOfPeriods)
        internal
    {   
        require(maxRentPeriod >= _numberOfPeriods);
        address landlord = ownerOf(_blockId);
        require(_renter != landlord);
        uint totalRent = getRentPrice(_blockId).mul(_numberOfPeriods);  // overflow safe
        
        transferFunds(_renter, landlord, totalRent);
        createRentDeal(_blockId, _renter, now, _numberOfPeriods);
    }

    function isForRent(uint16 _blockId) public view returns (bool) {
        return (blockIdToRentPrice[_blockId] > 0);
    }

    function isRented(uint16 _blockId) public view returns (bool) {
        RentDeal memory deal = blockIdToRentDeal[_blockId];
        // prevents overflow if unlimited num of periods is set
        uint rentedTill =  deal.numberOfPeriods.mul(rentPeriod).add(deal.rentedFrom);  
        return (rentedTill > now);
    }

    function getRentPrice(uint16 _blockId) internal view returns (uint) {
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
        returns (uint)
    {   
        uint totalPrice = 0;
        for (uint i = 0; i < _blockList.length; i++) {
            // overflow safe (rentPrice is arbitary)
            totalPrice = getRentPrice(_blockList[i]).mul(_numberOfPeriods).add(totalPrice);
        }
        return totalPrice;
    }

// ** ADMIN ** //

    function adminSetMaxRentPeriod(uint newMaxRentPeriod) external onlyOwner {
        require (newMaxRentPeriod > 0);
        maxRentPeriod = newMaxRentPeriod;
    }
}
