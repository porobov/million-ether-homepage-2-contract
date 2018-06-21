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

import "../installed_contracts/math.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/ownership/HasNoEther.sol";
import "openzeppelin-solidity/contracts/lifecycle/Destructible.sol";  // production is immortal
import "./OldeMillionEther.sol";
import "./MEH.sol";
import "../test/OracleProxy.sol";

contract Market is Ownable, Destructible, HasNoEther, DSMath {

    

    // Charity
    address public constant charityVault = 0x616c6C20796F75206e656564206973206C6f7665; // "all you need is love" in hex format. Insures nobody has access to it. Used for internal acounting only. 
    uint public charityPayed = 0;

    // Contracts
    bool public isMarket = true;
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

    modifier onlyMeh() {
        require(msg.sender == address(meh));
        _;
    }

// ** PAYMENT PROCESSING ** //

    /// @dev Reward admin and charity
    /// @notice Just for admin convinience. 
    ///  Admin is allowed to transfer charity to any account. 
    ///  Function helps to separate personal funds from charity.
    function depositToAdminAndCharity(uint _amount) internal {
        uint goesToCharity = _amount * 80 / 100;  // 80% goes to charity
        meh._depositTo(charityVault, goesToCharity);
        meh._depositTo(owner, _amount - goesToCharity);
    }

 // ** BUY AND SELL BLOCKS ** //

    function _mintCrowdsaleBlock(address _to, uint16 _blockId) internal {
        meh._mintCrowdsaleBlock(_to, _blockId);
    }

    /// @dev Transfer seller's tokens to this contract
    function _escrow(address _from, uint16 _blockId) internal {
        meh.transferFrom(_from, address(this), _blockId);
    }

    function _transferTo(address _to, uint16 _blockId) internal {
        meh.safeTransferFrom(address(this), _to, _blockId);
        return;
    }

    function _ownerOf(uint16 _blockId) internal returns (address) {
        return meh._ownerOf(_blockId);
    }

    // doubles price every 1000 blocks sold
    function crowdsalePriceUSD(uint16 _blocksSold) internal pure returns (uint16) {
        return uint16(1 * (2 ** (_blocksSold / 1000)));  // check overflow?
    }

    function crowdsalePriceWei() internal returns (uint) {
        return mul(mul(usd.oneCentInWei(), crowdsalePriceUSD(uint16(meh.totalSupply()))), 100);
    }

    // TODO remove dollars
    function getBlockSellPrice(uint16 _blockId) internal returns (uint) {
        return (mul(usd.oneCentInWei(), priceTags[_blockId].sellPrice));
    }

    function _removePriceTag(uint16 _blockId) internal {
        delete priceTags[_blockId];
    }

    function buyBlock(address _buyer, uint16 _blockId)
        external onlyMeh
    {
        address blockOwner = _ownerOf(_blockId);

        uint blockPrice = 0;
        // buying at crowdsale:
        if (blockOwner == address(0)) {        
            blockPrice = crowdsalePriceWei();
            meh._deductFrom(_buyer, blockPrice);
            _mintCrowdsaleBlock(_buyer, _blockId);
            depositToAdminAndCharity(blockPrice);//  pay contract owner and charity
            return;                              //  report one block bought at crowdsale
        }

        // buying from seller:
        blockPrice = getBlockSellPrice(_blockId);
        if (blockPrice > 0 && blockOwner == address(this)) {
            // require(seller != address(0));
            address seller = priceTags[_blockId].seller;
            meh._deductFrom(_buyer, blockPrice);
            _transferTo(_buyer, _blockId);
            _removePriceTag(_blockId);
            meh._depositTo(seller, blockPrice);   //  pay seller
            return;                            //  report zero blocks bought at crowdsale
        }
        revert();  // revert when no conditions are met
    }


    // nobody has access to block ownership except current landlord
    // function instead of modifier as modifier used too much stack for placeImage
    function isAuthorizedSeller(address _guy, uint16 _blockId) private view returns (bool) {
        address blockOwner = _ownerOf(_blockId);
        address seller = priceTags[_blockId].seller;
        return (_guy == blockOwner || _guy == seller);
    }

    /// @dev Trnsfer blockId to market, set or update price tag. Return block to seller.
    /// @notice _sellPriceWei = 0 - cancel sale, return blockId to seller
    function _sellBlock(address _seller, uint16 _blockId, uint _sellPriceWei) external onlyMeh {
        // only owner or seller are allowed to set, update price or cancel
        require(isAuthorizedSeller(_seller, _blockId));
        address currentOwner = _ownerOf(_blockId);

        // cancel sale
        if (_sellPriceWei == 0) {
            require(currentOwner != _seller);  // when not yet on sale cannot cancel it
            _transferTo(_seller, _blockId);
            return;
        }

        // if not yet transfered blockId to the market
        if (currentOwner != address(this)) {
            _escrow(_seller, _blockId);
        }
        
        // set price
        priceTags[_blockId].seller = _seller;
        priceTags[_blockId].sellPrice = _sellPriceWei;
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
        emit LogNewOracleProxy(_address);
    }

    // Emergency
    //TODO return tokens
    //TODO pause-upause

}
