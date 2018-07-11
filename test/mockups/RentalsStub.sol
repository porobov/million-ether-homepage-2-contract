pragma solidity ^0.4.24;    

import "openzeppelin-solidity/contracts/lifecycle/Destructible.sol";

contract RentalsStub is Destructible {
    
    bool public isRentals = true;
    function blocksRentPrice(uint _numberOfPeriods, uint16[] _blockList) external view returns (uint) {
        return 42;
    }
}
