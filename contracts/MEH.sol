pragma solidity ^0.4.24;    

import "./MehERC721.sol";
import "./Accounting.sol";

/*
MillionEther smart contract - decentralized advertising platform.

This program is free software: you can redistribute it and/or modifromY
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

/*
* A 1000x1000 pixel field is displayed at TheMillionEtherHomepage.com. 
* This smart contract lets anyone buy 10x10 pixel blocks and place ads there.
* It also allows to sell blocks and rent them out to other advertisers. 
*
* 10x10 pixels blocks are addressed by xy coordinates. So 1000x1000 pixel field is 100 by 100 blocks.
* Making up 10 000 blocks in total. Each block is an ERC721 (non fungible token) token. 
*
* At the initial sale the price for each block is $1 (price is feeded by an oracle). After
* every 1000 blocks sold (every 10%) the price doubles. Owners can sell and rent out blocks at any
* price they want. Owners and renters can place and replace ads to their blocks as many times they 
* want.
*
* All heavy logic is delegated to external upgradable contracts. There are 4 main modules (contracts):
*     - MEH: Million Ether Homepage (MEH) contract. Provides user interface and accounting 
*         functionality. It is immutable and it keeps Non fungible ERC721 tokens (10x10 pixel blocks) 
*         ledger and eth balances. 
*     - Market: Plugable. Provides methods for buy-sell functionality, keeps buy-sell ledger, 
*         querries oracle for a ETH-USD price, 
*     - Rentals: Plugable. Provides methods for rentout-rent functionality, keeps rentout-rent ledger.
*     - Ads: Plugable. Provides methods for image placement functionality.
* 
*/

