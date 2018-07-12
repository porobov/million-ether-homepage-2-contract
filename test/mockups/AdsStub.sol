pragma solidity ^0.4.18;

import "openzeppelin-solidity/contracts/lifecycle/Destructible.sol";  // production is immortal

contract AdsStub is Destructible {
    
    bool public isAds = true;

    function canPaintBlocks(
        address advertiser, 
        uint16[] _blockList
    ) 
        public
        view
        returns (bool)
    {   
        return true;
    }

    // function isAllowedToAdvertise(address _advertiser, uint8 _fromX, uint8 _fromY, uint8 _toX, uint8 _toY) 
    //     public 
    //     view
    //     returns (bool)
    // {
    //     return true;
    // }
}