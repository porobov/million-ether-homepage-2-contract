pragma solidity ^0.4.24;    

import "./MehModule.sol";

contract Ads is MehModule {
    
    bool public isAds = true;
    uint public numImages = 0;

    event LogImage (uint ID, uint8 fromX, uint8 fromY, uint8 toX, uint8 toY, string imageSourceUrl, string adUrl, string adText, address indexed publisher);

// ** INITIALIZE ** //

    constructor(address _mehAddress) public {
        adminSetMeh(_mehAddress);
    }

// ** PLACE IMAGES ** //

    // nobody has access to block ownership except current landlord
    // function instead of modifier as modifier used too much stack for placeImage
    function isBlockOwner(address _advertiser, uint8 _x, uint8 _y)    // TODO refactor to ownerOf - create MehModule.sol for all modules
        private 
        view 
        returns (bool) 
    {
        return (_advertiser == meh.ownerOf(meh.blockID(_x, _y)));
    }

    function isAllowedToAdvertise(address _advertiser, uint8 _fromX, uint8 _fromY, uint8 _toX, uint8 _toY) 
        private 
        view  
        returns (bool) 
    {
        for (uint8 ix=_fromX; ix<=_toX; ix++) {
            for (uint8 iy=_fromY; iy<=_toY; iy++) {
                return (isBlockOwner(_advertiser, ix, iy));
            }
        }
    }

    // place new ad to user owned or rented area
    function placeImage
    (
        address advertiser, 
        uint8 fromX, 
        uint8 fromY, 
        uint8 toX, 
        uint8 toY, 
        string imageSourceUrl, 
        string adUrl, 
        string adText
    ) 
        external
        onlyMeh
    {   
        require(isAllowedToAdvertise(advertiser, fromX, fromY, toX, toY));
        numImages++;
        emit LogImage(numImages, fromX, fromY, toX, toY, imageSourceUrl, adUrl, adText, advertiser);
    }

    // function chargeForImagePlacement() private {
    //     depositTo(msg.sender, msg.value);
    //     uint imagePlacementFeeInWei = mul(imagePlacementFeeCents, usd.getOneCentInWei()); 
    //     deductFrom(msg.sender, imagePlacementFeeInWei);
    //     depositTo(owner, imagePlacementFeeInWei);
    // }
}