/// @title MEH: Million Ether Homepage. Buy, sell, rent out pixels and place ads.
/// @author Peter Porobov (https://keybase.io/peterporobov)
/// @notice The main contract, accounting and user interface. Immutable.
contract MEH is MehERC721, Accounting {

    /// @notice emited when an area blocks is bought
    event LogBuys(
        uint ID,
        uint8 fromX,
        uint8 fromY,
        uint8 toX,
        uint8 toY,
        address newLandlord
    );

    /// @notice emited when an area blocks is marked for sale
    event LogSells(
        uint ID,
        uint8 fromX,
        uint8 fromY,
        uint8 toX,
        uint8 toY,
        uint sellPrice
    );

    /// @notice emited when an area blocks is marked for rent
    event LogRentsOut(
        uint ID,
        uint8 fromX,
        uint8 fromY,
        uint8 toX,
        uint8 toY,
        uint rentPricePerPeriodWei
    );

    /// @notice emited when an area blocks is rented
    event LogRents(
        uint ID,
        uint8 fromX,
        uint8 fromY,
        uint8 toX,
        uint8 toY,
        uint numberOfPeriods,
        uint rentedFrom
    );

    /// @notice emited when an ad is placed to an area
    event LogAds(
        uint ID, 
        uint8 fromX,
        uint8 fromY,
        uint8 toX,
        uint8 toY,
        string imageSourceUrl,
        string adUrl,
        string adText,
        address indexed advertiser);

// ** BUY AND SELL BLOCKS ** //
    
    /// @notice lets a message sender to buy blocks within area
    /// @dev if using a contract to buy an area make sure to implement ERC721 functionality 
    ///  as tokens are transfered using "transferFrom" function and not "safeTransferFrom"
    ///  in order to avoid external calls.
    function buyArea(uint8 fromX, uint8 fromY, uint8 toX, uint8 toY) 
        external
        whenNotPaused
        payable
    {   
        // check input parameters and eth deposited
        require(isLegalCoordinates(fromX, fromY, toX, toY));
        require(canPay(areaPrice(fromX, fromY, toX, toY)));
        depositFunds();

        // try to buy blocks through market contract
        // will get an id of buy-sell operation if succeeds (if all blocks available)
        uint id = market.buyBlocks(msg.sender, blocksList(fromX, fromY, toX, toY));
        emit LogBuys(id, fromX, fromY, toX, toY, msg.sender);
    }

    /// @notice lets a message sender to mark blocks for sale at price set for each block in wei
    /// @dev (priceForEachBlockCents = 0 - not for sale)
    function sellArea(uint8 fromX, uint8 fromY, uint8 toX, uint8 toY, uint priceForEachBlockWei)
        external 
        whenNotPaused
    {   
        // check input parameters
        require(isLegalCoordinates(fromX, fromY, toX, toY));

        // try to mark blocks for sale through market contract
        // will get an id of buy-sell operation if succeeds (if owns all blocks)
        uint id = market.sellBlocks(
            msg.sender, 
            priceForEachBlockWei, 
            blocksList(fromX, fromY, toX, toY)
        );
        emit LogSells(id, fromX, fromY, toX, toY, priceForEachBlockWei);
    }

    /// @notice get area price in wei
    function areaPrice(uint8 fromX, uint8 fromY, uint8 toX, uint8 toY) 
        public 
        view 
        returns (uint) 
    {   
        // check input
        require(isLegalCoordinates(fromX, fromY, toX, toY));

        // querry areaPrice in wei at market contract
        return market.areaPrice(blocksList(fromX, fromY, toX, toY));
    }

// ** RENT OUT AND RENT BLOCKS ** //
        
    /// @notice Rent out an area of blocks at coordinates [fromX, fromY, toX, toY] at a price for 
    ///  each block in wei
    /// @dev if rentPricePerPeriodWei = 0 then makes area not available for rent
    function rentOutArea(uint8 fromX, uint8 fromY, uint8 toX, uint8 toY, uint rentPricePerPeriodWei)
        external
        whenNotPaused
    {   
        // check input
        require(isLegalCoordinates(fromX, fromY, toX, toY));

        // try to mark blocks as rented out through rentals contract
        // will get an id of rent-rentout operation if succeeds (if message sender owns blocks)
        uint id = rentals.rentOutBlocks(
            msg.sender, 
            rentPricePerPeriodWei, 
            blocksList(fromX, fromY, toX, toY)
        );
        emit LogRentsOut(id, fromX, fromY, toX, toY, rentPricePerPeriodWei);
    }
    
    /// @notice Rent an area of blocks at coordinates [fromX, fromY, toX, toY] for a number of 
    ///  periods specified
    ///  (period length is specified in rentals contract)
    function rentArea(uint8 fromX, uint8 fromY, uint8 toX, uint8 toY, uint numberOfPeriods)
        external
        payable
        whenNotPaused
    {   
        // check input parameters and eth deposited
        // checks number of periods > 0 in rentals contract
        require(isLegalCoordinates(fromX, fromY, toX, toY));
        require(canPay(areaRentPrice(fromX, fromY, toX, toY, numberOfPeriods)));
        depositFunds();

        // try to rent blocks through rentals contract
        // will get an id of rent-rentout operation if succeeds (if all blocks available for rent)
        uint id = rentals.rentBlocks(
            msg.sender, 
            numberOfPeriods, 
            blocksList(fromX, fromY, toX, toY)
        );
        emit LogRents(id, fromX, fromY, toX, toY, numberOfPeriods, 0);
    }

    /// @notice get area rent price in wei for number of periods specified 
    ///  (period length is specified in rentals contract) 
    function areaRentPrice(uint8 fromX, uint8 fromY, uint8 toX, uint8 toY, uint numberOfPeriods)
        public 
        view 
        returns (uint) 
    {   
        // check input 
        require(isLegalCoordinates(fromX, fromY, toX, toY));

        // querry areaPrice in wei at rentals contract
        return rentals.blocksRentPrice (numberOfPeriods, blocksList(fromX, fromY, toX, toY));
    }

// ** PLACE ADS ** //
    
    /// @notice places ads (image, caption and link to a website) into desired coordinates
    /// @dev nothing is stored in any of the contracts except an image id. All other data is 
    ///  only emitted in event. Basicaly this function just verifies if an event is allowed 
    ///  to be emitted.
    function placeAds( 
        uint8 fromX, 
        uint8 fromY, 
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
        require(isLegalCoordinates(fromX, fromY, toX, toY));

        // try to place ads through ads contract
        // will get an image id if succeeds (if advertiser owns or rents all blocks within area)
        uint AdsId = ads.advertiseOnBlocks(
            msg.sender, 
            blocksList(fromX, fromY, toX, toY), 
            imageSource, 
            link, 
            text
        );
        emit LogAds(AdsId, fromX, fromY, toX, toY, imageSource, link, text, msg.sender);
    }

    /// @notice check if an advertiser is allowed to put ads within area (i.e. owns or rents all 
    ///  blocks)
    function canAdvertise(
        address advertiser,
        uint8 fromX, 
        uint8 fromY, 
        uint8 toX, 
        uint8 toY
    ) 
        external
        view
        returns (bool)
    {   
        // check user input
        require(isLegalCoordinates(fromX, fromY, toX, toY));

        // querry permission at ads contract
        return ads.canAdvertiseOnBlocks(advertiser, blocksList(fromX, fromY, toX, toY));
    }

// ** IMPORT BLOCKS ** //

    /// @notice import blocks from previous version Million Ether Homepage
    function adminImportOldMEBlock(uint8 x, uint8 y) external onlyOwner {
        (uint id, address newLandlord) = market.importOldMEBlock(x, y);
        emit LogBuys(id, x, y, x, y, newLandlord);
    }

// ** INFO GETTERS ** //
    
    /// @notice get an owner(address) of block at a specified coordinates
    function getBlockOwner(uint8 x, uint8 y) external view returns (address) {
        return ownerOf(blockID(x, y));
    }

// ** UTILS ** //
    
    /// @notice get ERC721 token id corresponding to xy coordinates
    function blockID(uint8 x, uint8 y) public pure returns (uint16) {
        return (uint16(y) - 1) * 100 + uint16(x);
    }

    /// @notice get a number of blocks within area
    function countBlocks(
        uint8 fromX, 
        uint8 fromY, 
        uint8 toX, 
        uint8 toY
    ) 
        internal 
        pure 
        returns (uint16)
    {
        return (toX - fromX + 1) * (toY - fromY + 1);
    }

    /// @notice get an array of all block ids (i.e. ERC721 token ids) within area
    function blocksList(
        uint8 fromX, 
        uint8 fromY, 
        uint8 toX, 
        uint8 toY
    ) 
        internal 
        pure 
        returns (uint16[] memory r) 
    {
        uint i = 0;
        r = new uint16[](countBlocks(fromX, fromY, toX, toY));
        for (uint8 ix=fromX; ix<=toX; ix++) {
            for (uint8 iy=fromY; iy<=toY; iy++) {
                r[i] = blockID(ix, iy);
                i++;
            }
        }
    }
    
    /// @notice insures that area coordinates are within 100x100 field and 
    ///  from-coordinates >= to-coordinates
    /// @dev function is used instead of modifier as modifier 
    ///  required too much stack for placeImage and rentBlocks
    function isLegalCoordinates(
        uint8 _fromX, 
        uint8 _fromY, 
        uint8 _toX, 
        uint8 _toY
    )    
        private 
        pure 
        returns (bool) 
    {
        return ((_fromX >= 1) && (_fromY >=1)  && (_toX <= 100) && (_toY <= 100) 
            && (_fromX <= _toX) && (_fromY <= _toY));
    }
}