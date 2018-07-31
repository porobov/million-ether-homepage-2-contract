pragma solidity ^0.4.24;    

import "openzeppelin-solidity/contracts/lifecycle/Destructible.sol";
import "../MEH.sol";

/// Not for production. Functionality added for testing and cleanup purposes only. 
contract MEHDisposable is Destructible, MEH {}
