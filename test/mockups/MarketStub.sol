pragma solidity ^0.4.18;

import "openzeppelin-solidity/contracts/lifecycle/Destructible.sol";  // production is immortal

contract MarketStub is Destructible {
    
    bool public isMarket = true;

    function areaPrice(uint8 fromX, uint8 fromY, uint8 toX, uint8 toY) 
        public 
        view 
        returns (uint) 
    {
        return 54321;
    }
}