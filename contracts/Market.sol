pragma solidity ^0.4.18;

import "./MehModule.sol";
import "./mockups/OracleProxy.sol";
import "./mockups/OldeMillionEther.sol";

// @title Market: Pluggable module for MEH contract responsible for buy-sell operations including 
//  initial sale. 80% of initial sale income goes to charity. Initial sale price doubles every 1000 
//  blocks sold
// @dev this contract is unaware of xy block coordinates - ids only (ids are ERC721 tokens)
contract Market is MehModule {

    // Makes MEH contract sure it plugged in the right module 
    bool public isMarket = true;

    // The address of the previous version of The Million Ether Homepage (MEH). 
    // The previous version was published at Dec-13-2016 and was priced in ETH. As the ETH price 
    // strated to rise quickly in March 2017 the pixels became too expensive and nobody bought 
    // new pixels since then. This new version of MEH is priced in USD.
    // Old MEH is here - https://etherscan.io/address/0x15dbdB25f870f21eaf9105e68e249E0426DaE916. 
    OldeMillionEther public oldMillionEther;

    // Address of an oracle proxy, pluggable. For flexibility sake OracleProxy is a separate module. 
    // The only function of an OracleProxy is to provide usd price. Whenever a better usd Oracle 
    // comes up (with better performance, price, decentralization level, etc.) a new OracleProxy 
    // will be written and plugged.  
    OracleProxy public usd;

    // Internal charity funds vault. 80% of initial sale income goes to this vault. 
    
    // The distribution of funds among charities is done manually through a dedicated address,
    // beign used for charity purposes only. Charities in priority are published here:
    // https://github.com/porobov/charities-accepting-ether (pull requests are welcome).
    // The address string is "all you need is love" in hex format - insures nobody has access to it.
    // Builded trust (trust history) vs trust by code... todo
    address public constant charityVault = 0x616c6C20796F75206e656564206973206C6f7665; 
    uint public charityPayed = 0;

    // Map from block ID to their corresponding price tag.
    // uint256 instead of uint16 for ERC721 compliance
    mapping (uint16 => uint256) blockIdToPrice;
    
    // Keeps track of buy-sell events
    uint public numOwnershipStatuses = 0;

    // Reports
    event LogModuleUpgrade(address newAddress, string moduleName);
    event LogCharityTransfer(address charityAddress, uint amount);

// ** INITIALIZE ** //
    
    /// @dev Initialize Market contract.
    /// @param _mehAddress address of the main Million Ether Homepage contract
    /// @param _oldMehAddress address of the previous MEH version for import
    /// @param _oracleProxyAddress usd oracle address. Can be changed afterwards
    constructor(address _mehAddress, address _oldMehAddress, address _oracleProxyAddress)
        MehModule(_mehAddress)
        public
    {
        oldMillionEther = OldeMillionEther(_oldMehAddress);
        adminSetOracle(_oracleProxyAddress);
    }

// ** BUY BLOCKS ** //
    
    /// @dev Lets buy a list of blocks by block ids
    function buyBlocks(address buyer, uint16[] _blockList) 
        external
        onlyMeh
        whenNotPaused
        returns (uint)
    {   
        for (uint i = 0; i < _blockList.length; i++) {
            _buyBlock(buyer, _blockList[i]);
        }
        numOwnershipStatuses++;
        return numOwnershipStatuses;
    }

    /// @dev buys 1 block
    function _buyBlock(address _buyer, uint16 _blockId) private {
        // checks if a block id is already minted (if ERC721 token exists)
        if (exists(_blockId)) {
            // if minted it means that the block has an owner, try to by from owner
            buyOwnedBlock(_buyer, _blockId);
        } else {
            // if not minted yet, buy from crowdsale (also called initial sale here)
            buyCrowdsaleBlock(_buyer, _blockId);
        }
    }
    /// @dev buy a block (by id) from current owner (if an owner is selling)
    function buyOwnedBlock(address _buyer, uint16 _blockId) private {
        uint blockPrice = blockSellPrice(_blockId);
        address blockOwner = ownerOf(_blockId);
        require(blockPrice > 0);
        require(_buyer != blockOwner);

        // transfer funds internally (no external calls)
        transferFunds(_buyer, blockOwner, blockPrice);
        // transfer ERC721 token (block id) to a new owner
        transferNFT(blockOwner, _buyer, _blockId);
        // reset sell price
        setSellPrice(_blockId, 0);
    }

    /// @dev buy a block (by id) at crowdsale (initial sale). 
    function buyCrowdsaleBlock(address _buyer, uint16 _blockId) private {
        uint blockPrice = crowdsalePriceWei();
        transferFundsToAdminAndCharity(_buyer, blockPrice);
        // mint new ERC721 token
        mintCrowdsaleBlock(_buyer, _blockId);
    }

    /// @dev get a block sell price set by block owner
    function blockSellPrice(uint16 _blockId) private view returns (uint) {
        return blockIdToPrice[_blockId];
    }

    /// @dev calculates crowdsale (initial sale) price. Price doubles every 1000 block sold
    function crowdsalePriceWei() private view returns (uint) {
        uint256 blocksSold = meh.totalSupply();
        // get ETHUSD price from an usd price oralce
        uint256 oneCentInWei = usd.oneCentInWei();

        // sanity check (in case oracle proxy or oralce go completely mad)
        require(oneCentInWei > 0);

        // return price in wei
        return crowdsalePriceUSD(blocksSold).mul(oneCentInWei).mul(100);
    }

    /// @dev calculates price in USD. Doubles every 1000 blocks sold.
    function crowdsalePriceUSD(uint256 _blocksSold) internal pure returns (uint256) {
        // can't overflow as _blocksSold == meh.totalSupply() and meh.totalSupply() < 10000
        return 2 ** (_blocksSold / 1000);
    }

// ** SELL BLOCKS ** //
    
    /// @dev Lets seller sell a list of blocks by block ids. 
    function sellBlocks(address seller, uint priceForEachBlockWei, uint16[] _blockList) 
        external
        onlyMeh
        whenNotPaused
        returns (uint)
    {   
        for (uint i = 0; i < _blockList.length; i++) {
            require(seller == ownerOf(_blockList[i]));
            _sellBlock(_blockList[i], priceForEachBlockWei);
        }
        numOwnershipStatuses++;
        return numOwnershipStatuses;
    }

    /// @dev Sets or updates price tag for a block id.
    ///  _sellPriceWei = 0 - cancel sale
    function _sellBlock(uint16 _blockId, uint _sellPriceWei) private {
        setSellPrice(_blockId, _sellPriceWei);
    }

    function setSellPrice(uint16 _blockId, uint256 _sellPriceWei) private {
        blockIdToPrice[_blockId] = _sellPriceWei;
    }

// ** ADMIN ** //

    /// @dev transfer charity amount to an address (internally).
    function adminTransferCharity(address charityAddress, uint amount) external onlyOwner {
        require(charityAddress != owner);
        transferFunds(charityVault, charityAddress, amount);
        charityPayed += amount;
        emit LogCharityTransfer(charityAddress, amount);
    }

    /// @dev set or reset an Oracle Proxy
    function adminSetOracle(address _address) public onlyOwner {
        OracleProxy candidateContract = OracleProxy(_address);
        require(candidateContract.isOracleProxy());
        usd = candidateContract;
        emit LogModuleUpgrade(_address, "OracleProxy");  // todo 
    }

    /// @dev import old million ether contract blocks. See oldMillionEther variable 
    ///  description above for more.
    function adminImportOldMEBlock(uint8 x, uint8 y) external onlyOwner {
        uint16 blockId = meh.blockID(x, y);
        require(!(exists(blockId)));
        (address oldLandlord, uint i, uint s) = oldMillionEther.getBlockInfo(x, y);  // WARN! sell price s is in wei
        require(oldLandlord != address(0));
        mintCrowdsaleBlock(oldLandlord, blockId);
    }

// ** INFO ** //
    
    /// @dev get a sell price for a list of blocks 
    function areaPrice(uint16[] _blockList)
        external 
        view 
        returns (uint totalPrice) 
    {
        totalPrice = 0;
        for (uint i = 0; i < _blockList.length; i++) {
            // As sell price value is arbitrary add is overflow-safe here
            totalPrice = totalPrice.add(getBlockPrice(_blockList[i]));
        }
    }

    /// @dev checks if a block is on sale. Usage e.g. - permits ERC721 tokens transfer when on sale.
    function isOnSale(uint16 _blockId) public view returns (bool) {
        return (blockIdToPrice[_blockId] > 0);
    }

    function getBlockPrice(uint16 _blockId) private view returns (uint) {
        uint blockPrice = 0;
        if (exists(_blockId)) {
            blockPrice = blockSellPrice(_blockId);
            require(blockPrice > 0);
        } else {
            blockPrice = crowdsalePriceWei();
        }
        return blockPrice;
    }
    
// ** PAYMENT PROCESSING ** //

    /// @dev transfers 80% of payers funds to charity and 20% to contract owner (admin)
    function transferFundsToAdminAndCharity(address _payer, uint _amount) private {
        uint goesToCharity = _amount * 80 / 100;  // 80% goes to charity  // check for oveflow too (in case of oracle mistake)
        transferFunds(_payer, charityVault, goesToCharity);
        transferFunds(_payer, owner, _amount - goesToCharity);
    }

// ** ERC721 ** //
    
    /// @dev mint new ERC721 token
    function mintCrowdsaleBlock(address _to, uint16 _blockId) private {
        meh._mintCrowdsaleBlock(_to, _blockId);
    }

    /// @dev transfer ERC721 token
    function transferNFT(address _from, address _to, uint16 _blockId) private {
        meh.transferFrom(_from, _to, _blockId);  // safeTransfer has external call
        return;
    }
}
