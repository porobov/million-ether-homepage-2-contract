pragma solidity ^0.4.18;

import "./Ownable.sol";
import "./HasNoEther.sol";
import "./Destructible.sol"; // production is immortal

contract MEStorage is Ownable, HasNoEther, Destructible {  // production but is immortal

    // Access
    address millionEtherAddress;

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


    // PERMISSIONS

    modifier onlyMillionEther() {
        require(msg.sender == millionEtherAddress);
        _;
    }

    function adminSetMEAddress(address millionEtherAddr) external onlyOwner {
        millionEtherAddress = millionEtherAddr;
    }

    // SETTERS

    function setBlockOwner(uint8 _x, uint8 _y, address _newOwner) external onlyMillionEther returns (bool) {
        blocks[_x][_y].landlord = _newOwner;
        return true;
    } 

    function setSellPrice(uint8 _x, uint8 _y, uint _sellPrince) external onlyMillionEther returns (bool) {
        blocks[_x][_y].sellPrice = _sellPrince;
        return true;
    }

    function setRenter(uint8 _x, uint8 _y, address _newRenter) external onlyMillionEther returns (bool) {
        blocks[_x][_y].renter = _newRenter;
        return true;
    }

    function setHourlyRent(uint8 _x, uint8 _y, uint _rentPrice) external onlyMillionEther returns (bool) {
        blocks[_x][_y].rentPrice = _rentPrice;
        return true;
    }

    function setRentedTill(uint8 _x, uint8 _y, uint _rentedTill) external onlyMillionEther returns (bool) {
        blocks[_x][_y].rentedTill = _rentedTill;
        return true;
    }

    function setBanStatus(address _user, bool _ban) external onlyMillionEther returns (bool) {
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