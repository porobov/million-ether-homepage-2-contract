pragma solidity ^0.4.18;

import "./Market.sol";
import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-solidity/contracts/token/ERC721/ERC721Basic.sol";
import "openzeppelin-solidity/contracts/token/ERC721/ERC721Token.sol";

contract MEH is ERC721Token("MillionEtherHomePage","MEH"), Ownable, Destructible  {

    bool public isMEH = true;
    Market market;  

    // Accounting
    mapping(address => uint) public balances;
    address public constant charityVault = 0x616c6C20796F75206e656564206973206C6f7665; // "all you need is love" in hex format. Insures nobody has access to it. Used for internal acounting only. 
    uint public charityPayed = 0;

    // Counters
    uint public numOwnershipStatuses = 0;
    uint public numImages = 0;


// GUARDS

    // function instead of modifier as modifier used too much stack for placeImage and rentBlocks
    function isLegalCoordinates(uint8 _fromX, uint8 _fromY, uint8 _toX, uint8 _toY) private pure returns (bool) {
        return ((_fromX >= 1) && (_fromY >=1)  && (_toX <= 100) && (_toY <= 100) 
            && (_fromX <= _toX) && (_fromY <= _toY));
    }

    modifier onlyMarket() {
        require(msg.sender == market);
        _;
    }

// ERC721 

    function _setMEHApprovalForAll(address _landlord) internal {
        if (!(isApprovedForAll(_landlord, market))) {
            require(_landlord == msg.sender);
            operatorApprovals[_landlord][market] = true;
            emit ApprovalForAll(_landlord, market, true);
        }
    }

    function _mint(address _to, uint256 _tokenId) public onlyMarket {
        if (totalSupply() <= 9999) {
        _mint(_to, _tokenId);
        }
    }

// ** PAYMENT PROCESSING ** //


    //production: function depositTo(address _recipient, uint _amount) private {
    function _depositTo(address _recipient, uint _amount) public onlyMarket {
        balances[_recipient] = add(balances[_recipient], _amount);
    }

    //production: function deductFrom(address _payer, uint _amount) private {
    function _deductFrom(address _payer, uint _amount) public onlyMarket {
        balances[_payer] = sub(balances[_payer], _amount);
    }

    function withdraw() external {
        address payee = msg.sender;
        uint256 payment = balances[payee];

        require(payment != 0);
        require(this.balance >= payment);

        balances[payee] = 0;

        assert(payee.send(payment));
    }

 // ** BUY AND SELL BLOCKS ** //

    function getBlockID (uint8 _x, uint8 _y) public pure returns (uint16) {
        return (uint16(_y) - 1) * 100 + uint16(_x);
    }

    function buyArea(uint8 fromX, uint8 fromY, uint8 toX, uint8 toY) 
        external
        payable
    {   
        require(isLegalCoordinates(fromX, fromY, toX, toY));
        depositTo(msg.sender, msg.value);

        for (uint8 ix=fromX; ix<=toX; ix++) {
            for (uint8 iy=fromY; iy<=toY; iy++) {
                market.buyBlock(msg.sender, getBlockID(ix, iy));
            }
        }
        // numOwnershipStatuses++;
        // emit LogOwnership(numOwnershipStatuses, fromX, fromY, toX, toY, msg.sender, 0);
    }


    // sell an area of blocks at coordinates [fromX, fromY, toX, toY]
    // (priceForEachBlockCents = 0 - not for sale)
    function sellArea(uint8 fromX, uint8 fromY, uint8 toX, uint8 toY, uint priceForEachBlockCents) 
        external 
    {   
        require(isLegalCoordinates(fromX, fromY, toX, toY));

        _setMEHApprovalForAll(msg.sender);

        for (uint8 ix=fromX; ix<=toX; ix++) {
            for (uint8 iy=fromY; iy<=toY; iy++) {
                market._sellBlock(msg.sender, getBlockID(ix, iy), priceForEachBlockCents);
            }
        }
        // numOwnershipStatuses++;
        // emit LogOwnership(numOwnershipStatuses, fromX, fromY, toX, toY, address(0x0), priceForEachBlockCents);
    }


// ** ADMIN ** //

// ** CONNECTIVITY ** //

    // credits to cryptokittes!
    // NOTE: verify that a contract is what we expect - https://github.com/Lunyr/crowdsale-contracts/blob/cfadd15986c30521d8ba7d5b6f57b4fefcc7ac38/contracts/LunyrToken.sol#L117
    function adminSetMarket(address _address) external onlyOwner {
        Market candidateContract = Market(_address);
        require(candidateContract.isMarket());
        market = candidateContract;
    }

    function adminSetRentals(address _address) external onlyOwner {
        Market candidateContract = Market(_address);
        require(candidateContract.isMarket());
        market = candidateContract;
    }

    function adminSetAds(address _address) external onlyOwner {
        Market candidateContract = Market(_address);
        require(candidateContract.isMarket());
        market = candidateContract;
    }

    // Emergency
    //TODO withdraw all
    //TODO pause-upause
}