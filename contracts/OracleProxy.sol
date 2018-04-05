pragma solidity ^0.4.11;

import "./owned.sol";
import "./mortal.sol";
import "github.com/oraclize/ethereum-api/oraclizeAPI.sol";
import "./MEMockup.sol";

contract ExampleContract is usingOraclize, mortal {
    
    // global defaults
    MillionEther public ME;
    uint public DELAY;
    string public REQUEST_URL;
    uint public GAS_PRICE;  // reference only
    
    // a mapping to keep track of valid requests to Oracalize
    mapping(bytes32=>bool) validIds;
    
    // Oracalize querry-response events
    event LogResponseReceived(bytes32 id, string price);
    event LogOraclizeQuery(string description);
    
    // events to fire when admin changes settings
    event LogNewME(address newMEAddress, string reason);
    event LogNewDelay(uint newDelay, string reason);
    event LogNewRequestURL(string newURL, string reason);

    function ExampleContract(address meAddress) public payable {
        ME = MillionEther(meAddress);
        DELAY = 25200;
        REQUEST_URL = "json(https://api.kraken.com/0/public/Ticker?pair=ETHUSD).result.XETHZUSD.p.1";
    }

    function __callback(bytes32 myid, string result) public {
        require(validIds[myid]);
        require(msg.sender == oraclize_cbAddress());
        emit LogResponseReceived(myid, result);
        bytes memory tempEmptyStringTest = bytes(result);
        require(tempEmptyStringTest.length > 0);
        
        uint oneEthInCents;
        oneEthInCents = parseInt(result, 2);
        assert(oneEthInCents > 0);
        
        uint oneCentInWei;
        oneCentInWei = 1 ether / oneEthInCents;
        assert(oneCentInWei > 0);
        
        ME.oracleSetOneCentInWei(oneCentInWei);
        
        delete validIds[myid];
        updatePrice(DELAY);
    }

    function updatePrice(uint update_delay) public payable onlyowner {
        if (oraclize_getPrice("URL") > address(this).balance) {
            emit LogOraclizeQuery("Oraclize query was NOT sent, please add some ETH to cover for the query fee");
        } else {
            emit LogOraclizeQuery("Oraclize query was sent, standing by for the answer...");
            bytes32 queryId = oraclize_query(update_delay, "URL", REQUEST_URL);
            validIds[queryId] = true;
        }
    }
    
    // Set new defaults
    function setME(address meAddress, string reason) external onlyowner returns(bool) {
        ME = MillionEther(meAddress);
        emit LogNewME(meAddress, reason);
        return true;
    }
    
    function setUpdatePeriod(uint newDelay, string reason) external onlyowner returns(bool) {
        DELAY = newDelay;
        emit LogNewDelay(newDelay, reason);
        return true;
    }
    
    function setGasPrice(uint newGasPriceInWei) external onlyowner returns(bool) {
        oraclize_setCustomGasPrice(newGasPriceInWei);
        GAS_PRICE = newGasPriceInWei;
        return true;
    }
    
    function setrequestURL(string newRequestURL, string reason) external onlyowner returns(bool) {
        REQUEST_URL = newRequestURL;
        emit LogNewRequestURL(newRequestURL, reason);
        return true;
    }
}