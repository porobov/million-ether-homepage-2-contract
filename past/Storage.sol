pragma solidity ^0.4.18;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/ownership/HasNoEther.sol";
import "openzeppelin-solidity/contracts/lifecycle/Destructible.sol";  // production is immortal

contract Storage is Ownable, HasNoEther, Destructible {  // production but is immortal {

    address public client;

    modifier onlyClient() {
        require(msg.sender == client);
        _;
    }

    function setClient(address newClient) external onlyOwner {
        client = newClient;
    }

    function isStorage() external view returns (bool) {
        return true;
    }
}
