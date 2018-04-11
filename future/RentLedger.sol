pragma solidity ^0.4.18;

import "../installed_contracts/Ownable.sol"; 
import "../installed_contracts/HasNoEther.sol";
import "../installed_contracts/Destructible.sol"; // production is immortal

contract MEStorage is Ownable, HasNoEther, Destructible, HasAuthorizedAccess {  // production but is immortal

    // Blocks
    struct Block {           //Blocks are 10x10 pixel areas. There are 10 000 blocks.
        address landlord;    //block owner
        uint sellPrice;      //price if willing to sell, 0 if not
        address renter;      //block renter
        uint rentSecondPrice;//rent price per second
        uint rentedTill;     //after this timestamp rent is over
    }
    Block[101][101] public blocks; 

    // Moderation
    mapping(address => bool) public bannedUsers;  // these users are not allowed to place images

    // SETTERS

    function setBlockOwner(uint8 _x, uint8 _y, address _newOwner) external auth returns (bool) {
        blocks[_x][_y].landlord = _newOwner;
        return true;
    } 

    function setSellPrice(uint8 _x, uint8 _y, uint _sellPrince) external auth returns (bool) {
        blocks[_x][_y].sellPrice = _sellPrince;
        return true;
    }

    function setRenter(uint8 _x, uint8 _y, address _newRenter) external auth returns (bool) {
        blocks[_x][_y].renter = _newRenter;
        return true;
    }

    function setHourlyRent(uint8 _x, uint8 _y, uint _rentPrice) external auth returns (bool) {
        blocks[_x][_y].rentPrice = _rentPrice;
        return true;
    }

    function setRentedTill(uint8 _x, uint8 _y, uint _rentedTill) external auth returns (bool) {
        blocks[_x][_y].rentedTill = _rentedTill;
        return true;
    }

    function setBanStatus(address _user, bool _ban) external auth returns (bool) {
        bannedUsers[_user] = _ban;
        return true;
    }


    // GETTERS

    function getBlockOwner(uint8 _x, uint8 _y) external view returns (address) {
        return blocks[_x][_y].landlord;
    } 

    function getSellPrice(uint8 _x, uint8 _y) external view returns (uint) {
        return blocks[_x][_y].sellPrice;
    } 

    function getRenter(uint8 _x, uint8 _y) external view returns (address) {
        return blocks[_x][_y].renter;
    } 

    function getHourlyRent(uint8 _x, uint8 _y) external view returns (uint) {
        return blocks[_x][_y].rentPrice;
    } 

    function getRentedTill(uint8 _x, uint8 _y) external view returns (uint) {
        return blocks[_x][_y].rentedTill;
    }

    function getBanStatus(address _user) external view returns (bool) {
        return bannedUsers[_user];
    }

    // function getBlockID (uint8 _x, uint8 _y) public pure returns (uint16) {
    //     return (uint16(_y) - 1) * 100 + uint16(_x);
    // }
}