pragma solidity ^0.4.24;    

import "./MehERC721.sol";
import "./Accounting.sol";

/*
* There is a 1000x1000 pixel field displayed at TheMillionEtherHomepage.com. 
* This smart contract lets you buy 10x10 pixel blocks and place your ads there. 
* It also allows to sell blocks and rent them out to other advertisers. 

Previous version is here 

There are 4 parts 
- MEH - accounting 

* interface contract for The Million Ether Homepage. All logic is delegated to external upgradable contracts. 
* This contract is immutable it keeps Non fungible ERC721 tokens (10x10 pixel blocks) ledger and eth balances.
*/
contract MEH is MehERC721, Accounting {

    /// @dev emited when an area blocks is bought
    event LogBuys(
        uint ID,
        uint8 fromX,
        uint8 fromY,
        uint8 toX,
        uint8 toY,
        address newLandlord
    );

    /// @dev emited when an area blocks is marked for sale
    event LogSells(
        uint ID,
        uint8 fromX,
        uint8 fromY,
        uint8 toX,
        uint8 toY,
        uint sellPrice
    );

    /// @dev emited when an area blocks is marked for rent
    event LogRentsOut(
        uint ID,
        uint8 fromX,
        uint8 fromY,
        uint8 toX,
        uint8 toY,
        uint rentPricePerPeriodWei
    );

    /// @dev emited when an area blocks is rented
    event LogRents(
        uint ID,
        uint8 fromX,
        uint8 fromY,
        uint8 toX,
        uint8 toY,
        uint numberOfPeriods,
        uint rentedFrom
    );

    /// @dev emited when an ad is placed to an area
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
    
    /// @dev lets a message sender to buy blocks within area
    function buyArea(uint8 fX, uint8 fY, uint8 toX, uint8 toY) 
        external
        whenNotPaused
        payable
    {   
        // check input parameters and eth deposited
        require(isLegalCoordinates(fX, fY, toX, toY));
        require(canPay(areaPrice(fX, fY, toX, toY)));
        depositFunds();

        // try to buy blocks through market contract
        // will get an id of buy-sell operation if succeeds (if all blocks available)
        uint id = market.buyBlocks(msg.sender, blocksList(fX, fY, toX, toY));
        emit LogBuys(id, fX, fY, toX, toY, msg.sender);
    }

    /// @dev lets a message sender to mark blocks for sale at price set for each block in wei
    /// @notice (priceForEachBlockCents = 0 - not for sale)
    function sellArea(uint8 fX, uint8 fY, uint8 toX, uint8 toY, uint priceForEachBlockWei) // TODO sellTo
        external 
        whenNotPaused
    {   
        // check input parameters
        require(isLegalCoordinates(fX, fY, toX, toY));

        // try to mark blocks for sale through market contract
        // will get an id of buy-sell operation if succeeds (if owns all blocks)
        uint id = market.sellBlocks(msg.sender, priceForEachBlockWei, blocksList(fX, fY, toX, toY));
        emit LogSells(id, fX, fY, toX, toY, priceForEachBlockWei);
    }

    /// @dev get area price in wei
    function areaPrice(uint8 fX, uint8 fY, uint8 toX, uint8 toY) 
        public 
        view 
        returns (uint) 
    {   
        // check input
        require(isLegalCoordinates(fX, fY, toX, toY));

        // querry areaPrice in wei at market contract
        return market.areaPrice(blocksList(fX, fY, toX, toY));
    }

// ** RENT OUT AND RENT BLOCKS ** //
        
    /// @dev Rent out an area of blocks at coordinates [fromX, fromY, toX, toY] at a price for each block in wei
    /// @notice if _rentPricePerPeriodWei = 0 then makes area not available for rent
    function rentOutArea(uint8 fX, uint8 fY, uint8 toX, uint8 toY, uint _rentPricePerPeriodWei)  // TODO maxRentPeriod, minRentPeriod,  
        external
        whenNotPaused
    {   
        // check input
        require(isLegalCoordinates(fX, fY, toX, toY));

        // try to mark blocks as rented out through rentals contract
        // will get an id of rent-rentout operation if succeeds (if message sender owns blocks)
        uint id = rentals.rentOutBlocks(msg.sender, _rentPricePerPeriodWei, blocksList(fX, fY, toX, toY));
        emit LogRentsOut(id, fX, fY, toX, toY, _rentPricePerPeriodWei);
    }
    
    /// @dev Rent an area of blocks at coordinates [fromX, fromY, toX, toY] for a number of periods specified
    ///  (period length is specified in rentals contract)
    function rentArea(uint8 fX, uint8 fY, uint8 toX, uint8 toY, uint _numberOfPeriods)  // TODO RentFrom
        external
        payable
        whenNotPaused
    {   
        // check input parameters and eth deposited
        // checks number of periods > 0 in rentals contract
        require(isLegalCoordinates(fX, fY, toX, toY));
        require(canPay(areaRentPrice(fX, fY, toX, toY, _numberOfPeriods)));
        depositFunds();

        // try to rent blocks through rentals contract
        // will get an id of rent-rentout operation if succeeds (if all blocks available for rent)
        uint id = rentals.rentBlocks(msg.sender, _numberOfPeriods, blocksList(fX, fY, toX, toY));   // TODO RentFrom
        emit LogRents(id, fX, fY, toX, toY, _numberOfPeriods, 0);
    }

    /// @dev get area rent price in wei for number of periods specified 
    ///  (period length is specified in rentals contract) 
    function areaRentPrice(uint8 fX, uint8 fY, uint8 toX, uint8 toY, uint _numberOfPeriods)
        public 
        view 
        returns (uint) 
    {   
        // check input 
        require(isLegalCoordinates(fX, fY, toX, toY));

        // querry areaPrice in wei at rentals contract
        return rentals.blocksRentPrice  (_numberOfPeriods, blocksList(fX, fY, toX, toY));
    }

// ** PLACE ADS ** //
    
    /// @dev places ads (image, caption and link to an advertised website) into desired coordinates
    /// @notice nothing is stored in any of the contracts except an image id. All other data is 
    ///  only emitted in event. Basicaly this function just verifies if an event is allowed 
    ///  to be emitted.
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
        // check input
        require(isLegalCoordinates(fX, fY, toX, toY));

        // try to place ads through ads contract
        // will get an image id if succeeds (if advertiser owns or rents all blocks within area)
        uint AdsId = ads.paintBlocks(msg.sender, blocksList(fX, fY, toX, toY), imageSource, link, text);
        emit LogAds(AdsId, fX, fY, toX, toY, imageSource, link, text, msg.sender);
    }

    /// @dev check if an advertiser is allowed to put ads within area (i.e. owns or rents all blocks)
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
        // check user input
        require(isLegalCoordinates(fX, fY, toX, toY));

        // querry permission at ads contract
        return ads.canPaintBlocks(advertiser, blocksList(fX, fY, toX, toY));
    }

