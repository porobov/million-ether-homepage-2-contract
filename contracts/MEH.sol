pragma solidity ^0.4.24;    

import "./MehERC721.sol";
import "./Accounting.sol";

contract MEH is MehERC721, Accounting {

    // Counters
    uint public numOwnershipStatuses = 0;
    uint public numImages = 0;

    // TODO check for overflow 
    // TODO set modifier to guard >100, <0 etc.
    function blockID(uint8 _x, uint8 _y) public pure returns (uint16) {
        return (uint16(_y) - 1) * 100 + uint16(_x);
    }

    // function instead of modifier as modifier used too much stack for placeImage and rentBlocks
    function isLegalCoordinates(uint8 _fromX, uint8 _fromY, uint8 _toX, uint8 _toY) private pure returns (bool) {
        return ((_fromX >= 1) && (_fromY >=1)  && (_toX <= 100) && (_toY <= 100) 
            && (_fromX <= _toX) && (_fromY <= _toY));
    }

// ** BUY AND SELL BLOCKS ** //

    function buyArea(uint8 fromX, uint8 fromY, uint8 toX, uint8 toY) 
        external
        whenNotPaused
        payable
    {   
        require(isLegalCoordinates(fromX, fromY, toX, toY));
        // require enough funds
        _depositTo(msg.sender, msg.value);

        for (uint8 ix=fromX; ix<=toX; ix++) {
            for (uint8 iy=fromY; iy<=toY; iy++) {
                // uint16 blockId = blockID(ix, iy);
                // require(msg.sender != ownerOf(blockId));  // thows, because blocks may not exist
                market._buyBlock(msg.sender, blockID(ix, iy));
            }
        }
        // numOwnershipStatuses++;
        // emit LogOwnership(numOwnershipStatuses, fromX, fromY, toX, toY, msg.sender, 0);
    }

    // sell an area of blocks at coordinates [fromX, fromY, toX, toY]
    // (priceForEachBlockCents = 0 - not for sale)
    function sellArea(uint8 fromX, uint8 fromY, uint8 toX, uint8 toY, uint priceForEachBlockWei) // TODO sellTo
        external 
        whenNotPaused
    {   
        require(isLegalCoordinates(fromX, fromY, toX, toY));

        for (uint8 ix=fromX; ix<=toX; ix++) {
            for (uint8 iy=fromY; iy<=toY; iy++) {
                // only owner is to set, update price or cancel
                uint16 _blockId = blockID(ix, iy);
                require(msg.sender == ownerOf(_blockId));
                market._sellBlock(_blockId, priceForEachBlockWei);
            }
        }
        // numOwnershipStatuses++;
        // emit LogOwnership(numOwnershipStatuses, fromX, fromY, toX, toY, address(0x0), priceForEachBlockCents);
    }

    // area price
    function areaPrice(uint8 fromX, uint8 fromY, uint8 toX, uint8 toY) 
        public 
        view 
        returns (uint) 
    {
        require(isLegalCoordinates(fromX, fromY, toX, toY));
        return market.areaPrice(fromX, fromY, toX, toY);
    }

// ** RENT OUT AND RENT BLOCKS ** //
        
    // @dev Rent out an area of blocks at coordinates [fromX, fromY, toX, toY]
    // @notice INFOf _rentPricePerPeriodWei = 0 then not for rent
    function rentOutArea(uint8 fromX, uint8 fromY, uint8 toX, uint8 toY, uint _rentPricePerPeriodWei)  // TODO maxRentPeriod, minRentPeriod,  
        external
        whenNotPaused
    {   
        require(isLegalCoordinates(fromX, fromY, toX, toY));

        for (uint8 ix=fromX; ix<=toX; ix++) {
            for (uint8 iy=fromY; iy<=toY; iy++) {
                uint16 _blockId = blockID(ix, iy);
                require(msg.sender == ownerOf(_blockId));
                rentals.rentOutBlock(_blockId, _rentPricePerPeriodWei);
            }
        }
        // numRentStatuses++;
        // LogRent(numRentStatuses, fromX, fromY, toX, toY, hourlyRentForEachBlockInWei, 0, address(0x0));
    }
    
    function rentArea(uint8 fromX, uint8 fromY, uint8 toX, uint8 toY, uint _numberOfPeriods)  // TODO RentFrom
        external
        payable
        whenNotPaused
    {   
        require(isLegalCoordinates(fromX, fromY, toX, toY));
        require(msg.value >= areaRentPrice(fromX, fromY, toX, toY, _numberOfPeriods));

        _depositTo(msg.sender, msg.value);

        for (uint8 ix=fromX; ix<=toX; ix++) {
            for (uint8 iy=fromY; iy<=toY; iy++) {
                uint16 _blockId = blockID(ix, iy);
                require(msg.sender != ownerOf(_blockId));
                rentals.rentBlock(msg.sender, _blockId, _numberOfPeriods);   // TODO RentFrom
            }
        }
        // numRentStatuses++;
        // LogRent(numRentStatuses, fromX, fromY, toX, toY, 0, rentedTill, msg.sender);
    }

        // rent price for period 
    function areaRentPrice(uint8 fromX, uint8 fromY, uint8 toX, uint8 toY, uint _numberOfPeriods) 
        public 
        view 
        returns (uint) 
    {
        require(isLegalCoordinates(fromX, fromY, toX, toY));

        uint totalPrice = 0;
        for (uint8 ix=fromX; ix<=toX; ix++) {
            for (uint8 iy=fromY; iy<=toY; iy++) {
                uint16 _blockId = blockID(ix, iy);
                // TODO need to check ownership here? 
                totalPrice += rentals.rentPriceAndAvailability(_blockId) * _numberOfPeriods;
            }
        }
        return totalPrice;
    }

// ** PLACE ADS ** //

    function placeImage(
        uint8 fromX, 
        uint8 fromY, 
        uint8 toX, 
        uint8 toY, 
        string imageSourceUrl, 
        string adUrl, 
        string adText
    ) 
        external
        whenNotPaused
    {   
        require(isLegalCoordinates(fromX, fromY, toX, toY));
        ads.placeImage(msg.sender, fromX, fromY, toX, toY, imageSourceUrl, adUrl, adText);
    }

    function isAllowedToAdvertise(
        uint8 fromX, 
        uint8 fromY, 
        uint8 toX, 
        uint8 toY
    ) 
        external
        view
        returns (bool)
    {
        require(isLegalCoordinates(fromX, fromY, toX, toY));
        return ads.isAllowedToAdvertise(msg.sender, fromX, fromY, toX, toY);
    }

// ** INFO GETTERS ** //

    function getBlockOwner(uint8 x, uint8 y) external view returns (address) {
        return ownerOf(blockID(x, y));
    }


}