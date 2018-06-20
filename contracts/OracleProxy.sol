pragma solidity ^0.4.18;

import "./Storage.sol";

contract OracleProxy is Destructible, Storage {
    
    bool public isOracleProxy = true;

    uint public oneCentInWei;

    function OracleProxy() {
        oneCentInWei = 1 wei;  // TODO remove after debug
    }
    
    function getOneCentInWei() external view returns (uint) {
        return oneCentInWei;
    }
}