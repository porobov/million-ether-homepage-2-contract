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
import "./Owned.sol";

contract MillionEther is Owned{

    // Seller contract
    uint public ethUSDCentsPrice;  //1 eth price in cents  // TODO remove, delegate to Oracle Proxy
    
    // Counters
    uint public charityPayed = 0;
    uint public numImages = 0;
    uint16  public blocksSold = 0;


    // minimal access needed
    // owner
    // oracle
    // moderator

/*
    // CAPABILITIES 
    
    owner (cold wallet)
    // set admin? - no! 
    // transfer ownership
    // transfer charity funds
    // collect income
    // kill

    admin (cold wallet)
    // set admin
    // set oracle
    // set moderator
    // set server host
    oracle (contract)
    // update dollar price
    moderator (hot wallet)
    // ban users
    // update pictures at will
    server host (hot wallet)
    // collect fees nothing (ordinary user)

*/
    // owner - transfer ownership, transfer charity
    string constant ROLE_ADMIN = "admin";  // super-admin  set roles
    string constant ROLE_ORACLE = "oracle";  // push ETHUSD price 
    string constant ROLE_MODERATOR = "moderator";  // ban users
    
    // Balances
    mapping(address => uint) public balances;   //charity purposes too
    address constant public charityInternalAddress = 0x616c6C20796F75206e656564206973206C6f7665; // "all you need is love" in hex format. Insures nobody has access to it. Used for internal acounting only. 

    // External contracts
    OldeMillionEther oldMillionEther;
    MEStorage strg;
    // OracleProxy oracleProxy;
    // AccessControl accessControl;

    // Events  //TODO indexed
    event NewAreaStatus (uint ID, uint8 fromX, uint8 fromY, uint8 toX, uint8 toY, uint price);
    event NewImage(uint ID, uint8 fromX, uint8 fromY, uint8 toX, uint8 toY, string imageSourceUrl, string adUrl, string adText);


// ** INITIALIZE ** //

    function MillionEther (address _strgAddr, address _oldMillionEtherAddr) public {
        oldMillionEther = OldeMillionEther(_oldMillionEtherAddr);
        strg = MEStorage(_strgAddr);
        ethUSDCentsPrice = 100000;  // $1000
    }


// ** FUNCTION MODIFIERS (PERMISSIONS) ** //

    modifier onlyForSale (uint8 _x, uint8 _y) {
        require(strg.getBlockOwner(_x, _y) == address(0x0));  // TODO || blocks[_x][_y].sellPrice != 0));
        _;
    }

    modifier onlyLegalCoordinates (uint8 _fromX, uint8 _fromY, uint8 _toX, uint8 _toY) { // , bool checkAuth) {
        require ((_fromX >= 1) && (_fromY >=1)  && (_toX <= 100) && (_toY <= 100));
        require ((_fromX <= _toX) && (_fromY <= _toY));  //TODO > 100 area check
        _;
    }

    modifier onlyByLandlord (uint8 _x, uint8 _y) {
        if (msg.sender != owner) {  // TODO remove??
            require(strg.getBlockOwner(_x, _y) == msg.sender);
        }
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
        uint balance = balances[_recipient];
        require (balance + _amount >= balance); // need >= to be able to put 0 credits //checking for overflow  // TODO safemath or something
        balances[_recipient] = balance + _amount;
        return true;
    }

    function deductFrom(address _payer, uint _amount) public returns (bool) {  // TODO private
        uint balance = balances[_payer];
        require (balance >= _amount);
        balances[_payer] = balance - _amount;
        return true;
    }

    // reward admin and charity
    function payOwnerAndCharity (uint _amount) public {  // TODO private
        uint goesToCharity = _amount * charityPercent(blocksSold) / 100;
        depositTo(charityInternalAddress, goesToCharity);
        depositTo(owner, _amount - goesToCharity);
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


    function getBlockPrice (uint8 _x, uint8 _y, uint8 _iBlocksSold) public view returns (uint, address) {
        if (strg.getBlockOwner(_x, _y) == address(0x0)) { 
            // when buying at initial sale price doubles every 1000 blocks sold
            // return (oneDollarInWei * crowdsaleUSDPrice(_iBlocksSold), address(0x0));
            return (convertUSDtoWEI(crowdsaleUSDPrice(_iBlocksSold), ethUSDCentsPrice), address(0x0));
        } else {
            // the block is already bought and landlord have set a sell price
            return (strg.getSellPrice(_x, _y), strg.getBlockOwner(_x, _y));
        }
    }

    function setNewBlockOwner(uint8 _x, uint8 _y, address _newOwner) public returns (bool) {  //TODO make private
        strg.setBlockOwner(_x, _y, _newOwner);
        //blocks[_x][_y].landlord = _newOwner;
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
        strg.setSellPrice(x, y, sellPrice);
    }

    // sell an area of blocks at coordinates [fromX, fromY, toX, toY]
    // priceForEachBlockInWei = 0 - not for sale
    function sellBlocks (uint8 fromX, uint8 fromY, uint8 toX, uint8 toY, uint priceForEachBlockInWei) 
        external 
        onlyLegalCoordinates (fromX, fromY, toX, toY)
        returns (bool) 
    {
        for (uint8 ix=fromX; ix<=toX; ix++) {
            for (uint8 iy=fromY; iy<=toY; iy++) {
                sellBlock (ix, iy, priceForEachBlockInWei);
            }
        }
        return true;
    }

// ** RENT AND RENT OUT BLOCKS ** //
//
//
//



// ** ASSIGNING IMAGES ** //

    // place new ad to user owned area
    function placeImage (uint8 fromX, uint8 fromY, uint8 toX, uint8 toY, string imageSourceUrl, string adUrl, string adText) 
        public 
        // TODO no banned users
        onlyLegalCoordinates(fromX, fromY, toX, toY)
        returns (uint) 
    {   
        for (uint8 ix=fromX; ix<=toX; ix++) {
            for (uint8 iy=fromY; iy<=toY; iy++) {
                require(strg.getBlockOwner(ix, iy) == msg.sender); // || msg.sender == owner);  //TODO renter too 
            }
        }
        numImages++;
        NewImage(numImages, fromX, fromY, toX, toY, imageSourceUrl, adUrl, adText);  // TODO add emit at production
        return numImages;
    }

// ** ETHUSD PRICE ORACLE
    // function sync_eth_usd_price() {
    //     ethUSDCentsPrice = oracle.getEthUsdCentsPrice();
    // }

// ** CHARITY TRANSFER ** //
    // function transfer_charity(address some_charity, uint amount) only_owner {
    //     deductFrom(charityAddress, amount)
    //     depositTo(some_charity, amount)
    //     charityPayed++
    //     Event charity transfered(to addr, amount, now)
    // }

    // function getTotalCharity() public returns (uint) {return balances['0x0'] + charityPayed}

// ** INFO ** //

    function getBlockInfo(uint8 x, uint8 y) 
        public view returns (address, uint, address, uint, uint) 
    {
        address landlord = strg.getBlockOwner(x, y);
        uint sellPrice = strg.getSellPrice(x, y);
        address renter = strg.getRenter(x, y);
        uint hourlyRent = strg.getHourlyRent(x, y);
        uint rentedTill = strg.getRentedTill(x, y);
        return (landlord, sellPrice, renter, hourlyRent, rentedTill);
    }

// ** IMPORT OLD CONTRACT DATA ** //

    function import_old_me(uint8 _x, uint8 _y) public returns (bool) {
        require(strg.getBlockOwner(_x, _y) == address(0x0));
        address landlord;
        uint imageID;
        uint sellPrice;
        (landlord, imageID, sellPrice) = oldMillionEther.getBlockInfo(_x, _y);
        require(landlord != address(0x0));
        setNewBlockOwner(_x, _y, landlord);
        incrementBlocksSold(1);  //increment blocksSold by 1
        return true;
    }


  //   function withdrawPayments() public { //zeppelin
  //       address payee = msg.sender;
  //       uint256 payment = payments[payee];

  //       require(payment != 0);
  //       require(this.balance >= payment);

  //       totalPayments = totalPayments.sub(payment);
  //       payments[payee] = 0;

  //       assert(payee.send(payment));
  // }

  // Admin
      // function setOracle(address _newOracleAddress) onlyOwner returns (bool) {
    //     oracleAddres = _newOracleAddress;
    //     return true;
    // }

    // function setInterface() onlyOwner returns (bool) {
    //     millionEtherAddress = _millionEtherAddress;
    //     return true;
    // }
}