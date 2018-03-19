pragma solidity ^0.4.18;

import "./Owned.sol";

contract MEStorage is Owned{

    // main settings
    address millionEtherAddress;
    address oldMillionEtherAddress;
    address oracleAddres;

    enum level {ORACLE, FULL}
    mapping(address => level) accessLevel;

    uint public ethUSDCentsPrice;  //1 eth price in cents
    uint public numImages;
    uint8 public blocksImported;
    // address public oldMillionEtherAddr;

    // Users and balances
    uint public charityBalance = 0;
    mapping(address => uint) public balances;       //charity purposes too
    mapping(address => bool) public bannedUsers;
    address[] public addressList;

    // Blocks 1 
    struct Block {          //Blocks are 10x10 pixel areas. There are 10 000 blocks.
        address landlord;   //owner
        address renter;     //renter address
        uint sellPrice;     //price if willing to sell
        uint hourlyRent;    //rent price per day
        uint rentedTill;    //rented at day
    }
    Block[101][101] public blocks; 
    uint16  public numBlocksSold = 0;

    // Settings
    modifier access(level _level) {
        require(accessLevel[msg.sender] >= _level);
        _;
    }

    function setPermissions(address _newClient, uint8 _permissionLevel) external onlyOwner {
        accessLevel[_newClient] = level(_permissionLevel);
    }

    // function setOracle(address _newOracleAddress) onlyOwner returns (bool) {
    //     oracleAddres = _newOracleAddress;
    //     return true;
    // }

    // function setInterface() onlyOwner returns (bool) {
    //     millionEtherAddress = _millionEtherAddress;
    //     return true;
    // }

    // Users and balances
    function setBal(uint _newBal, address _user) external access(level.FULL){
        balances[_user] = _newBal;
    } 

    function getBal(address _user) external view returns (uint) {
        return balances[_user];
    }

    // Blocks
    function setBlocksSold(uint16 _blocksSold) external access(level.FULL){
        numBlocksSold = _blocksSold;
    } 

    function getBlocksSold() external view returns (uint16) {
        return numBlocksSold;
    } 

    function setBlockOwner(uint8 _x, uint8 _y, address _newOwner) external access(level.FULL){
        blocks[_x][_y].landlord = _newOwner;
    } 

    function getBlockOwner(uint8 _x, uint8 _y) external view returns (address) {
        return blocks[_x][_y].landlord;
    } 

    function setSellPrice(uint8 _x, uint8 _y, uint _sellPrince) external access(level.FULL){
        blocks[_x][_y].sellPrice = _sellPrince;
    } 

    function getSellPrice(uint8 _x, uint8 _y) external view returns (uint) {
        return blocks[_x][_y].sellPrice;
    } 
}