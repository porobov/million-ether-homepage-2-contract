pragma solidity ^0.4.18;

import "./Market.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/lifecycle/Pausable.sol";

contract MEHAccessControl is Ownable, Pausable {

    bool public isMEH = true;
    Market market;

// GUARDS

    modifier onlyMarket() {
        require(msg.sender == address(market));
        _;
    }

// ** Admin set Access ** //

    // credits to cryptokittes!
    // NOTE: verify that a contract is what we expect - https://github.com/Lunyr/crowdsale-contracts/blob/cfadd15986c30521d8ba7d5b6f57b4fefcc7ac38/contracts/LunyrToken.sol#L117
    function adminSetMarket(address _address) external onlyOwner { //whenPaused {    // TODO 
        Market candidateContract = Market(_address);
        require(candidateContract.isMarket());
        market = candidateContract;
    }

    function adminSetRentals(address _address) external onlyOwner whenPaused {
        Market candidateContract = Market(_address);
        require(candidateContract.isMarket());
        market = candidateContract;
    }

    function adminSetAds(address _address) external onlyOwner whenPaused {
        Market candidateContract = Market(_address);
        require(candidateContract.isMarket());
        market = candidateContract;
    }
}