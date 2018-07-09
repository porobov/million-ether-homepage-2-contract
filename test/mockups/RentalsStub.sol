pragma solidity ^0.4.24;    

import "openzeppelin-solidity/contracts/lifecycle/Destructible.sol";

contract RentalsStub is Destructible {
    
    bool public isRentals = true;

    function rentPriceAndAvailability(uint16 _blockId) public view returns (uint) {
        return 42;
    }
}
