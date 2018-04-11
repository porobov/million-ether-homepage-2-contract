pragma solidity ^0.4.18;

import "../installed_contracts/Ownable.sol"; 
import "../installed_contracts/HasNoEther.sol";
import "../installed_contracts/Destructible.sol"; // production is immortal

contract HasAuthorizedAccess is Ownable, HasNoEther, Destructible {  // production but is immortal {

    address authorized;

    modifier auth() {
        require(msg.sender == authorized);
        _;
    }

    function adminSetAuth(address newAuthorizedAddress) external onlyOwner {
        authorized = newAuthorizedAddress;
    }
}
