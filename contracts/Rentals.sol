pragma solidity ^0.4.24;    

import "./MehModule.sol";

// @title Rentals: Pluggable module for MEH contract responsible for rentout-rent operations.
// @dev this contract is unaware of xy block coordinates - ids only (ids are ERC721 tokens)
contract Rentals is MehModule {
    
    // For MEH contract to be sure it plugged the right module in
    bool public isRentals = true;

    // Minimum rent period and a unit to measure rent lenght
    uint public rentPeriod = 1 days;
    // Maximum rent period (can be adjusted by admin)
    uint public maxRentPeriod = 90;  // can be changed in settings 

    // Rent deal struct. A 10x10 pixel block can have only one rent deal.
    struct RentDeal {
        address renter;  // block renter
        uint rentedFrom;  // time when rent started
        uint numberOfPeriods;  //periods available
    }
    mapping(uint16 => RentDeal) public blockIdToRentDeal;

    // Rent is allowed if price is > 0
    mapping(uint16 => uint) public blockIdToRentPrice;

    // Keeps track of rentout-rent operations
    uint public numRentStatuses = 0;

// ** INITIALIZE ** //

    /// @dev Initialize Rentals contract.
    /// @param _mehAddress address of the main Million Ether Homepage contract
    constructor(address _mehAddress) MehModule(_mehAddress) public {}

// ** RENT AOUT BLOCKS ** //
    
    /// @dev Rent out a list of blocks referenced by block ids. Set rent price per period in wei.
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

    /// @dev Set rent price for a block. Independent on rent deal. Does not affect current 
    ///  rent deal.
    function rentOutBlock(uint16 _blockId, uint _rentPricePerPeriodWei) 
        internal
    {   
        blockIdToRentPrice[_blockId] = _rentPricePerPeriodWei;
    }

// ** RENT BLOCKS ** //
    
    /// @dev Rent a list of blocks referenced by block ids for a number of periods.
    function rentBlocks(address renter, uint _numberOfPeriods, uint16[] _blockList) 
        external
        onlyMeh
        whenNotPaused
        returns (uint)
    {   
        /// check user input (not in the MEH contract to add future flexibility)
        require(_numberOfPeriods > 0);

        for (uint i = 0; i < _blockList.length; i++) {
            rentBlock(renter, _blockList[i], _numberOfPeriods);
        }
        numRentStatuses++;
        return numRentStatuses;
    }

    /// @dev Rent a block by id for a number of periods. 
    function rentBlock (address _renter, uint16 _blockId, uint _numberOfPeriods)
        internal
    {   
        // check input
        require(maxRentPeriod >= _numberOfPeriods);
        address landlord = ownerOf(_blockId);
        require(_renter != landlord);

        // get price, throws if not for rent (if rent price == 0)
        uint totalRent = getRentPrice(_blockId).mul(_numberOfPeriods);  // overflow safe
        
        transferFunds(_renter, landlord, totalRent);
        createRentDeal(_blockId, _renter, now, _numberOfPeriods);
    }

    /// @dev Checks if block is for rent.
    function isForRent(uint16 _blockId) public view returns (bool) {
        return (blockIdToRentPrice[_blockId] > 0);
    }

    /// @dev Checks if block rented and the rent hasn't expired.
    function isRented(uint16 _blockId) public view returns (bool) {
        RentDeal memory deal = blockIdToRentDeal[_blockId];
        // prevents overflow if unlimited num of periods is set 
        uint rentedTill = 
            deal.numberOfPeriods.mul(rentPeriod).add(deal.rentedFrom);
        return (rentedTill > now);
    }

    /// @dev Gets rent price for block. Throws if not for rent or if 
    ///  current rent is active.
    function getRentPrice(uint16 _blockId) internal view returns (uint) {
        require(isForRent(_blockId));
        require(!(isRented(_blockId)));
        return blockIdToRentPrice[_blockId];
    }

    /// @dev Gets renter of a block. Throws if not rented.
    function renterOf(uint16 _blockId) public view returns (address) {
        require(isRented(_blockId));
        return blockIdToRentDeal[_blockId].renter;
    }

    /// @dev Creates new rent deal.
    function createRentDeal(uint16 _blockId, address _renter, uint _rentedFrom, uint _numberOfPeriods) private {
        blockIdToRentDeal[_blockId].renter = _renter;
        blockIdToRentDeal[_blockId].rentedFrom = _rentedFrom;
        blockIdToRentDeal[_blockId].numberOfPeriods = _numberOfPeriods;
    }

// ** RENT PRICE ** //
    
    /// @dev Calculates rent price for a list of blocks. Throws if at least one block
    ///  is not available for rent.
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
    
    /// @dev Adjusts max rent period (only contract owner)
    function adminSetMaxRentPeriod(uint newMaxRentPeriod) external onlyOwner {
        require (newMaxRentPeriod > 0);
        maxRentPeriod = newMaxRentPeriod;
    }
}
