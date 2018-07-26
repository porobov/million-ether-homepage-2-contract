var MEH = artifacts.require("./mockups/MEHDisposable.sol");
var OldeMillionEther = artifacts.require("./mockups/OldeMillionEther.sol");
var OracleProxy = artifacts.require("./mockups/OracleProxy.sol");

// var OracleProxyStub = artifacts.require("../test/mockups/OracleProxyStub.sol");
var OracleProxyStub = artifacts.require("./mockups/OracleProxyStub.sol");
var MarketStub = artifacts.require("./mockups/MarketStub.sol");
var RentalsStub = artifacts.require("./mockups/RentalsStub.sol");
var AdsStub = artifacts.require("./mockups/AdsStub.sol");

module.exports = function(deployer) {
  deployer.deploy(MEH);
  deployer.deploy(OldeMillionEther);
  deployer.deploy(OracleProxy);

  deployer.deploy(OracleProxyStub);
  deployer.deploy(MarketStub);
  deployer.deploy(RentalsStub);
  deployer.deploy(AdsStub);
};
