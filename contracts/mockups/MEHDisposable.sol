pragma solidity ^0.4.24;    

import "openzeppelin-solidity/contracts/lifecycle/Destructible.sol";
import "../MEH.sol";

contract MEHDisposable is Destructible, MEH {}
