pragma solidity ^0.4.24;    

import "./MehERC721.sol";
import "./Accounting.sol";

contract MEH is MehERC721, Accounting {

    // Counters
    uint public numOwnershipStatuses = 0;
    uint public numImages = 0;

 // ** BUY AND SELL BLOCKS ** //

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

    function buyArea(uint8 fromX, uint8 fromY, uint8 toX, uint8 toY) 
        external
        whenNotPaused
        payable
    {   
        require(isLegalCoordinates(fromX, fromY, toX, toY));
        _depositTo(msg.sender, msg.value);

        for (uint8 ix=fromX; ix<=toX; ix++) {
            for (uint8 iy=fromY; iy<=toY; iy++) {
                market._buyBlock(msg.sender, blockID(ix, iy));
            }
        }
        // numOwnershipStatuses++;
        // emit LogOwnership(numOwnershipStatuses, fromX, fromY, toX, toY, msg.sender, 0);
    }


    // sell an area of blocks at coordinates [fromX, fromY, toX, toY]
    // (priceForEachBlockCents = 0 - not for sale)
    function sellArea(uint8 fromX, uint8 fromY, uint8 toX, uint8 toY, uint priceForEachBlockWei) 
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


// ** INFO GETTERS ** //

    function getBlockOwner(uint8 x, uint8 y) external view returns (address) {
        return ownerOf(blockID(x, y));
    }

    // Emergency
    //TODO withdraw all
    //TODO pause-upause
}