// ** INFO GETTERS ** //
    
    /// @dev get an owner(address) of block at a specified coordinates
    function getBlockOwner(uint8 x, uint8 y) external view returns (address) {
        return ownerOf(blockID(x, y));
    }

    // todo getBalanceOf

// ** UTILS ** //
    
    /// @dev get ERC721 token id corresponding to xy coordinates
    function blockID(uint8 _x, uint8 _y) public pure returns (uint16) {
        return (uint16(_y) - 1) * 100 + uint16(_x);
    }

    /// @dev get a number of blocks within area
    function countBlocks(uint8 fX, uint8 fY, uint8 toX, uint8 toY) internal pure returns (uint16){
        return (toX - fX + 1) * (toY - fY + 1);
    }

    /// @dev get an array of all block ids (i.e. ERC721 token ids) within area
    function blocksList(
        uint8 fX, 
        uint8 fY, 
        uint8 toX, 
        uint8 toY
    ) 
        internal 
        pure 
        returns (uint16[] memory r) 
    {
        uint i = 0;
        r = new uint16[](countBlocks(fX, fY, toX, toY));
        for (uint8 ix=fX; ix<=toX; ix++) {
            for (uint8 iy=fY; iy<=toY; iy++) {
                r[i] = blockID(ix, iy);
                i++;
            }
        }
    }
    /// @dev insures that area coordinates are within 100x100 field and 
    ///  from-coordinates >= to-coordinates
    /// @notice function is used instead of modifier as modifier 
    ///  required too much stack for placeImage and rentBlocks
    function isLegalCoordinates(
        uint8 _fX, 
        uint8 _fY, 
        uint8 _toX, 
        uint8 _toY
    )    
        private 
        pure 
        returns (bool) 
    {
        return ((_fX >= 1) && (_fY >=1)  && (_toX <= 100) && (_toY <= 100) 
            && (_fX <= _toX) && (_fY <= _toY));
        // TODO need to limit total number of blocks here?
    }
}