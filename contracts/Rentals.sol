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
        uint numberOfPeriods;  //periods available
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
        cutCurrentRentDeal(_blockId);  // claims earned for previos as well
        blockIdToRentPrice[_blockId] = _rentPricePerPeriodWei;
    }

    // MEH
    // rent out an area of blocks at coordinates [fromX, fromY, toX, toY]
    // hourlyRentForEachBlockInWei = 0 - not for rent
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

    function isForRent(uint16 _blockId) {
        return (blockIdToRentPrice[_blockId] > 0);
    }

    function isRented(uint16 _blockId) {
        RentDeal deal = blockIdToRentDeal[_blockId];
        return (deal.rentedFrom + deal.numberOfPeriods * rentPeriod > now);
    }

    function createRentDeal(address _renter, uint16 _blockId, uint _rentedFrom, uint _numberOfPeriods) {
        blockIdToRentDeal[_blockId].renter = _renter;
        blockIdToRentDeal[_blockId].rentedFrom = _rentedFrom;
        blockIdToRentDeal[_blockId].numberOfPeriods = _numberOfPeriods;
    }

    function removeRentDeal(uint16 _blockId) {
        delete blockIdToRentDeal[_blockId];
    }

    function escrowRentPayment(uint16 _blockId, uint _totalRent) {
        uint rentPrice = numberOfPeriods * blockIdToRentPrice[_blockId];
        address renter = blockIdToRentDeal[_blockId].renter;
        address landlord = meh.ownerOf(_blockId)
        deductFrom(renter, rentPrice);
        depositTo(rentOffice, rentPrice);

    }
    
    function _numPeriodsElapsed (uint16 _blockId) {
        return numPeriodsElapsed = (now - rentedFrom) / rentPeriod;  //TODO will auto-truncate
    }

    // does not affect renter if they have enough funds
    // moves rented from, pays rent profit
    function refreshRentDeal(uint16 _blockId) {
        
        uint numPeriodsElapsed = _numPeriodsElapsed(_blockId);
        require(numPeriodsElapsed > 0);
        
        // pay landlord
        uint landlordPayment = numPeriodsElapsed * rentPrice;
        deductFrom(rentOffice, landlordPayment);
        address landlord = ownerOf(_blockId);
        depositTo(landlord, landlordPayment);

        // renew rent
        uint numPeriodsLeft = numberOfPeriods - numPeriodsElapsed;
        if (numPeriodsLeft >= 1) {
            newRentedFrom = rentedFrom + numPeriodsElapsed * rentPeriod;
            cutRentLeft(_blockId, newRentedFrom, numPeriodsLeft);
        } else {
            removeRentDeal(_blockId);
        }
        return numPeriodsLeft;
    }

    // 
    function cutCurrentRentDeal(uint16 _blockId) {
        uint numPeriodsLeft = refreshRent(uint16 _blockId);
        if (numPeriodsLeft == 1) {
            //do nothing
        }
        if (numPeriodsLeft > 1) {
            cutRentRight(_blockId, 1);
            deductFrom(rentOffice, numPeriodsLeft * rentPrice);
            depositTo(renter, numPeriodsLeft * rentPrice);
        }
    }

    function rentPriceForOnePeriod(uint16 _blockId) {
        require(isForRent(_blockId));
        require(!(isRented(_blockId)));
        return blockIdToRentPrice[_blockId];
    }

    // TODO prolong rent
    // TODO pay previous owner
    function rentBlock (address _renter, uint16 _blockId, uint _numberOfPeriods)
        internal
    {   
        require(isForRent(_blockId));
        require(!(isRented(_blockId)));  // TODO will throw but the rent will not refresh
        refreshRentDeal(_blockId);  // TODO how to refresh if throws
        escrowRentPayment(_blockId, renter, _numberOfPeriods);
        createRentDeal(_renter, _blockId, now, _numberOfPeriods);
    }

    // what if tries to rent own area
    // what if tries to rent mixed (rented by themselves + not rented yet)
    function rentArea(uint8 fromX, uint8 fromY, uint8 toX, uint8 toY, uint _numberOfPeriods) // , uint rentPeriodHours) 
        external
        payable
    {   
        require(isLegalCoordinates(fromX, fromY, toX, toY));
        require(msg.value >= rentPriceTotal(fromX, fromY, toX, toY, _numberOfPeriods));

        depositTo(msg.sender, msg.value);

        for (uint8 ix=fromX; ix<=toX; ix++) {
            for (uint8 iy=fromY; iy<=toY; iy++) {
                uint16 _blockId = blockID(ix, iy);
                rentBlock(msg.sender, _blockId, _numberOfPeriods);
            }
        }
        // numRentStatuses++;
        // LogRent(numRentStatuses, fromX, fromY, toX, toY, 0, rentedTill, msg.sender);
    }




}
