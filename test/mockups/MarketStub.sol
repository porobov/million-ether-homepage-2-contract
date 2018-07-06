pragma solidity ^0.4.18;

import "openzeppelin-solidity/contracts/lifecycle/Destructible.sol";  // production is immortal

contract MarketStub is Destructible {
    
    bool public isMarket = true;
    uint public charityPayed = 12345;

    // function OracleProxy() {
    //     oneCentInWei = 1 wei;  // TODO remove after debug
    // }
    
    // function getOneCentInWei() external view returns (uint) {
    //     return oneCentInWei;
    // }
}