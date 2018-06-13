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

import "../installed_contracts/Ownable.sol"; 
import "../installed_contracts/Destructible.sol";
import "../installed_contracts/math.sol";
import "./OldeMillionEther.sol";
import "./OwnershipLedger.sol";
import "./OracleProxy.sol";

contract MillionEther is Ownable, DSMath, Destructible {

    // External contracts
    OldeMillionEther oldMillionEther;
    OwnershipLedger  strg; // ownrs
    OracleProxy usd;  // orcl

    // Admin settings
    uint    public imagePlacementFeeCents;

    // Accounting
    mapping(address => uint) public balances;
    address public constant charityVault = 0x616c6C20796F75206e656564206973206C6f7665; // "all you need is love" in hex format. Insures nobody has access to it. Used for internal acounting only. 
    uint public charityPayed = 0;

    // Counters
    uint16  public blocksSold = 0;
    uint public numOwnershipStatuses = 0;
    uint public numImages = 0;
    
    // Events
    // price > 0 - for sale. price = 0 - sold (or marked as not for sale). address(0x0) - actions of current landlord
    event LogOwnership (uint ID, uint8 fromX, uint8 fromY, uint8 toX, uint8 toY, address indexed newLandlord, uint newPrice); 
    event LogImage     (uint ID, uint8 fromX, uint8 fromY, uint8 toX, uint8 toY, string imageSourceUrl, string adUrl, string adText, address indexed publisher);

    // Reports
    event LogNewOracleProxy(address oracleProxy, string reason);
    event LogCharityTransfer(address charityAddress, uint amount, string reason);
    event LogNewFees(uint newImagePlacementFeeCents, string reason);

// ** INITIALIZE ** //

    function MillionEther (address _strgAddr, address _oldMillionEtherAddr, address _oracleProxyAddr) public {
        oldMillionEther = OldeMillionEther(_oldMillionEtherAddr);
        
        strg = OwnershipLedger(_strgAddr);
        require(strg.isStorage());

        adminSetOracle(_oracleProxyAddr, "init");

        imagePlacementFeeCents = 0;
    }

// ** MODIFIERS ** //

    modifier onlyForSale(uint8 _x, uint8 _y) {
        require(strg.getBlockOwner(_x, _y) == address(0x0) || strg.getSellPrice(_x, _y) != 0);  // address(0x0) - no landlord yet, 0 - not for sale
        _;
    }

    // function instead of modifier as modifier used too much stack for placeImage and rentBlocks
    function requireLegalCoordinates(uint8 _fromX, uint8 _fromY, uint8 _toX, uint8 _toY) private pure {
        require ((_fromX >= 1) && (_fromY >=1)  && (_toX <= 100) && (_toY <= 100));
        require ((_fromX <= _toX) && (_fromY <= _toY));
    }

    // nobody has access to block ownership except current landlord
    // function instead of modifier as modifier used too much stack for placeImage
    function requireBlockOwnership(uint8 _x, uint8 _y) private view {
        require(msg.sender == strg.getBlockOwner(_x, _y));
    }



 // ** PAYMENT PROCESSING ** //


    //production: function depositTo(address _recipient, uint _amount) private {
    function depositTo(address _recipient, uint _amount) public {
        balances[_recipient] = add(balances[_recipient], _amount);
    }

    //production: function deductFrom(address _payer, uint _amount) private {
    function deductFrom(address _payer, uint _amount) public {
        balances[_payer] = sub(balances[_payer], _amount);
    }

    // reward admin and charity
    //production: function depositToAdminAndCharity(uint _amount) private {
    function depositToAdminAndCharity(uint _amount) public {
        uint goesToCharity = _amount * 80 / 100;  // 80% goes to charity
        depositTo(charityVault, goesToCharity);
        depositTo(owner, _amount - goesToCharity);
    }

    function withdraw() public {
        address payee = msg.sender;
        uint256 payment = balances[payee];

        require(payment != 0);
        require(this.balance >= payment);

        balances[payee] = 0;

        assert(payee.send(payment));
    }



 // ** BUY AND SELL BLOCKS ** //

    // doubles price every 1000 blocks sold
    //production: function crowdsalePriceUSD(uint16 _blocksSold) private pure returns (uint16) {
    function crowdsalePriceUSD(uint16 _blocksSold) public pure returns (uint16) {
        return uint16(1 * (2 ** (_blocksSold / 1000)));  // check overflow?
    }

    // TODO private?? 
    function getBlockPriceAndOwner(uint8 _x, uint8 _y, uint16 _iBlocksSold) private view returns (uint, address) {
        if (strg.getBlockOwner(_x, _y) == address(0x0)) { 
            // when buying at initial sale price doubles every 1000 blocks sold
            return (mul(mul(usd.getOneCentInWei(), crowdsalePriceUSD(_iBlocksSold)), 100), address(0x0));
        } else {
            // the block is already bought and landlord have set a sell price
            return (mul(usd.getOneCentInWei(), strg.getSellPrice(_x, _y)), strg.getBlockOwner(_x, _y));
        }
    }

    function incrementBlocksSold(uint16 _iBlocksSold) public { //production make private
        assert(blocksSold + _iBlocksSold >= blocksSold);
        blocksSold += _iBlocksSold;
        assert(blocksSold <= 10000);  // total blocks available
    }

    function buyBlock(uint8 x, uint8 y, uint16 _iBlocksSold)
        private
        onlyForSale (x, y)
        returns (uint16)
    {
        uint blockPrice;
        address blockOwner;
        (blockPrice, blockOwner) = getBlockPriceAndOwner(x, y, _iBlocksSold);

        // deduct from buyer
        deductFrom(msg.sender, blockPrice);

        // set new block owner
        strg.setBlockOwner(x, y, msg.sender);
        
        // deposit to seller
        if (blockOwner == address(0x0)) {        // buying at crowdsale:
            depositToAdminAndCharity(blockPrice);//  pay contract owner and charity
            return 1;                            //  report one block bought at crowdsale
        } else {                                 // buying from current landlord:
            strg.setSellPrice(x, y, 0);          //  reset sell price
            depositTo(blockOwner, blockPrice);   //  pay block owner
            return 0;                            //  report zero blocks bought at crowdsale
        }
    }

    function buyArea(uint8 fromX, uint8 fromY, uint8 toX, uint8 toY) 
        external
        payable
        returns (uint16) 
    {   
        requireLegalCoordinates(fromX, fromY, toX, toY);
        depositTo(msg.sender, msg.value);

        uint16 iBlocksSold = 0;
        for (uint8 ix=fromX; ix<=toX; ix++) {
            for (uint8 iy=fromY; iy<=toY; iy++) {
                iBlocksSold += buyBlock(ix, iy, iBlocksSold);
            }
        }
        incrementBlocksSold(iBlocksSold);  // put outside for-loops to save gas
        numOwnershipStatuses++;
        LogOwnership(numOwnershipStatuses, fromX, fromY, toX, toY, msg.sender, 0);
        return iBlocksSold;
    }

    //Mark block for sale (set a sell price)
    function sellBlock (uint8 x, uint8 y, uint sellPriceCents) 
        private
    {   
        requireBlockOwnership(x, y);
        strg.setSellPrice(x, y, sellPriceCents);
    }

    // sell an area of blocks at coordinates [fromX, fromY, toX, toY]
    // (priceForEachBlockCents = 0 - not for sale)
    function sellArea (uint8 fromX, uint8 fromY, uint8 toX, uint8 toY, uint priceForEachBlockCents) 
        external 
        returns (bool) 
    {   
        mul(priceForEachBlockCents, usd.getOneCentInWei());  // try multiply now to prevent overflow when buying
        requireLegalCoordinates(fromX, fromY, toX, toY);

        for (uint8 ix=fromX; ix<=toX; ix++) {
            for (uint8 iy=fromY; iy<=toY; iy++) {
                sellBlock (ix, iy, priceForEachBlockCents);
            }
        }
        numOwnershipStatuses++;
        LogOwnership(numOwnershipStatuses, fromX, fromY, toX, toY, address(0x0), priceForEachBlockCents);
        return true;
    }



// ** PLACE IMAGES ** //

    function requireAreaOwnership(uint8 _fromX, uint8 _fromY, uint8 _toX, uint8 _toY) private view {
        for (uint8 ix=_fromX; ix<=_toX; ix++) {
            for (uint8 iy=_fromY; iy<=_toY; iy++) {
                requireBlockOwnership(ix, iy);
            }
        }
    }

    function chargeForImagePlacement() private {
        depositTo(msg.sender, msg.value);
        uint imagePlacementFeeInWei = mul(imagePlacementFeeCents, usd.getOneCentInWei()); 
        deductFrom(msg.sender, imagePlacementFeeInWei);
        depositTo(owner, imagePlacementFeeInWei);
    }

    // place new ad to user owned or rented area
    function placeImage(uint8 fromX, uint8 fromY, uint8 toX, uint8 toY, string imageSourceUrl, string adUrl, string adText) 
        external
        payable
        returns (uint)
    {   
        requireLegalCoordinates(fromX, fromY, toX, toY);
        requireAreaOwnership(fromX, fromY, toX, toY);
        chargeForImagePlacement();
        numImages++;
        LogImage(numImages, fromX, fromY, toX, toY, imageSourceUrl, adUrl, adText, msg.sender);  // production add emit 
        return numImages;
    }


// ** INFO GETTERS ** //

    function getCharityTurnOver() external view returns (uint) {
        return balances[charityVault] + charityPayed;
    }

    function getAreaPrice(uint8 fromX, uint8 fromY, uint8 toX, uint8 toY) external view returns (uint) {
        requireLegalCoordinates(fromX, fromY, toX, toY);
        uint totalPrice = 0;
        uint blockPrice;
        address blockOwner;
        uint16 iblocksSold = blocksSold;
        for (uint8 ix=fromX; ix<=toX; ix++) {
            for (uint8 iy=fromY; iy<=toY; iy++) {
                (blockPrice, blockOwner) = getBlockPriceAndOwner(ix, iy, iblocksSold);
                if (blockOwner == address(0x0)) { 
                        iblocksSold ++; 
                    }
                if (blockPrice == 0) { 
                    return 0; // not for sale
                    } 
                totalPrice += blockPrice;
            }
        }
        return totalPrice;
    }

// ** SETTINGS ** //

    // transfer charity to an address (internally)
    function adminTransferCharity(address charityAddress, uint amount, string reason) external onlyOwner {
        deductFrom(charityVault, amount);
        depositTo(charityAddress, amount);
        charityPayed += amount;
        LogCharityTransfer(charityAddress, amount, reason);
    }

    // set image placement fee
    function adminImagePlacementFee(uint newImagePlacementFeeCents, string reason) external onlyOwner {
        imagePlacementFeeCents = newImagePlacementFeeCents;
        LogNewFees(newImagePlacementFeeCents, reason);
    }

    function adminSetOracle(address oracleProxyAddr, string reason) public onlyOwner {
        usd = OracleProxy(oracleProxyAddr);
        require(usd.isStorage());
        LogNewOracleProxy(oracleProxyAddr, reason);
    }
    
    // import old contract blocks
    function adminImportOldMEBlock(uint8 x, uint8 y) public onlyOwner returns (bool) {
        require(strg.getBlockOwner(x, y) == address(0x0));
        address landlord;
        uint imageID;
        uint sellPrice;
        (landlord, imageID, sellPrice) = oldMillionEther.getBlockInfo(x, y);  // WARN! sell price in wei here
        require(landlord != address(0x0));
        strg.setBlockOwner(x, y, landlord);
        incrementBlocksSold(1);  //increment blocksSold by 1
        numOwnershipStatuses++;
        LogOwnership(numOwnershipStatuses, x, y, x, y, landlord, 0);
        return true;
    }

    // fallback
    function() public { }
}
