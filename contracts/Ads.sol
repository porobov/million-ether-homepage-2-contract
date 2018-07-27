pragma solidity ^0.4.24;    

import "./MehModule.sol";
import "./Rentals.sol";

// @title Ads: Pluggable module for MEH contract responsible publishing ads.
contract Ads is MehModule {
    
    // For MEH contract to be sure it plugged the right module in
    bool public isAds = true;

    // Keeps track of ads ids. Initial state represents the last image id of the previous 
    // version of the million ether homepage. See Market contract for more details. 
    uint public numImages = 0;  // TODO

    // Needs rentals contract to get block rent status
    RentalsInterface public rentalsContract;
   
// ** INITIALIZE ** //
    
    /// @dev Initialize Ads contract.
    /// @param _mehAddress address of the main Million Ether Homepage contract
    constructor(address _mehAddress) MehModule(_mehAddress) public {}

// ** PLACE IMAGES ** //

    /// @dev Places new ad to user owned or rented list of blocks. Returns new image id on success,
    ///  throws if user is not authorized to advertise (neither an owner nor renter). 
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

    ///        canAdvertiseOnBlocks TODO
    /// @dev Checks if user is authorized to advertise on all blocks in list (is an owner or renter).
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
    /// @dev Checks if user is authorized to advertise on a block (rents or owns a block).
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

    /// @dev Checks if user owns a block (through main MEH contract)
    function isBlockOwner(address _advertiser, uint16 _blockId)
        private 
        view 
        returns (bool) 
    {
        return (_advertiser == ownerOf(_blockId));
    }

    /// @dev Checks if user rents a block (through Rentals contract)
    function isRenter(address _advertiser, uint16 _blockId)
        private 
        view 
        returns (bool) 
    {
        return (_advertiser == meh.rentals().renterOf(_blockId));
    }
}