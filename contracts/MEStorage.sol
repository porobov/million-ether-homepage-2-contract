pragma solidity ^0.4.18;

import "./Owned.sol";

contract MEStorage is Owned{

    // Access
    address millionEtherAddress;
    enum level {NONE, ORACLE, FULL}
    mapping(address => level) public accessLevel;

    // Blocks
    struct Block {          //Blocks are 10x10 pixel areas. There are 10 000 blocks.
        address landlord;   //owner
        address renter;     //renter address
        uint sellPrice;     //price if willing to sell
        uint hourlyRent;    //rent price per day
        uint rentedTill;    //rented at day
    }
    Block[101][101] public blocks; 

    // Moderation
    mapping(address => bool) public bannedUsers;  // Allowed only to buy/sell, rent blocks. Not allowed to place images. 

    modifier access(level _level) {
        require(accessLevel[msg.sender] >= _level);
        _;
    }

    function setPermissions(address _newClient, uint8 _permissionLevel) external onlyOwner {
        accessLevel[_newClient] = level(_permissionLevel);
    }

    // Blocks

    // function getBlockID (uint8 _x, uint8 _y) public pure returns (uint16) {
    //     return (uint16(_y) - 1) * 100 + uint16(_x);
    // }

    function setBlockOwner(uint8 _x, uint8 _y, address _newOwner) external access(level.FULL){
        blocks[_x][_y].landlord = _newOwner;
    } 

    function setSellPrice(uint8 _x, uint8 _y, uint _sellPrince) external access(level.FULL){
        blocks[_x][_y].sellPrice = _sellPrince;
    } 

    function getBlockOwner(uint8 _x, uint8 _y) external view returns (address) {
        return blocks[_x][_y].landlord;
    } 

    function getSellPrice(uint8 _x, uint8 _y) external view returns (uint) {
        return blocks[_x][_y].sellPrice;
    } 

    function getRenter(uint8 _x, uint8 _y) external view returns (address) {
        return address(0x0);
    } 

    function getHourlyRent(uint8 _x, uint8 _y) external view returns (uint) {
        return 0;
    } 

    function getRentedTill(uint8 _x, uint8 _y) external view returns (uint) {
        return 0;
    } 

    // TODO fallback function
}