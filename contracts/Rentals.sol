pragma solidity ^0.4.24;    

import "./MehModule.sol";

contract Rentals is MehModule {
    
    bool public isRentals = true;

    // deafaul
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

    constructor(address _mehAddress) public {  // TODO move to MehModule
        adminSetMeh(_mehAddress);
    }

    // TODO create library (same for Market) - into MehModule maybe
    function depositTo(address _recipient, uint _amount) internal {
        return meh.operatorDepositTo(_recipient, _amount);
    }

    function deductFrom(address _payer, uint _amount) internal {
        return meh.operatorDeductFrom(_payer, _amount);
    }

// ** RENT AND RENT OUT BLOCKS ** //
    
    // Mark block for rent (set a rent price per period).
    // Independent on rent deal. Does not affect current renter in any way.
    function rentOutBlock(uint16 _blockId, uint _rentPricePerPeriodWei) 
        external
        onlyMeh
        whenNotPaused
    {   
        blockIdToRentPrice[_blockId] = _rentPricePerPeriodWei;
    }

    // what if tries to rent own area
    function rentBlock (address _renter, uint16 _blockId, uint _numberOfPeriods)
        external
        onlyMeh
        whenNotPaused
    {   
        require(maxRentPeriod >= _numberOfPeriods);
        uint totalRent = rentPriceAndAvailability(_blockId) * _numberOfPeriods;
        address landlord = meh.ownerOf(_blockId);
        deductFrom(_renter, totalRent);
        createRentDeal(_blockId, _renter, now, _numberOfPeriods);
        depositTo(landlord, totalRent);
    }

    function isForRent(uint16 _blockId) public view returns (bool) {
        return (blockIdToRentPrice[_blockId] > 0);
    }

    function isRented(uint16 _blockId) public view returns (bool) {
        RentDeal memory deal = blockIdToRentDeal[_blockId];
        uint rentedTill = deal.rentedFrom + deal.numberOfPeriods * rentPeriod;
        return (rentedTill > now);
    }

    function createRentDeal(uint16 _blockId, address _renter, uint _rentedFrom, uint _numberOfPeriods) private {
        blockIdToRentDeal[_blockId].renter = _renter;
        blockIdToRentDeal[_blockId].rentedFrom = _rentedFrom;
        blockIdToRentDeal[_blockId].numberOfPeriods = _numberOfPeriods;
    }

    function rentPriceAndAvailability(uint16 _blockId) public view returns (uint) {
        require(isForRent(_blockId));
        require(!(isRented(_blockId)));
        return blockIdToRentPrice[_blockId];
    }

    function renterOf(uint16 _blockId) public view returns (address) {
        require(isRented(_blockId));
        return blockIdToRentDeal[_blockId].renter;
    }

    function adminSetMaxRentPeriod(uint newMaxRentPeriod) external onlyOwner {
        require (newMaxRentPeriod > 0);
        maxRentPeriod = newMaxRentPeriod;
    }
}
