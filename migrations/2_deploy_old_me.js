var OldeMillionEther = artifacts.require("./OldeMillionEther.sol");
var OwnershipLedger = artifacts.require("./OwnershipLedger.sol");
var OracleProxy = artifacts.require("./OracleProxy.sol");

module.exports = function(deployer) {
  deployer.deploy(OwnershipLedger, "dsf", "dfs");
  deployer.deploy(OldeMillionEther);
  deployer.deploy(OracleProxy);
};
