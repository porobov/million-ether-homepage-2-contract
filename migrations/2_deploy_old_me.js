var MEH = artifacts.require("./MEH.sol");
var OldeMillionEther = artifacts.require("../test/mockups/OldeMillionEther.sol");
var OracleProxy = artifacts.require("../test/mockups/OracleProxy.sol");
var OracleProxyStub = artifacts.require("../test/mockups/OracleProxyStub.sol");
var MarketStub = artifacts.require("../test/mockups/MarketStub.sol");

module.exports = function(deployer) {
  deployer.deploy(MEH);
  deployer.deploy(OldeMillionEther);
  deployer.deploy(OracleProxy);
  deployer.deploy(OracleProxyStub);
  deployer.deploy(MarketStub);
};
