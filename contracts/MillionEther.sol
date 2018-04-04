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
// import "./OracleProxy.sol";
// import "./OracleProxyMockup.sol";  // for testing only

contract MillionEther is Owned{

    // External contracts
    OldeMillionEther oldMillionEther;
    MEStorage strg;

    // Admin settings
    address public oracle;
    address public moderator;
    uint public imagePlacementFeeCents;
    uint public minRentPeriodHours;
    uint public maxRentPeriodHours;

    // Accounting
    mapping(address => uint) public balances;
    address constant public charityVault = 0x616c6C20796F75206e656564206973206C6f7665; // "all you need is love" in hex format. Insures nobody has access to it. Used for internal acounting only. 
    uint public charityPayed = 0;
    uint public oneCentInWei;
    uint public imagePlacementFeeInWei;

    // Counters
    uint public numImages = 0;
    uint16  public blocksSold = 0;
    
    // Events  //TODO indexed
    event NewAreaStatus (uint ID, uint8 fromX, uint8 fromY, uint8 toX, uint8 toY, uint price);
    event NewImage(uint ID, uint8 fromX, uint8 fromY, uint8 toX, uint8 toY, string imageSourceUrl, string adUrl, string adText);

    // Reports
    event LogCharityTransfer(address charityAddress, uint amount);
    event LogNewPermissions(address oracle, address moderator, string reason);
    event LogNewFeesAndRentParams(uint newImagePlacementFeeCents, uint newMinRentPeriodHours, uint newMaxRentPeriodHours, string reason);

// ** INITIALIZE ** //

    function MillionEther (address _strgAddr, address _oldMillionEtherAddr, address _oracleProxyAddr) public {
        oldMillionEther = OldeMillionEther(_oldMillionEtherAddr);
        strg = MEStorage(_strgAddr);
        oracle = _oracleProxyAddr;
        moderator = msg.sender;

        imagePlacementFeeCents = 0;
        minRentPeriodHours = 0;
        maxRentPeriodHours = 4320;  // 3 mounths in hours
    }

// ** FUNCTION MODIFIERS (PERMISSIONS) ** //

    modifier onlyForSale(uint8 _x, uint8 _y) {
        require(strg.getBlockOwner(_x, _y) == address(0x0) || strg.getSellPrice(_x, _y) != 0);  // address(0x0) - no landlord yet, 0 - not for sale
        _;
    }

    modifier onlyForRent(uint8 _x, uint8 _y) {
        require(strg.getHourlyRent(_x, _y) != 0 && strg.getRentedTill(x, y) < now);  // hourlyRent = 0 - not for rent
        _;
    }

    modifier onlyLegalRentPeriodHours(uint _rentPeriodHours) {
        require(minRentPeriodHours < _rentPeriodHours && _rentPeriodHours < maxRentPeriodHours)
        _;
    }

    modifier onlyLegalCoordinates(uint8 _fromX, uint8 _fromY, uint8 _toX, uint8 _toY) { // , bool checkAuth) {
        require ((_fromX >= 1) && (_fromY >=1)  && (_toX <= 100) && (_toY <= 100));
        require ((_fromX <= _toX) && (_fromY <= _toY));  //TODO > 100 area check
        _;
    }

    modifier onlyByLandlord(uint8 _x, uint8 _y) {
        require(strg.getBlockOwner(_x, _y) == msg.sender);
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == oracle);
        _;
    }

    modifier onlyModerator() {
        require(msg.sender == moderator);
        _;
    }

    modifier noBannedUsers() {
        require(strg.getBanStatus[msg.sender] == false);
    }



 // ** PAYMENT PROCESSING ** //

    // ETHUSD price oracle
    function oracleSetOneCentInWei(uint newOneCentInWei) external onlyOracle returns (bool) {
        oneCentInWei = newOneCentInWei;
        imagePlacementFeeInWei = imagePlacementFeeCents * newOneCentInWei;
    }

    function crowdsalePriceInUSD(uint _blocksSold) public pure returns (uint) {  
        return 1 * (2 ** (_blocksSold / 1000));  // price doubles every 1000 blocks sold
    }

    function charityPercent(uint _blocksSold) public pure returns (uint) {
        return 10 * (_blocksSold / 1000);
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
        depositTo(charityVault, goesToCharity);
        depositTo(owner, _amount - goesToCharity);
    }

    // transfer charity to an address (internally)
    function transferCharity(address charityAddress, uint amount) external only_owner {
        deductFrom(charityVault, amount);
        depositTo(charityAddress, amount);
        charityPayedOut++;
        LogCharityTransfer(charityAddress, amount);
    }

    function withdrawPayments() public { //zeppelin // TODO 
        address payee = msg.sender;
        uint256 payment = payments[payee];

        require(payment != 0);
        require(this.balance >= payment);

        totalPayments = totalPayments.sub(payment);
        payments[payee] = 0;

        assert(payee.send(payment));
    }



 // ** BUY AND SELL BLOCKS ** //

    function getBlockPriceAndOwner (uint8 _x, uint8 _y, uint8 _iBlocksSold) public view returns (uint, address) {
        if (strg.getBlockOwner(_x, _y) == address(0x0)) { 
            // when buying at initial sale price doubles every 1000 blocks sold
            return (oneCentInWei * 100 * crowdsalePriceInUSD(_iBlocksSold), address(0x0));
        } else {
            // the block is already bought and landlord have set a sell price
            return (strg.getSellPrice(_x, _y), strg.getBlockOwner(_x, _y));
        }
    }

    function setNewBlockOwner(uint8 _x, uint8 _y, address _newOwner) public returns (bool) {  //TODO make private
        strg.setBlockOwner(_x, _y, _newOwner);
        return true;
    }

    function incrementBlocksSold(uint16 _iBlocksSold) public { //TODO make private
        blocksSold += _iBlocksSold;
    }

    function payBlockOwner(address _blockOwner, uint _blockPrice) public returns (uint8){ //TODO private
        uint8 iBlocksSold = 0;
        // Buy at initial sale
        if (_blockOwner == address(0x0)) {
            payOwnerAndCharity(_blockPrice);
            iBlocksSold = 1;
        // Buy from current landlord and pay them _blockPrice
        } else {
            depositTo(_blockOwner, _blockPrice);
        }
        return iBlocksSold;
    }

    function buyBlock (uint8 x, uint8 y, uint8 _iBlocksSold)
        private
        onlyForSale (x, y)
        returns (uint8)
    {
        uint blockPrice;
        address blockOwner;
        (blockPrice, blockOwner) = getBlockPriceAndOwner(x, y, _iBlocksSold);
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
    
    function rentBlock (uint8 x, uint8 y, uint rentPeriodHours)
        private
        onlyLegalRentPeriodHours(rentPeriodHours)
        onlyForRent (x, y)
        returns (bool)
    {
        uint horlyRent = strg.getHourlyRent(x, y);
        uint rentPrice = horlyRent * rentPeriodHours;
        deductFrom(msg.sender, rentPrice);

        address blockOwner = strg.getBlockOwner(x, y);
        depositTo(blockOwner, rentPrice);

        uint rentedTill = rentPeriodHours * 3600 + now;  // convert to seconds
        strg.setRentedTill(x, y, rentedTill);
        strg.setRenter(x, y, msg.sender);
        return true;
    }

    function rentBlocks (uint8 fromX, uint8 fromY, uint8 toX, uint8 toY, uint rentPeriodHours) 
        external
        payable
        onlyLegalCoordinates (fromX, fromY, toX, toY)
        returns (bool) 
    {   
        depositTo(msg.sender, msg.value);
        // perform rentBlock for coordinates [fromX, fromY, toX, toY] and withdraw funds
        for (uint8 ix=fromX; ix<=toX; ix++) {
            for (uint8 iy=fromY; iy<=toY; iy++) {
                rentBlock(ix, iy, rentPeriodHours);
            }
        }
        return true;
    }

    //Mark block for rent (set a hourly rent price)
    function rentOutBlock (uint8 x, uint8 y, uint hourlyRent) 
        private
        onlyByLandlord (x, y) 
    {   
        strg.setHourlyRent(x, y, hourlyRent);
    }

    // rent out an area of blocks at coordinates [fromX, fromY, toX, toY]
    // hourlyRentForEachBlockInWei = 0 - not for rent
    function rentOutBlocks (uint8 fromX, uint8 fromY, uint8 toX, uint8 toY, uint hourlyRentForEachBlockInWei) 
        external 
        onlyLegalCoordinates (fromX, fromY, toX, toY)
        returns (bool)
    {
        for (uint8 ix=fromX; ix<=toX; ix++) {
            for (uint8 iy=fromY; iy<=toY; iy++) {
                rentOutBlock (ix, iy, hourlyRentForEachBlockInWei);
            }
        }
        return true;
    }



// ** PLACE IMAGES ** //

    function chargeForImagePlacement() private {
        depositTo(msg.sender, msg.value);
        deductFrom(msg.sender, imagePlacementFeeInWei); 
        depositTo(owner, imagePlacementFeeInWei);
    }

    // place new ad to user owned area
    function placeImage (uint8 fromX, uint8 fromY, uint8 toX, uint8 toY, string imageSourceUrl, string adUrl, string adText) 
        external
        payable
        noBannedUsers
        onlyLegalCoordinates(fromX, fromY, toX, toY)
        returns (uint) 
    {   
        chargeForImagePlacement();
        for (uint8 ix=fromX; ix<=toX; ix++) {
            for (uint8 iy=fromY; iy<=toY; iy++) {
                require(
                    msg.sender == moderator ||
                    msg.sender == strg.getBlockOwner(ix, iy) ||
                    msg.sender == strg.getRenter(x, y,)
                );
            }
        }
        numImages++;
        NewImage(numImages, fromX, fromY, toX, toY, imageSourceUrl, adUrl, adText);  // TODO add emit at production
        return numImages;
    }




// ** INFO GETTERS ** //
    
    // TODO remove
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

    function getCharityTurnOver() external view returns (uint) {
        return balances[charityVault] + charityPayed;
    }

// ** SETTINGS ** //

    function adminPermissions(address newOracle, address newModerator, string reason) external onlyOwner {
        if (newOracle != address(0x0)) { oracle = newOracle };
        if (newModerator != address(0x0)) { moderator = newModerator };
        LogNewPermissions(newOracle, newModerator, reason);
    }

    function adminFeesAndRentParams(
        uint newImagePlacementFeeCents, 
        uint newMinRentPeriodHours, 
        uint newMaxRentPeriodHours,
        string reason) 
    external 
    onlyOwner
    {
        imagePlacementFeeCents = newImagePlacementFeeCents;
        minRentPeriodHours = newMinRentPeriodHours;
        maxRentPeriodHours = newMaxRentPeriodHours;
        LogNewFeesAndRentParams(newImagePlacementFeeCents, newMinRentPeriodHours, newMaxRentPeriodHours, reason);
    }
    
    // import old contract blocks
    function adminImportOldMEBlock(uint8 x, uint8 y) public onlyOwner returns (bool) {
        require(strg.getBlockOwner(x, y) == address(0x0));
        address landlord;
        uint imageID;
        uint sellPrice;
        (landlord, imageID, sellPrice) = oldMillionEther.getBlockInfo(x, y);
        require(landlord != address(0x0));
        setNewBlockOwner(x, y, landlord);
        incrementBlocksSold(1);  //increment blocksSold by 1
        return true;
    }

    function moderatorBanUser(address user, bool ban) external onlyModerator returns (bool) {
        strg.setBanStatus(user, ban);
        return true;
        }
    }

// TODO fallback
// TODO kill

}