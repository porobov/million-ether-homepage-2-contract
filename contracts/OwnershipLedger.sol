pragma solidity ^0.4.18;

import "./Storage.sol";

contract OwnershipLedger is Storage {

    // Blocks
    struct Block {           //Blocks are 10x10 pixel areas. There are 10 000 blocks.
        address landlord;    //block owner
        uint sellPrice;      //price if willing to sell, 0 if not
    }
    Block[101][101] public blocks; 

    // SETTERS

    function setBlockOwner(uint8 _x, uint8 _y, address _newOwner) external onlyClient returns (bool) {
        blocks[_x][_y].landlord = _newOwner;
        return true;
    } 

    function setSellPrice(uint8 _x, uint8 _y, uint _sellPrince) external onlyClient returns (bool) {
        blocks[_x][_y].sellPrice = _sellPrince;
        return true;
    }

    // GETTERS

    function getBlockOwner(uint8 _x, uint8 _y) external view returns (address) {
        return blocks[_x][_y].landlord;
    } 

    function getSellPrice(uint8 _x, uint8 _y) external view returns (uint) {
        return blocks[_x][_y].sellPrice;
    } 

    // function getBlockID (uint8 _x, uint8 _y) public pure returns (uint16) {
    //     return (uint16(_y) - 1) * 100 + uint16(_x);
    // }
}