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

//import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
//import "openzeppelin-solidity/contracts/lifecycle/Destructible.sol";
//import "../installed_contracts/math.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/ownership/HasNoEther.sol";
import "openzeppelin-solidity/contracts/lifecycle/Destructible.sol";  // production is immortal
import "./OldeMillionEther.sol";
import "./OwnershipLedger.sol";
import "./OracleProxy.sol";

contract Market is Ownable, Destructible, HasNoEther {

    bool public isMarket = true;

    // External contracts
    OldeMillionEther oldMillionEther;
    MEH  meh;
    OracleProxy usd;

    // Blocks
    struct PriceTag {
        address seller;    // block landlord becomes seller
        uint sellPrice;    // price if willing to sell, 0 if not
    }

    // Map from block ID to their corresponding price tag.
    /// @notice uint256 instead of uint16 for ERC721 compliance
    mapping (uint256 => PriceTag) priceTags;
    
    // Events
    // price > 0 - for sale. price = 0 - sold (or marked as not for sale). address(0x0) - actions of current landlord
    event LogOwnership (uint ID, uint8 fromX, uint8 fromY, uint8 toX, uint8 toY, address indexed newLandlord, uint newPrice); 
    event LogImage     (uint ID, uint8 fromX, uint8 fromY, uint8 toX, uint8 toY, string imageSourceUrl, string adUrl, string adText, address indexed publisher);

    // Reports
    event LogNewOracleProxy(address oracleProxy);
    event LogCharityTransfer(address charityAddress, uint amount);
    event LogNewFees(uint newImagePlacementFeeCents);
    event LogContractUpgrade(address newAddress, string ContractName);

// ** INITIALIZE ** //

    function Market(address _mehAddress, address _oldMehAddress, address _oracleProxyAddress) public {
        oldMillionEther = OldeMillionEther(_oldMehAddress);
        // TODO some test on OldeMillionEther
        adminSetMeh(_mehAddress);
        adminSetOracle(_oracleProxyAddress);
    }

// ** GUARDS ** //


// ** PAYMENT PROCESSING ** //

    /// @dev Reward admin and charity
    /// @notice Just for admin convinience. 
    ///  Admin is allowed to transfer charity to any account. 
    ///  Function helps to separate personal funds from charity.
    // production: function depositToAdminAndCharity(uint _amount) private {
    function depositToAdminAndCharity(uint _amount) internal {
        uint goesToCharity = _amount * 80 / 100;  // 80% goes to charity
        meh.depositTo(charityVault, goesToCharity);
        meh.depositTo(owner, _amount - goesToCharity);
    }

 // ** BUY AND SELL BLOCKS ** //

    function _mintCrowdsaleBlock(address _to, uint16 _blockID) internal {
        meh.mint(_to, _blockID);
    }

    function _escrow(uint16 _blockID) internal {
        meh.transferFrom(_seller, address(this), _blockID);
    }

    function _transferTo(uint16 _blockID, address to) internal {
        meh.safeTransferFrom(address(this), to, _blockID);
    }

    function _ownerOf(uint256 _blockID) internal returns (address) {
        if (meh.exists(_blockID)) {
            return meh.ownerOf(_blockID);
        }
        return address(0);
    }

    // doubles price every 1000 blocks sold
    //production: function crowdsalePriceUSD(uint16 _blocksSold) private pure returns (uint16) {
    function crowdsalePrice() internal returns (uint) {
        return mul(mul(usd.getOneCentInWei(), crowdsalePriceUSD(uint16(meh.totalSupply()))), 100);
    }

    // TODO remove dollars
    function getBlockSellPrice(uint256 _blockId) internal returns (uint) {
        return (mul(usd.getOneCentInWei(), priceTags[_blockID].sellPrice));
    }

    function _removePriceTag(uint256 _blockId) internal {
        delete priceTags[_blockId];
    }

    function buyBlock(uint256 _blockId, address _buyer)
        external onlyMeh
    {
        address blockOwner = _ownerOf(_blockID);

        uint blockPrice = 0;
        // buying at crowdsale:
        if (blockOwner == address(0)) {        
            blockPrice = crowdsalePrice();
            meh.deductFrom(_buyer, blockPrice);
            _mintCrowdsaleBlock(_buyer, _blockID);
            depositToAdminAndCharity(blockPrice);//  pay contract owner and charity
            return;                              //  report one block bought at crowdsale
        }

        // buying from current landlord:
        blockPrice = getBlockSellPrice(_blockID);
        if (blockPrice > 0 && blockOwner != address(0)) {
            meh.deductFrom(_buyer, blockPrice);
            _transferTo(_buyer, _blockID);
            _removePriceTag(_blockID);
            meh.depositTo(blockOwner, blockPrice);   //  pay block owner
            return;                            //  report zero blocks bought at crowdsale
        }
        revert();  // revert when no conditions are met
    }


    // nobody has access to block ownership except current landlord
    // function instead of modifier as modifier used too much stack for placeImage
    function isAuthorizedSeller(address _guy, uint256 _blockID) private view returns (bool) {
        address blockOwner = _ownerOf(_blockID);
        address seller = priceTags[_blockID].seller;
        return (_guy == blockOwner || _guy == seller);
    }

    /// @dev Trnsfer blockId to market, set or update price tag. Return block to seller.
    /// @notice _sellPriceWei = 0 - cancel sale, return blockId to seller
    function _sellBlock(address _seller, uint _blockID, uint _sellPriceWei) external onlyMeh {
        // only owner or seller are allowed to set, update price or cancel
        require(isAuthorizedSeller(_seller, blockID));
        address currentOwner = _ownerOf(_blockID);

        // cancel sale
        if (_sellPriceWei == 0) {
            require(currentOwner != _seller);  // when not yet on sale cannot cancel it
            _transferTo(_seller, _blockID);
            return;
        }

        // if not yet transfered blockId to the market
        if (currentOwner != address(this)) {
            _escrow(_seller, _blockID);
        }
        
        // set price
        priceTags[blockID].seller = _sellPriceWei;
        priceTags[blockID].sellPrice = _seller;
    }

// ** ADMIN ** //

    function adminSetMeh(address _address) public onlyOwner {
        MEH candidateContract = MEH(_address);
        require(candidateContract.isMEH());
        meh = candidateContract;
    }

    function adminSetOracle(address _address) public onlyOwner {
        OracleProxy candidateContract = OracleProxy(_address);
        require(candidateContract.isOracleProxy());
        usd = candidateContract;
        // emit ContractUpgrade(_v2Address);
        emit LogNewOracleProxy(oracleProxyAddr);
    }

    // Emergency
    //TODO return tokens
    //TODO pause-upause

    // fallback
    function() public { }
}
