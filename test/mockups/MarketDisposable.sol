pragma solidity ^0.4.24;    

import "../../contracts/Market.sol";

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