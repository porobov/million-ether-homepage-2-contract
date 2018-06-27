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
import "./MEH.sol";
import "../test/mockups/OracleProxy.sol";
import "../test/mockups/OldeMillionEther.sol";

contract Market is Ownable, Destructible, HasNoEther, DSMath {

    // Charity
    address public constant charityVault = 0x616c6C20796F75206e656564206973206C6f7665; // "all you need is love" in hex format. Insures nobody has access to it. Used for internal acounting only. 
    uint public charityPayed = 0;

    // Contracts
    bool public isMarket = true;
    OldeMillionEther oldMillionEther;
    MEH  meh;
    OracleProxy usd;

    // Map from block ID to their corresponding price tag.
    /// @notice uint256 instead of uint16 for ERC721 compliance
    mapping (uint16 => uint256) blockIdToPrice;

    // Events
    // price > 0 - for sale. price = 0 - sold (or marked as not for sale). address(0x0) - actions of current landlord
    event LogOwnership (uint ID, uint8 fromX, uint8 fromY, uint8 toX, uint8 toY, address indexed newLandlord, uint newPrice); 
    event LogImage     (uint ID, uint8 fromX, uint8 fromY, uint8 toX, uint8 toY, string imageSourceUrl, string adUrl, string adText, address indexed publisher);

    // Reports
    event LogNewOracleProxy(address oracleProxy);
    event LogCharityTransfer(address charityAddress, uint amount);
    event LogNewFees(uint newImagePlacementFeeCents);


// ** INITIALIZE ** //

    constructor(address _mehAddress, address _oldMehAddress, address _oracleProxyAddress) public {
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

    function depositTo(address _recipient, uint _amount) internal {
        return meh.operatorDepositTo(_recipient, _amount);
    }

    function deductFrom(address _payer, uint _amount) internal {
        return meh.operatorDeductFrom(_payer, _amount);
    }

    /// @dev Reward admin and charity
    /// @notice Just for admin convinience. 
    ///  Admin is allowed to transfer charity to any account. 
    ///  Function helps to separate personal funds from charity.
    function depositToAdminAndCharity(uint _amount) internal {
        uint goesToCharity = _amount * 80 / 100;  // 80% goes to charity
        depositTo(charityVault, goesToCharity);
        depositTo(owner, _amount - goesToCharity);
    }

// ** ERC721 ** //

    function exists(uint16 _blockId) internal view  returns (bool) {
        return meh.exists(_blockId);
    }

    function ownerOf(uint16 _blockId) internal view returns (address) {
        return meh.ownerOf(_blockId);
    }

    function mintCrowdsaleBlock(address _to, uint16 _blockId) internal {
        meh._mintCrowdsaleBlock(_to, _blockId);
    }

    function transferFrom(address _from, address _to, uint16 _blockId) internal {
        meh.safeTransferFrom(_from, _to, _blockId);
        return;
    }

// ** BUY AND SELL BLOCKS ** //

    // doubles price every 1000 blocks sold
    function crowdsalePriceUSD() internal view returns (uint16) {
        uint16 blocksSold = uint16(meh.totalSupply());
        return uint16(2 ** (blocksSold / 1000));  // check overflow?
    }

    function crowdsalePriceWei() internal view returns (uint) {
        uint256 oneCentInWei = usd.oneCentInWei();
        require(oneCentInWei > 0);
        return mul(mul(oneCentInWei, crowdsalePriceUSD()), 100);
    }

    function blockSellPrice(uint16 _blockId) internal view returns (uint) {
        return blockIdToPrice[_blockId];
    }


    function _buyBlock(address _buyer, uint16 _blockId)
        external onlyMeh
    {
        uint blockPrice = 0;
        if (exists(_blockId)) {
            // buy from current owner
            blockPrice = blockSellPrice(_blockId);
            address blockOwner = ownerOf(_blockId);
            require(blockPrice > 0);
            require(_buyer != blockOwner);
            deductFrom(_buyer, blockPrice);
            transferFrom(blockOwner, _buyer, _blockId);
            setSellPrice(_blockId, 0);
            depositTo(blockOwner, blockPrice);   //  pay seller
            return;                            //  report zero blocks bought at crowdsale
        } else { 
            // buy at crowdsale:
            blockPrice = crowdsalePriceWei();
            deductFrom(_buyer, blockPrice);
            mintCrowdsaleBlock(_buyer, _blockId);
            depositToAdminAndCharity(blockPrice);//  pay contract owner and charity
            return;                              //  report one block bought at crowdsale
        }
    }

    function isOnSale(uint16 _blockId) public view returns (bool) {
        return (blockIdToPrice[_blockId] > 0);
    }

    /// @dev Trnsfer blockId to market, set or update price tag. Return block to seller.
    /// @notice _sellPriceWei = 0 - cancel sale, return blockId to seller
    function _sellBlock(uint16 _blockId, uint _sellPriceWei) external onlyMeh {
        setSellPrice(_blockId, _sellPriceWei);
    }

    function setSellPrice(uint16 _blockId, uint256 _sellPriceWei) internal {
        blockIdToPrice[_blockId] = _sellPriceWei;
    }

// ** ADMIN ** //

    function adminSetMeh(address _address) internal onlyOwner {
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

    // import old contract blocks
    function adminImportOldMEBlock(uint8 x, uint8 y) public onlyOwner {
        uint16 blockId = meh.blockID(x, y);
        require(!(exists(blockId)));
        (address oldLandlord, uint i, uint s) = oldMillionEther.getBlockInfo(x, y);  // WARN! sell price s is in wei
        require(oldLandlord != address(0));
        mintCrowdsaleBlock(oldLandlord, blockId);
    }

    // Emergency
    //TODO return tokens
    //TODO pause-upause

}
