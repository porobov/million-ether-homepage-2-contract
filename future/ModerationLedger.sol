pragma solidity ^0.4.18;

import "./Storage.sol";

contract ModerationLedger is Storage {

    // Moderation
    mapping(address => bool) public bannedUsers;  // these users are not allowed to place images
    mapping(address => bool) public moderators;  // these users are allowed to replace imgaes and ban other users

    function setBanStatus(address _user, bool _ban) external onlyClient returns (bool) {
        bannedUsers[_user] = _ban;
        return true;
    }

    function setModerator(address _user, bool _canBan) external onlyClient returns (bool) {
        moderators[_user] = _canBan;
        return true;
    }

    function getBanStatus(address _user) external view returns (bool) {
        return bannedUsers[_user];
    }

    function isModerator(address _user) external view returns (bool) {
        return moderators[_user];
    }

}