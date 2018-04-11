pragma solidity ^0.4.11;

import "./Ownable.sol";
import "./Destructible.sol";
import "./MillionEther.sol";

contract oracleProxyMockUp is Ownable, Destructible {
    
    MillionEther public ME;
    
    function ExampleContract(address meAddress) public payable {
        ME = MillionEther(meAddress);
    }

    function __callback(uint oneCentInWei) public {
        ME.oracleSetOneCentInWei(oneCentInWei);
    }
}