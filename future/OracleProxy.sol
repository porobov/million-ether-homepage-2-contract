pragma solidity ^0.4.11;

import "github.com/OpenZeppelin/openzeppelin-solidity/contracts/lifecycle/Destructible.sol";
import "github.com/OpenZeppelin/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "github.com/oraclize/ethereum-api/oraclizeAPI.sol";

contract OracleProxy is Ownable, Destructible, usingOraclize {
    
    // cofirm it's the right Oracle proxy
    bool public isOracleProxy = true;

    // stores ETHUSD price (one cent in wei)
    uint public oneCentInWei = 10 wei;

    // Oracalize default callback gas limit is 200000. More accurate estimate saves money.
    uint public callbackGasLimit;

    // Default REQUEST URL string (according to Oracalize API)
    string public REQUEST_URL;
    
    // Mapping to keep track of valid requests to Oracalize
    mapping(bytes32=>bool) validIds;
    
    // Oracalize querry-response events
    event LogResponseReceived(bytes32 id, string price);
    event LogOraclizeQuery(string description);
    
    // events to fire when admin changes settings
    event LogNewRequestURL(string newURL);

    constructor() public {
        REQUEST_URL = "json(https://api.kraken.com/0/public/Ticker?pair=ETHUSD).result.XETHZUSD.p.1";
        callbackGasLimit = 99159;  // 99159 - my estimation, 36062 - actual Oracalize response at Rinkeby
    }
    
    function __callback(bytes32 myid, string result) public {
        require(validIds[myid]);
        require(msg.sender == oraclize_cbAddress());

        emit LogResponseReceived(myid, result);
        bytes memory tempEmptyStringTest = bytes(result);
        require(tempEmptyStringTest.length > 0);
        
        uint oneEthInCents = parseInt(result, 2);
        assert(oneEthInCents > 0);  
        
        oneCentInWei = 1 ether / oneEthInCents;
        assert(oneCentInWei > 0);
        
        delete validIds[myid];
    }

    function getQueryPrice(uint EthUsdInCents, uint gasPriceInWei) pure returns (uint) {
        return EthUsdInCents / 100 + callbackGasLimit * gasPriceInWei; // 1 cent for URL request + gas cost (gasLimit * gasPriceInWei)
    }

    function updatePrice(uint EthUsdInCents, uint gasPriceInWei) public payable {
        // todo require correct ammount of money
        oraclize_setCustomGasPrice(gasPriceInWei);

        if (oraclize_getPrice("URL") > address(this).balance) {
            /// emit queryId EthUsdInCents gasPriceInWei
            emit LogOraclizeQuery("Oraclize query was NOT sent, please add some ETH to cover for the query fee");
        } else {
            emit LogOraclizeQuery("Oraclize query was sent, standing by for the answer...");
            bytes32 queryId = oraclize_query(0, "URL", REQUEST_URL, callbackGasLimit);
            validIds[queryId] = true;
        }
    }

    // fine-tune callback gas limit
    function setCallbackGasLimit(uint newCallbackGasLimit) external onlyOwner {
        callbackGasLimit = newCallbackGasLimit;
    }
    
    // set new request URL according to Oracalize API
    function setrequestURL(string newRequestURL) external onlyOwner {
        REQUEST_URL = newRequestURL;
        emit LogNewRequestURL(newRequestURL);
    }

    // function Excess()

}