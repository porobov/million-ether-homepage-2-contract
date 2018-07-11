pragma solidity ^0.4.24;    

import "./MehERC721.sol";
import "./Accounting.sol";

contract MEH is MehERC721, Accounting {

    // Counters
    uint public numOwnershipStatuses = 0;

    event LogAds(uint ID, string imageSourceUrl, string adUrl, string adText, address indexed advertiser);  // todo emit real event

    // TODO check for overflow 
    // TODO set modifier to guard >100, <0 etc.
    function blockID(uint8 _x, uint8 _y) public pure returns (uint16) {
        return (uint16(_y) - 1) * 100 + uint16(_x);
    }

    function countBlocks(uint8 fX, uint8 fY, uint8 toX, uint8 toY) internal pure returns (uint){
        return (toX - fX + 1) * (toY - fY + 1);
    }

    function blocksList(uint8 fX, uint8 fY, uint8 toX, uint8 toY) internal pure returns (uint16[] memory r) {
        uint i = 0;
        r = new uint16[](countBlocks(fX, fY, toX, toY));
        for (uint8 ix=fX; ix<=toX; ix++) {
            for (uint8 iy=fY; iy<=toY; iy++) {
                r[i] = blockID(ix, iy);
                i++;
            }
        }
    }

    // function instead of modifier as modifier used too much stack for placeImage and rentBlocks
    function isLegalCoordinates(uint8 _fX, uint8 _fY, uint8 _toX, uint8 _toY) private pure returns (bool) {
        return ((_fX >= 1) && (_fY >=1)  && (_toX <= 100) && (_toY <= 100) 
            && (_fX <= _toX) && (_fY <= _toY));
        // TODO need to linit total number of blocs here?
    }

// ** BUY AND SELL BLOCKS ** //

    function buyArea(uint8 fX, uint8 fY, uint8 toX, uint8 toY) 
        external
        whenNotPaused
        payable
    {   
        require(isLegalCoordinates(fX, fY, toX, toY));
        // require(msg.value >= areaPrice(fX, fY, toX, toY));  //TODO find alternative, because it will not let buy from current balance
        _depositTo(msg.sender, msg.value);
        market.buyBlocks(msg.sender, blocksList(fX, fY, toX, toY));
        // numOwnershipStatuses++;
        // emit LogOwnership(numOwnershipStatuses, fX, fY, toX, toY, msg.sender, 0);
    }

    // sell an area of blocks at coordinates [fX, fY, toX, toY]
    // (priceForEachBlockCents = 0 - not for sale)
    // TODO what if a huge range of coordinates is selected
    function sellArea(uint8 fX, uint8 fY, uint8 toX, uint8 toY, uint priceForEachBlockWei) // TODO sellTo
        external 
        whenNotPaused
    {   
        require(isLegalCoordinates(fX, fY, toX, toY));
        market.sellBlocks(msg.sender, priceForEachBlockWei, blocksList(fX, fY, toX, toY));
        // numOwnershipStatuses++;
        // emit LogOwnership(numOwnershipStatuses, fX, fY, toX, toY, address(0x0), priceForEachBlockCents);
    }

    // area price
    function areaPrice(uint8 fX, uint8 fY, uint8 toX, uint8 toY) 
        public 
        view 
        returns (uint) 
    {
        require(isLegalCoordinates(fX, fY, toX, toY));
        return market.areaPrice(blocksList(fX, fY, toX, toY));
    }

// ** RENT OUT AND RENT BLOCKS ** //
        
    // @dev Rent out an area of blocks at coordinates [fX, fY, toX, toY]
    // @notice INFOf _rentPricePerPeriodWei = 0 then not for rent
    function rentOutArea(uint8 fX, uint8 fY, uint8 toX, uint8 toY, uint _rentPricePerPeriodWei)  // TODO maxRentPeriod, minRentPeriod,  
        external
        whenNotPaused
    {   
        require(isLegalCoordinates(fX, fY, toX, toY));
        rentals.rentOutBlocks(msg.sender, _rentPricePerPeriodWei, blocksList(fX, fY, toX, toY));
        // numRentStatuses++;
        // LogRent(numRentStatuses, fX, fY, toX, toY, hourlyRentForEachBlockInWei, 0, address(0x0));
    }
    
    function rentArea(uint8 fX, uint8 fY, uint8 toX, uint8 toY, uint _numberOfPeriods)  // TODO RentFrom
        external
        payable
        whenNotPaused
    {
        require(isLegalCoordinates(fX, fY, toX, toY));
        // require(msg.value >= areaRentPrice(fX, fY, toX, toY, _numberOfPeriods)); //TODO will permit buying from current balance
        _depositTo(msg.sender, msg.value);
        rentals.rentBlocks(msg.sender, _numberOfPeriods, blocksList(fX, fY, toX, toY));   // TODO RentFrom
        // numRentStatuses++;
        // LogRent(numRentStatuses, fX, fY, toX, toY, 0, rentedTill, msg.sender);
    }

    // rent price for period 
    function areaRentPrice(uint8 fX, uint8 fY, uint8 toX, uint8 toY, uint _numberOfPeriods)
        public 
        view 
        returns (uint) 
    {
        require(isLegalCoordinates(fX, fY, toX, toY));
        return rentals.blocksRentPrice(_numberOfPeriods, blocksList(fX, fY, toX, toY));
    }

// ** PLACE ADS ** //
    
    // paintArea
    function placeAds( 
        uint8 fX, 
        uint8 fY, 
        uint8 toX, 
        uint8 toY, 
        string imageSourceUrl, 
        string adUrl, 
        string adText
    ) 
        external
        whenNotPaused
    {   
        require(isLegalCoordinates(fX, fY, toX, toY));
        // paintBlocks
        uint AdsId = ads.placeAds(msg.sender, blocksList(fX, fY, toX, toY), imageSourceUrl, adUrl, adText);
        // todo emit full event here 
    }   

    // canPaint
    function isAllowedToAdvertise(
        uint8 fX, 
        uint8 fY, 
        uint8 toX, 
        uint8 toY
    ) 
        external
        view
        returns (bool)
    {
        require(isLegalCoordinates(fX, fY, toX, toY));
        return ads.isAllowedToAdvertise(msg.sender, blocksList(fX, fY, toX, toY));
    }

// ** INFO GETTERS ** //

    function getBlockOwner(uint8 x, uint8 y) external view returns (address) {
        return ownerOf(blockID(x, y));
    }
}