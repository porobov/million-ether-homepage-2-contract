pragma solidity ^0.4.18;

contract MEStorage {

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
    //Block[10001] public blocks; 
    uint16  public blocksSold = 0;

    // function MillionEther(address _oldMillionEtherAddr) public {
    //     // oldMillionEtherAddr = _oldMillionEtherAddr;
    //     ethUSDCentsPrice = 100000;  // $1000
    // }

    function setBlockOwner(uint8 _x, uint8 _y, address _newOwner) external {
        blocks[_x][_y].landlord = _newOwner;
    } 

    function getBlockOwner(uint8 _x, uint8 _y) external view returns (address) {
        return blocks[_x][_y].landlord;
    } 
}