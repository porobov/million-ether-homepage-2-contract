pragma solidity ^0.4.18;

import "openzeppelin-solidity/contracts/lifecycle/Destructible.sol";  // production is immortal

contract MarketStub is Destructible {
    
    bool public isMarket = true;

    function areaPrice(uint16[] memory _blockList) 
        public 
        view 
        returns (uint) 
    {
        return 54321;
    }
}