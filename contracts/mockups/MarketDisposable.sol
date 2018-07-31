pragma solidity ^0.4.24;    

import "../Market.sol";

/// Not for production. Functionality added for testing and cleanup purposes only. 
contract MarketDisposable is Market {
    
    constructor(
        address _mehAddress, 
        address _oldMehAddress, 
        address _oracleProxyAddress
    ) 
        Market(_mehAddress, _oldMehAddress, _oracleProxyAddress) 
    {}

    function usdPrice(uint256 blocksSold) public view returns (uint256) {
        return crowdsalePriceUSD(blocksSold);
    }
}