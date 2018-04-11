pragma solidity ^0.4.18;

import "../installed_contracts/Ownable.sol"; 
import "../installed_contracts/HasNoEther.sol";
import "../installed_contracts/Destructible.sol"; // production is immortal
import "./HasAuthorizedAccess.sol";

contract ModerationLedger is Ownable, HasNoEther, Destructible, HasAuthorizedAccess {  // production but is immortal

    // Moderation
    mapping(address => bool) public bannedUsers;  // these users are not allowed to place images

    function setBanStatus(address _user, bool _ban) external auth returns (bool) {
        bannedUsers[_user] = _ban;
        return true;
    }

    function getBanStatus(address _user) external view returns (bool) {
        return bannedUsers[_user];
    }
}