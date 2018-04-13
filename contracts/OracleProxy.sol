pragma solidity ^0.4.18;

import "./Storage.sol";

contract OracleProxy is Destructible, Storage {
    
    uint public oneCentInWei;

    function OracleProxy() {
        oneCentInWei = 1;  // TODO remove after debug
    }
    
    function getOneCentInWei() external view returns (uint) {
        return oneCentInWei;
    }
}