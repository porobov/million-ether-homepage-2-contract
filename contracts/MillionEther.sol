/*
MillionEther smart contract - decentralized advertising platform.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

pragma solidity ^0.4.18;

import "./OldeMillionEther.sol";
import "./MEStorage.sol";

contract Owned {
  address public owner;

  //@dev The Owned constructor sets the original `owner` of the contract to the sender
  //account.
  function Owned() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

contract MillionEther is Owned{

    uint public ethUSDCentsPrice;  //1 eth price in cents
    uint public numImages;
    uint8 public blocksImported;
    // address public oldMillionEtherAddr;
    OldeMillionEther oldMillionEther;
    MEStorage meStorage;

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

    

    // Events  //TODO indexed
    event NewAreaStatus (uint ID, uint8 fromX, uint8 fromY, uint8 toX, uint8 toY, uint price);
    event NewImage(uint ID, uint8 fromX, uint8 fromY, uint8 toX, uint8 toY, string imageSourceUrl, string adUrl, string adText);


// ** INITIALIZE ** //

    function MillionEther (address _meStorageAddr, address _oldMillionEtherAddr) public {
        // oldMillionEtherAddr = _oldMillionEtherAddr;
        oldMillionEther = OldeMillionEther(_oldMillionEtherAddr);
        meStorage = MEStorage(_meStorageAddr);
        ethUSDCentsPrice = 100000;  // $1000
    }

    function sBlockOwner(uint8 _x, uint8 _y, address _newOwner) public {
        meStorage.setBlockOwner(_x, _y, _newOwner);
    }
    function getBlockOwner(uint8 _x, uint8 _y) public returns (address) {
        return meStorage.getBlockOwner(_x, _y);
    }

// ** FUNCTION MODIFIERS (PERMISSIONS) ** //

    modifier onlyForSale (uint8 _x, uint8 _y) {
        require(blocks[_x][_y].landlord == address(0x0));  //|| blocks[_x][_y].sellPrice != 0));
        _;
    }

    modifier onlyLegalCoordinates (uint8 _fromX, uint8 _fromY, uint8 _toX, uint8 _toY) { // , bool checkAuth) {
        require ((_fromX >= 1) && (_fromY >=1)  && (_toX <= 100) && (_toY <= 100));
        require ((_fromX <= _toX) && (_fromY <= _toY));
        _;
    }

    modifier onlyAuthorized (uint8 _x, uint8 _y) {
        require(blocks[_x][_y].landlord == msg.sender || blocks[_x][_y].landlord == owner);
        _;
    }

    modifier onlyByLandlord (uint8 _x, uint8 _y) {
        if (msg.sender != owner) {
            require(blocks[_x][_y].landlord == msg.sender);
        }
        _;
    }

    modifier onlyLegalPrice(uint _price) {
        require(_price > 0);
        _;
    }

 // ** PAYMENT PROCESSING ** //

    function crowdsaleUSDPrice(uint _blocksSold) public pure returns (uint) {  
        return 1 * (2 ** (_blocksSold / 1000));  // price doubles every 1000 blocks sold
    }

    function charityPercent(uint _blocksSold) public pure returns (uint) {
        return 10 * (_blocksSold / 1000);
    }

    function convertUSDtoWEI(uint _usd, uint _ethUSDCentsPrice) public pure  returns (uint) { // TODO private
        return 1 ether * 100 * _usd / _ethUSDCentsPrice;
    }

    function depositTo(address _recipient, uint _amount) public returns (bool) { // TODO private
        require (balances[_recipient] + _amount > balances[_recipient]); //checking for overflow
        balances[_recipient] += _amount;
        return true;
    }

    function deductFrom(address _payer, uint _amount) public returns (bool) {  // TODO private
        require (balances[_payer] >= _amount);
        balances[_payer] -= _amount;
        return true;
    }

    // reward admin and charity
    function payOwnerAndCharity (uint _amount) public {  // TODO private
        uint goesToCharity = _amount * charityPercent(blocksSold) / 100;
        charityBalance += goesToCharity;
        depositTo(owner, _amount - goesToCharity);  //TODO check negative balance
    }

    function payBlockOwner(address _blockOwner, uint _blockPrice) public returns (uint8){ //TODO private
        uint8 iBlocksSold = 0;
        // Buy at initial sale
        if (_blockOwner == address(0x0)) {
            payOwnerAndCharity(_blockPrice);
            iBlocksSold = 1;
        // Buy from current landlord and pay him or her the _blockPrice
        } else {
            depositTo(_blockOwner, _blockPrice);
        }
        return iBlocksSold;
    }

 // ** BUY AND SELL BLOCKS ** //

    // function getBlockID (uint8 _x, uint8 _y) public pure returns (uint16) {
    //     return (uint16(_y) - 1) * 100 + uint16(_x);
    // }

    function getBlockPrice (uint8 _x, uint8 _y, uint8 _iBlocksSold) public view returns (uint, address) {
        if (blocks[_x][_y].landlord == address(0x0)) { 
            // when buying at initial sale price doubles every 1000 blocks sold
            return (convertUSDtoWEI(crowdsaleUSDPrice(_iBlocksSold), ethUSDCentsPrice), address(0x0));
        } else {
            // the block is already bought and landlord have set a sell price
            return (blocks[_x][_y].sellPrice, blocks[_x][_y].landlord);
        }
    }

    function setNewBlockOwner(uint8 x, uint8 y, address _newOnwer) public returns (bool) {  //TODO make private
        // blocks[x][y].landlord = _newOnwer;
        sBlockOwner(x, y, _newOnwer);
        return true;
    }

    function incrementBlocksSold(uint16 _iBlocksSold) public { //TODO make private
        blocksSold += _iBlocksSold;
    }

    function buyBlock (uint8 x, uint8 y, uint8 _iBlocksSold)
        private
        onlyForSale (x, y)
        returns (uint8)
    {
        uint blockPrice;
        address blockOwner;
        (blockPrice, blockOwner) = getBlockPrice(x, y, _iBlocksSold);
        deductFrom(msg.sender, blockPrice);
        setNewBlockOwner(x, y, msg.sender);
        return payBlockOwner(blockOwner, blockPrice);
    }

    function buyBlocks (uint8 fromX, uint8 fromY, uint8 toX, uint8 toY) 
        external
        payable
        onlyLegalCoordinates (fromX, fromY, toX, toY)
        returns (uint) 
    {   
        depositTo(msg.sender, msg.value);
        // perform buyBlock for coordinates [fromX, fromY, toX, toY] and withdraw funds
        uint8 iBlocksSold = 0;
        for (uint8 ix=fromX; ix<=toX; ix++) {
            for (uint8 iy=fromY; iy<=toY; iy++) {
                iBlocksSold += buyBlock(ix, iy, iBlocksSold);  // TODO assert everywhere iBlocksSold <=255;
            }
        }
        incrementBlocksSold(iBlocksSold);  //TODO overflow assert
        return iBlocksSold;
    }

    //Mark block for sale (set a sell price)
    function sellBlock (uint8 x, uint8 y, uint sellPrice) 
        private
        onlyByLandlord (x, y) 
    {
        blocks[x][y].sellPrice = sellPrice;
    }

    // sell an area of blocks at coordinates [fromX, fromY, toX, toY]
    function sellBlocks (uint8 fromX, uint8 fromY, uint8 toX, uint8 toY, uint priceForEachBlockInWei) 
        external 
        onlyLegalCoordinates (fromX, fromY, toX, toY)
        onlyLegalPrice(priceForEachBlockInWei)
        returns (bool) 
    {
        for (uint8 ix=fromX; ix<=toX; ix++) {
            for (uint8 iy=fromY; iy<=toY; iy++) {
                sellBlock (ix, iy, priceForEachBlockInWei);
            }
        }
        return true;
    }



// ** ASSIGNING IMAGES ** //

    // place new ad to user owned area
    function checkAuth (uint8 x, uint8 y) 
        public
        view
        onlyAuthorized (x, y)
        returns (bool)
    {
        return true;
    }

    // place new ad to user owned area
    function placeImage (uint8 fromX, uint8 fromY, uint8 toX, uint8 toY, string imageSourceUrl, string adUrl, string adText) 
        public 
        onlyLegalCoordinates(fromX, fromY, toX, toY)
        returns (uint) 
    {
        for (uint8 ix=fromX; ix<=toX; ix++) {
            for (uint8 iy=fromY; iy<=toY; iy++) {
                checkAuth (ix, iy);
            }
        }
        numImages++;
        NewImage(numImages, fromX, fromY, toX, toY, imageSourceUrl, adUrl, adText);  // TODO add emit at production
        return numImages;
    }


// ** IMPORT OLD CONTRACT DATA ** //



    function import_old_me(uint8 _x, uint8 _y) public returns (bool) {
        require(blocksImported <= 105);  //why 105?!
        require(blocks[_x][_y].landlord == address(0x0));
        address landlord;
        uint imageID; 
        uint sellPrice;
        (landlord, imageID, sellPrice) = oldMillionEther.getBlockInfo(_x, _y);
        require(landlord != address(0x0));
        blocks[_x][_y].landlord = landlord;
        blocksImported++;
        return true;
    }
}