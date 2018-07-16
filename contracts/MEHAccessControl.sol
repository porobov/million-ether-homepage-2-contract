pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/lifecycle/Pausable.sol";

contract MarketInerface {
    function buyBlocks(address, uint16[]) external returns (uint) {}
    function sellBlocks(address, uint, uint16[]) external returns (uint) {}
    function isMarket() public returns (bool) {}  // todo view
    function isOnSale(uint16) public view returns (bool) {}
    function areaPrice(uint16[] memory) public view returns (uint) {}
}

contract RentalsInterface {
    // function rentOutBlock(uint16, uint) external {}
    // function rentBlock (address, uint16, uint) external {}
    // function rentPriceAndAvailability(uint16) public view returns (uint) {}
    function rentOutBlocks(address, uint, uint16[]) external returns (uint) {}
    function rentBlocks(address, uint, uint16[]) external returns (uint) {}
    function blocksRentPrice(uint, uint16[]) external view returns (uint) {}
    function isRentals() public returns (bool) {}  // todo view
    function isRented(uint16) public view returns (bool) {}
    function renterOf(uint16) public view returns (address) {}
}

contract AdsInterface {
    function paintBlocks(address, uint16[], string, string, string) external returns (uint) {}
    function canPaintBlocks(address, uint16[]) public view returns (bool) {}
    function isAds() public view returns (bool) {}
}

contract MEHAccessControl is Pausable {

    bool public isMEH = true;
    MarketInerface public market;
    RentalsInterface public rentals;
    AdsInterface public ads;

    event LogModuleUpgrade(address newAddress, string moduleName);
    
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
        emit LogModuleUpgrade(_address, "Market");
    }

    function adminSetRentals(address _address) external onlyOwner { //whenPaused {    // TODO 
        RentalsInterface candidateContract = RentalsInterface(_address);
        require(candidateContract.isRentals());
        rentals = candidateContract;
        emit LogModuleUpgrade(_address, "Rentals");
    }

    function adminSetAds(address _address) external onlyOwner { //whenPaused {    // TODO
        AdsInterface candidateContract = AdsInterface(_address);
        require(candidateContract.isAds());
        ads = candidateContract;
        emit LogModuleUpgrade(_address, "Ads");
    }
}