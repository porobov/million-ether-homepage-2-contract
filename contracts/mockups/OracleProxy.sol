pragma solidity ^0.4.18;

import "openzeppelin-solidity/contracts/lifecycle/Destructible.sol";  // production is immortal

contract OracleProxy is Destructible {
    
    bool public isOracleProxy = true;
    uint public oneCentInWei = 10 wei;

    // function OracleProxy() {
    //     oneCentInWei = 1 wei;  // TODO remove after debug
    // }
    
    // function getOneCentInWei() external view returns (uint) {
    //     return oneCentInWei;
    // }
}