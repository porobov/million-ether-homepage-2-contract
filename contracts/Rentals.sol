pragma solidity ^0.4.24;    

import "./MehModule.sol";

contract Rentals is MehModule {
    
    bool public isRentals = true;

    // deafaul
    /// @notice Neither Landlord nor Renter can cancel rent untill rent period is over
    uint rentPeriod = 1 days; 

    // Rent deals. Any block can have one rent deal.
    struct RentDeal {          
        address renter;  // block renter
        uint rentedFrom;  // time when rent started
    }
    mapping(uint => RentDeal) public blockIdToRentDeal;

    // Rent is allowed if price is set (price Per Period)
    mapping(uint => uint) public blockIdToRentPrice;

// ** RENT AND RENT OUT BLOCKS ** //
    
    //Mark block for rent (set a hourly rent price)
    function rentOutBlock(uint16 _blockId, uint _rentPricePerPeriodWei) 
        external
        onlyMeh
    {   
        // collect rent
        // cancel current rent
        blockIdToRentPrice[_blockId] = _rentPricePerPeriodWei;
    }

    // MEH
    // rent out an area of blocks at coordinates [fromX, fromY, toX, toY]
    // hourlyRentForEachBlockInWei = 0 - not for rent
    // function rentOutArea(uint8 fromX, uint8 fromY, uint8 toX, uint8 toY, uint rentForEachBlockCentsPerSecond, uint maxPeriodSeconds)
    function rentOutArea(uint8 fromX, uint8 fromY, uint8 toX, uint8 toY, uint _rentPricePerPeriodWei)
        external
        whenNotPaused
    {   
        require(isLegalCoordinates(fromX, fromY, toX, toY));
        for (uint8 ix=fromX; ix<=toX; ix++) {
            for (uint8 iy=fromY; iy<=toY; iy++) {
                uint16 _blockId = blockID(ix, iy);
                require(msg.sender == ownerOf(_blockId));  // TODO refactor? 
                rentals.rentOutBlock(uint16 _blockId, uint _rentPricePerPeriodWei);
            }
        }
        // numRentStatuses++;
        // LogRent(numRentStatuses, fromX, fromY, toX, toY, hourlyRentForEachBlockInWei, 0, address(0x0));
    }

    function rentBlock (address renter, uint16 _blockId)
        internal
    {
        createRentDeal(renter, _blockId, now);
        firstRentPayMent(_blockId);  // TODO try to charge first and set deal second
    }

    function createRentDeal(address _renter, uint16 _blockId, uint _rentedFrom) {
        blockIdToRentDeal[_blockId].renter = _renter;
        blockIdToRentDeal[_blockId].rentedFrom = _rentedFrom;
    }

    function firstRentPayMent(uint16 _blockId) {
        chargeRent(_blockId, 1);
    }

    function chargeRent(uint16 _blockId, uint numberOfPeriods) {
        uint rentPrice = numberOfPeriods * blockIdToRentPrice[_blockId];
        address renter = blockIdToRentDeal[_blockId].renter;
        address landlord = meh.ownerOf(_blockId)
        deductFrom(renter, rentPrice);
        depositTo(landlord, rentPrice);
    }

    function isRentedOut(uint16 _blockId) {
        
    }

    function rentPriceForOnePeriod(uint8 fromX, uint8 fromY, uint8 toX, uint8 toY) {
        require(isRentedOut(fromX, fromY, toX, toY));
        require(hasNoRenter(fromX, fromY, toX, toY));
        return rentPricePerPeriod;
    }

    function rentArea(uint8 fromX, uint8 fromY, uint8 toX, uint8 toY) // , uint rentPeriodHours) 
        external
        payable
    {   
        require(isLegalCoordinates(fromX, fromY, toX, toY));
        require(msg.value >= rentPriceForOnePeriod(fromX, fromY, toX, toY));
        depositTo(msg.sender, msg.value);

        for (uint8 ix=fromX; ix<=toX; ix++) {
            for (uint8 iy=fromY; iy<=toY; iy++) {
                uint16 _blockId = blockID(ix, iy);
                rentBlock(msg.sender, _blockId);
            }
        }
        // numRentStatuses++;
        // LogRent(numRentStatuses, fromX, fromY, toX, toY, 0, rentedTill, msg.sender);
    }




}
