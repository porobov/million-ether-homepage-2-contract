pragma solidity ^0.4.24;    

import "./MehModule.sol";
import "./Rentals.sol";

contract Ads is MehModule {
    
    bool public isAds = true;
    uint public numImages = 0;  // TODO set initial state to last state of the old ME
    RentalsInterface public rentalsContract;
   
// ** INITIALIZE ** //

    constructor(address _mehAddress) MehModule(_mehAddress) public {}

// ** PLACE IMAGES ** //

    // place new ad to user owned or rented area
    function paintBlocks(
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
        require(canPaintBlocks(advertiser, _blockList));
        numImages++;
        return numImages;
    }
    //       canAdvertiseOnBlocks TODO
    function canPaintBlocks(
        address advertiser, 
        uint16[] _blockList
    ) 
        public
        view
        returns (bool)
    {   
        for (uint i = 0; i < _blockList.length; i++) {
            require(canPaintBlock(advertiser, _blockList[i]));
        }
        return true;
    }
    //       canAdvertiseOnBlock TODO
    function canPaintBlock(address _advertiser, uint16 blockId) 
        internal 
        view
        returns (bool)
    {
        if (meh.rentals().isRented(blockId)) {
            return(isRenter(_advertiser, blockId));
        } else {
            return(isBlockOwner(_advertiser, blockId));
        }
    }

    function isBlockOwner(address _advertiser, uint16 _blockId)
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
}