pragma solidity ^0.4.11;

import "github.com/OpenZeppelin/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "github.com/OpenZeppelin/openzeppelin-solidity/contracts/lifecycle/Destructible.sol";
import "github.com/OpenZeppelin/openzeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "github.com/oraclize/ethereum-api/oraclizeAPI.sol";
import "github.com/OpenZeppelin/openzeppelin-solidity/contracts/math/SafeMath.sol ";

contract OracleProxy is Ownable, Destructible, Pausable, usingOraclize {
    using SafeMath for uint256;
    // cofirm it's the right Oracle proxy
    bool public isOracleProxy = true;

    // stores ETHUSD price (one cent in wei)
    uint public oneCentInWei;

    // Oracalize default callback gas limit is 200000. More accurate estimate saves money.
    uint public callbackGasLimit;

    // Default REQUEST URL string (according to Oracalize API)
    string public REQUEST_URL;
    
    // Mapping to keep track of valid requests to Oracalize
    mapping(bytes32=>bool) validIds;
    
    // Oracalize querry-response events
    event LogResponseReceived(bytes32 id, string price);
    event LogOraclizeQuery(bytes32 queryId, uint gasPriceInWei, string description);
    
    // events to fire when admin changes settings
    event LogNewRequestURL(string newURL);
    event LogNewCallbackGasLimit(uint callbackGasLimit);

    constructor() public {
        REQUEST_URL = "json(https://api.kraken.com/0/public/Ticker?pair=ETHUSD).result.XETHZUSD.p.1";
        callbackGasLimit = 99159; // 99159;  // 99159 - my estimation, 36364, 36062 - actual Oracalize response at Rinkeby
        oneCentInWei = 10 wei; // 24331000000000; // 1 cent in wei (1 eth = $410)
    }
    
    function __callback(bytes32 myid, string result) public whenNotPaused {
        require(validIds[myid]);
        require(msg.sender == oraclize_cbAddress());

        emit LogResponseReceived(myid, result);
        
        // parseInt handles zero length result string and returns 0
        uint oneEthInCents = parseInt(result, 2);
        require(oneEthInCents > 0);
        
        oneCentInWei = 1 ether / oneEthInCents;
        assert(oneCentInWei > 0);
        
        delete validIds[myid];
    }

    /// @notice calculates the ammount of ether to send with updatePrice
    function getQueryPrice(uint EthInCents, uint gasPriceInWei) public view returns (uint) {
        uint256 oneEth = 1 ether;  // dedicated var to apply SafeMath's div function
        uint256 oracalizeFee = oneEth.div(EthInCents).div(98); // 1 cent + 2% (safety margin)
        uint256 gasCost = callbackGasLimit.mul(gasPriceInWei);
        return oracalizeFee + gasCost;
    }

    /// @dev function is public in order to allow hot wallet
    /// @notice Will not check the right ammount of money. Will consume all ether sent!
    function updatePrice(uint gasPriceInWei) public payable whenNotPaused {

        if (gasPriceInWei > 0) {
            oraclize_setCustomGasPrice(gasPriceInWei);
        }
        
        if (oraclize_getPrice("URL") > address(this).balance) {

            emit LogOraclizeQuery(
                "", 
                gasPriceInWei, 
                "Oraclize query was NOT sent, please add some ETH to cover for the query fee");

        } else {

            bytes32 queryId = oraclize_query(0, "URL", REQUEST_URL, callbackGasLimit);
            validIds[queryId] = true;
            emit LogOraclizeQuery(
                queryId,
                gasPriceInWei, 
                "Oraclize query was sent, standing by for the answer...");
        }
    }

    // fine-tune callback gas limit
    function setCallbackGasLimit(uint newCallbackGasLimit) external onlyOwner {
        require(newCallbackGasLimit >0);
        callbackGasLimit = newCallbackGasLimit;
        emit LogNewCallbackGasLimit(newCallbackGasLimit);
    }
    
    // set new request URL according to Oracalize API
    function setRequestURL(string newRequestURL) external onlyOwner {
        REQUEST_URL = newRequestURL;
        emit LogNewRequestURL(newRequestURL);
    }

    /// sends excess contract balance to contract owner
    function withdrawExcess() external {
        uint payment = address(this).balance;
        require(payment > 0);
        owner.transfer(payment);
    }
}