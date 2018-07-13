pragma solidity ^0.4.24;    

import "./MehERC721.sol";
import "./Accounting.sol";

contract MEH is MehERC721, Accounting {

    event LogBuys(
        uint ID,
        uint8 fromX,
        uint8 fromY,
        uint8 toX,
        uint8 toY,
        address newLandlord
    );
    event LogSells(
        uint ID,
        uint8 fromX,
        uint8 fromY,
        uint8 toX,
        uint8 toY,
        uint sellPrice
    );
    event LogRentsOut(
        uint ID,
        uint8 fromX,
        uint8 fromY,
        uint8 toX,
        uint8 toY,
        uint rentPricePerPeriodWei
    );
    event LogRents(
        uint ID,
        uint8 fromX,
        uint8 fromY,
        uint8 toX,
        uint8 toY,
        uint numberOfPeriods,
        uint rentedFrom
    );
    event LogAds(uint ID, 
        uint8 fromX,
        uint8 fromY,
        uint8 toX,
        uint8 toY,
        string imageSourceUrl,
        string adUrl,
        string adText,
        address indexed advertiser);

// ** BUY AND SELL BLOCKS ** //

    function buyArea(uint8 fX, uint8 fY, uint8 toX, uint8 toY) 
        external
        whenNotPaused
        payable
    {   
        require(isLegalCoordinates(fX, fY, toX, toY));
        require(canPay(areaPrice(fX, fY, toX, toY)));
        depositFunds();
        uint id = market.buyBlocks(msg.sender, blocksList(fX, fY, toX, toY));
        emit LogBuys(id, fX, fY, toX, toY, msg.sender);
    }

    // sell an area of blocks at coordinates [fX, fY, toX, toY]
    // (priceForEachBlockCents = 0 - not for sale)
    function sellArea(uint8 fX, uint8 fY, uint8 toX, uint8 toY, uint priceForEachBlockWei) // TODO sellTo
        external 
        whenNotPaused
    {   
        require(isLegalCoordinates(fX, fY, toX, toY));
        uint id = market.sellBlocks(msg.sender, priceForEachBlockWei, blocksList(fX, fY, toX, toY));
        emit LogSells(id, fX, fY, toX, toY, priceForEachBlockWei);
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
        uint id = rentals.rentOutBlocks(msg.sender, _rentPricePerPeriodWei, blocksList(fX, fY, toX, toY));
        emit LogRentsOut(id, fX, fY, toX, toY, _rentPricePerPeriodWei);
    }
    
    function rentArea(uint8 fX, uint8 fY, uint8 toX, uint8 toY, uint _numberOfPeriods)  // TODO RentFrom
        external
        payable
        whenNotPaused
    {
        require(isLegalCoordinates(fX, fY, toX, toY));
        require(canPay(areaRentPrice(fX, fY, toX, toY, _numberOfPeriods)));
        depositFunds();
        uint id = rentals.rentBlocks(msg.sender, _numberOfPeriods, blocksList(fX, fY, toX, toY));   // TODO RentFrom
        emit LogRents(id, fX, fY, toX, toY, _numberOfPeriods, 0);
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
    
    function placeAds( 
        uint8 fX, 
        uint8 fY, 
        uint8 toX, 
        uint8 toY, 
        string imageSource, 
        string link, 
        string text
    ) 
        external
        whenNotPaused
    {   
        require(isLegalCoordinates(fX, fY, toX, toY));
        uint AdsId = ads.paintBlocks(msg.sender, blocksList(fX, fY, toX, toY), imageSource, link, text);
        emit LogAds(AdsId, fX, fY, toX, toY, imageSource, link, text, msg.sender);
    }

    function canAdvertise(
        address advertiser,
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
        return ads.canPaintBlocks(advertiser, blocksList(fX, fY, toX, toY));
    }

// ** INFO GETTERS ** //

    function getBlockOwner(uint8 x, uint8 y) external view returns (address) {
        return ownerOf(blockID(x, y));
    }

    // todo getBalanceOf

// ** UTILS ** //

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
        // TODO what if a huge range of coordinates is selected
    }
}