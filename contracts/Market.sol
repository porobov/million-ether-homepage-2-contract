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

import "./MehModule.sol";
import "../installed_contracts/math.sol";
import "../test/mockups/OracleProxy.sol";
import "../test/mockups/OldeMillionEther.sol";

contract Market is MehModule, DSMath {
    
    // Contracts
    bool public isMarket = true;
    OldeMillionEther public oldMillionEther;
    OracleProxy public usd;

    // Charity
    address public constant charityVault = 0x616c6C20796F75206e656564206973206C6f7665; // "all you need is love" in hex format. Insures nobody has access to it. Used for internal acounting only. 
    uint public charityPayed = 0;

    // Map from block ID to their corresponding price tag.
    /// @notice uint256 instead of uint16 for ERC721 compliance
    mapping (uint16 => uint256) blockIdToPrice;
    
    // keeps track of buy-sell events
    uint public numOwnershipStatuses = 0;

    // Reports
    event LogNewOracleProxy(address oracleProxy);
    event LogCharityTransfer(address charityAddress, uint amount);

// ** INITIALIZE ** //
    
    constructor(address _mehAddress, address _oldMehAddress, address _oracleProxyAddress)
        MehModule(_mehAddress)
        public
    {
        oldMillionEther = OldeMillionEther(_oldMehAddress);
        adminSetOracle(_oracleProxyAddress);
    }

// ** BUY BLOCKS ** //

    function buyBlocks(address buyer, uint16[] _blockList) 
        external
        onlyMeh
        whenNotPaused
        returns (uint numOwnershipStatuses)
    {   
        for (uint i = 0; i < _blockList.length; i++) {
            _buyBlock(buyer, _blockList[i]);
        }
        numOwnershipStatuses++;
    }

    function _buyBlock(address _buyer, uint16 _blockId) internal {
        uint blockPrice = 0;
        if (exists(_blockId)) {
            // buy from current owner
            blockPrice = blockSellPrice(_blockId);
            address blockOwner = ownerOf(_blockId);
            require(blockPrice > 0);
            require(_buyer != blockOwner);
            transferFunds(_buyer, blockOwner, blockPrice);
            transferNFT(blockOwner, _buyer, _blockId);
            setSellPrice(_blockId, 0);
            return;
        } else { 
            // buy at crowdsale:
            blockPrice = crowdsalePriceWei();
            transferFundsToAdminAndCharity(_buyer, blockPrice);  // pay contract owner and charity
            mintCrowdsaleBlock(_buyer, _blockId);
            return;
        }
    }

    function blockSellPrice(uint16 _blockId) internal view returns (uint) {
        return blockIdToPrice[_blockId];
    }

    function crowdsalePriceWei() internal view returns (uint) {
        uint16 blocksSold = uint16(meh.totalSupply());
        uint256 oneCentInWei = usd.oneCentInWei();
        require(oneCentInWei > 0);
        return mul(mul(oneCentInWei, crowdsalePriceUSD(blocksSold)), 100);
    }

    // doubles price every 1000 blocks sold
    function crowdsalePriceUSD(uint16 _blocksSold) internal pure returns (uint16) {
        return uint16(2 ** (_blocksSold / 1000));  // check overflow?
    }

// ** SELL BLOCKS ** //

    function sellBlocks(address seller, uint priceForEachBlockWei, uint16[] _blockList) 
        external
        onlyMeh
        whenNotPaused
        returns (uint numOwnershipStatuses)
    {   
        for (uint i = 0; i < _blockList.length; i++) {
            require(seller == ownerOf(_blockList[i]));
            _sellBlock(_blockList[i], priceForEachBlockWei);
        }
        numOwnershipStatuses++;
    }

    /// @dev Trnsfer blockId to market, set or update price tag. Return block to seller.
    /// @notice _sellPriceWei = 0 - cancel sale, return blockId to seller
    function _sellBlock(uint16 _blockId, uint _sellPriceWei) internal {
        setSellPrice(_blockId, _sellPriceWei);
    }

    function setSellPrice(uint16 _blockId, uint256 _sellPriceWei) internal {
        blockIdToPrice[_blockId] = _sellPriceWei;
    }

// ** ADMIN ** //

    // transfer charity to an address (internally)
    function adminTransferCharity(address charityAddress, uint amount) external onlyOwner {
        require(charityAddress != owner);
        transferFunds(charityVault, charityAddress, amount);
        charityPayed += amount;
        emit LogCharityTransfer(charityAddress, amount);
    }

    function adminSetOracle(address _address) public onlyOwner {
        OracleProxy candidateContract = OracleProxy(_address);
        require(candidateContract.isOracleProxy());
        usd = candidateContract;
        // emit ContractUpgrade(_v2Address);
        emit LogNewOracleProxy(_address);
    }

    // import old contract blocks
    function adminImportOldMEBlock(uint8 x, uint8 y) external onlyOwner {
        uint16 blockId = meh.blockID(x, y);
        require(!(exists(blockId)));
        (address oldLandlord, uint i, uint s) = oldMillionEther.getBlockInfo(x, y);  // WARN! sell price s is in wei
        require(oldLandlord != address(0));
        mintCrowdsaleBlock(oldLandlord, blockId);
    }

// ** INFO ** //

    function areaPrice(uint16[] memory _blockList) // todo maybe external?
        public 
        view 
        returns (uint totalPrice) 
    {
        totalPrice = 0;
        // TODO need to check ownership here? 
        for (uint i = 0; i < _blockList.length; i++) {
            totalPrice += getBlockPrice(_blockList[i]);
        }
    }

    function getBlockPrice(uint16 _blockId) view returns (uint) {
        uint blockPrice = 0;
        // TODO need to check ownership here? 
        if (exists(_blockId)) {
            blockPrice = blockSellPrice(_blockId);
            require(blockPrice > 0);
        } else {
            blockPrice = crowdsalePriceWei();
        }
        return blockPrice;
    }

    /// @notice Nobody can transfer ERC721 tokens when they are on sale.
    function isOnSale(uint16 _blockId) public view returns (bool) {  // todo remove??
        return (blockIdToPrice[_blockId] > 0);
    }
    
// ** PAYMENT PROCESSING ** //

    /// @dev Reward admin and charity
    /// @notice Just for admin convinience. 
    ///  Admin is allowed to transfer charity to any account. 
    ///  Separates personal funds from charity.
    function transferFundsToAdminAndCharity(address _payer, uint _amount) internal {
        uint goesToCharity = _amount * 80 / 100;  // 80% goes to charity
        transferFunds(_payer, charityVault, goesToCharity);
        transferFunds(_payer, owner, _amount - goesToCharity);
    }

// ** ERC721 ** //

    function mintCrowdsaleBlock(address _to, uint16 _blockId) internal {
        meh._mintCrowdsaleBlock(_to, _blockId);
    }

    function transferNFT(address _from, address _to, uint16 _blockId) internal {
        meh.transferFrom(_from, _to, _blockId);  // safeTransfer has external call
        return;
    }
}
