pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/lifecycle/Pausable.sol";

contract MarketInerface {
    function isMarket() public returns (bool) {}
    // function _buyBlock(address, uint16) external {}
    // function _sellBlock(uint16, uint) external {}
    function buyBlocks(address, uint16[]) external {}
    function sellBlocks(address, uint, uint16[]) external {}
    function isOnSale(uint16) public view returns (bool) {}
    // function areaPrice(uint8, uint8, uint8, uint8) public view returns (uint) {}
    function areaPrice(uint16[] memory) public view returns (uint) {}
}

contract RentalsInterface {
    function isRentals() public returns (bool) {}
    function rentOutBlock(uint16, uint) external {}
    function rentBlock (address, uint16, uint) external {}
    function rentPriceAndAvailability(uint16) public view returns (uint) {}
    function isRented(uint16) public view returns (bool) {}
    function renterOf(uint16) public view returns (address) {}
}

contract AdsInterface {
    function isAds() public returns (bool) {}
    function placeImage(address, uint8, uint8, uint8, uint8, string, string, string) external {}
    function isAllowedToAdvertise(address, uint8, uint8, uint8, uint8) public view returns (bool) {}
}

contract MEHAccessControl is Pausable {

    bool public isMEH = true;
    MarketInerface public market;
    RentalsInterface public rentals;
    AdsInterface public ads;

    event LogContractUpgrade(address newAddress, string ContractName);
    
// GUARDS

    modifier onlyMarket() {
        require(msg.sender == address(market));
        _;
    }

    modifier onlyBalanceOperators() {
        require(msg.sender == address(market) || msg.sender == address(rentals));
        _;
    }

// ** Admin set Access ** //

    // credits to cryptokittes!
    // NOTE: verify that a contract is what we expect - https://github.com/Lunyr/crowdsale-contracts/blob/cfadd15986c30521d8ba7d5b6f57b4fefcc7ac38/contracts/LunyrToken.sol#L117
    function adminSetMarket(address _address) external onlyOwner { //whenPaused {    // TODO 
        MarketInerface candidateContract = MarketInerface(_address);
        require(candidateContract.isMarket());
        market = candidateContract;
    }

    function adminSetRentals(address _address) external onlyOwner { //whenPaused {    // TODO 
        RentalsInterface candidateContract = RentalsInterface(_address);
        require(candidateContract.isRentals());
        rentals = candidateContract;
    }

    function adminSetAds(address _address) external onlyOwner { //whenPaused {    // TODO
        AdsInterface candidateContract = AdsInterface(_address);
        require(candidateContract.isAds());
        ads = candidateContract;
    }
}