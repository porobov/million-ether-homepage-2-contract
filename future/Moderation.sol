pragma solidity ^0.4.18;

import "../installed_contracts/Ownable.sol"; 
import "../installed_contracts/Destructible.sol";
import "./ModerationLedger.sol";

contract Moderation is Ownable, HasNoEther, Destructible {

    ModerationLedger bans;

    // Reports
    event LogUserBan(address user, bool ban, string reason);
    event LogNewModerator(address user, bool isModerator, string reason);

    function Moderation (address _bansAddr) public {
        bans = ModerationLedger(_bansAddr);
        require(bans.isStorage());
    }

    // owner sets moderator, no sense to block owner
    modifier onlyModerator() {
        require(bans.isModerator(msg.sender) || msg.sender == owner);  
        _;
    }

    function moderatorBanUser(address user, bool ban, string reason) external onlyModerator returns (bool) {
        bans.setBanStatus(user, ban);
        LogUserBan(user, ban, reason);
        return true;
        }

    // set moderator
    function adminSetModerator(address user, bool isModerator, string reason) external onlyOwner {
        if (user != address(0x0)) { 
            bans.setModerator(user, isModerator);
        }
        LogNewModerator(user, isModerator, reason);
    }
}