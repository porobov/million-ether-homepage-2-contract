pragma solidity ^0.4.24;    

import "./MehModule.sol";
import "./Rentals.sol";

contract Ads is MehModule {
    
    bool public isAds = true;
    uint public numImages = 0;
    RentalsInterface public rentalsContract;
   

    event LogImage (uint ID, string imageSourceUrl, string adUrl, string adText, address indexed advertiser);

// ** INITIALIZE ** //

    constructor(address _mehAddress) MehModule(_mehAddress) {
    }

// ** PLACE IMAGES ** //

    // nobody has access to block ownership except current landlord
    // function instead of modifier as modifier used too much stack for placeImage
    function isBlockOwner(address _advertiser, uint16 _blockId)    // TODO refactor to ownerOf - create MehModule.sol for all modules
        private 
        view 
        returns (bool) 
    {
        return (_advertiser == ownerOf(_blockId));
    }

    function isRenter(address _advertiser, uint16 _blockId)
        private 
        view 
        returns (bool) 
    {
        return (_advertiser == meh.rentals().renterOf(_blockId));
    }

    function isAllowedToAdvertise(address _advertiser, uint16 blockId) 
        public 
        view
        returns (bool)
    {
        if (meh.rentals().isRented(blockId)) {
            require(isRenter(_advertiser, blockId));
        } else {
            require(isBlockOwner(_advertiser, blockId));
        }
        return true;
    }

    function isAllowedToAdvertise(address _advertiser, uint8 _fromX, uint8 _fromY, uint8 _toX, uint8 _toY) 
        public 
        view
        returns (bool)
    {
        for (uint8 ix=_fromX; ix<=_toX; ix++) {
            for (uint8 iy=_fromY; iy<=_toY; iy++) {
                uint16 blockId = meh.blockID(ix, iy);
                if (meh.rentals().isRented(blockId)) {
                    require(isRenter(_advertiser, blockId));
                } else {
                    require(isBlockOwner(_advertiser, blockId));
                }
            }
        }
    }

    // place new ad to user owned or rented area
    function placeAds
    (
        address advertiser, 
        uint16[] _blockList,
        string imageSourceUrl, 
        string adUrl,
        string adText
    ) 
        external
        onlyMeh
        whenNotPaused
        returns (uint)
    {   
        for (uint i = 0; i < _blockList.length; i++) {
            isAllowedToAdvertise(advertiser, _blockList[i]);
        }
        emit LogImage(numImages, imageSourceUrl, adUrl, adText, advertiser);
        numImages++;
        return numImages;
    }
}