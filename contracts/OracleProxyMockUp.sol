pragma solidity ^0.4.18;

import "../installed_contracts/Ownable.sol"; 
import "../installed_contracts/Destructible.sol";
import "./MillionEther.sol";

contract OracleProxy is Ownable, Destructible {
    
    MillionEther public ME;
    
    function setME(address meAddress) public payable {
        ME = MillionEther(meAddress);
    }

    function __callback(uint oneCentInWei) public {
        ME.oracleSetOneCentInWei(oneCentInWei);
    }
}