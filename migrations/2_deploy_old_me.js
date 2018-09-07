module.exports = function(deployer, network) {
    
    if (network == "live") {
        var MEH = artifacts.require("./MEH.sol");
    }

    if (network == "rinkeby" || network == "developement") {
        var MEH = artifacts.require("./mockups/MEHDisposable.sol");
        var OldeMillionEther = artifacts.require("./mockups/OldeMillionEtherMock.sol");
        var OracleProxy = artifacts.require("./mockups/OracleProxy.sol");
        var OracleProxyStub = artifacts.require("./mockups/OracleProxyStub.sol");
        var MarketStub = artifacts.require("./mockups/MarketStub.sol");
        var RentalsStub = artifacts.require("./mockups/RentalsStub.sol");
        var AdsStub = artifacts.require("./mockups/AdsStub.sol");
        deployer.deploy(OldeMillionEther);
        deployer.deploy(OracleProxy);
        deployer.deploy(OracleProxyStub);
        deployer.deploy(MarketStub);
        deployer.deploy(RentalsStub);
        deployer.deploy(AdsStub);
    }

    deployer.deploy(MEH);

};
