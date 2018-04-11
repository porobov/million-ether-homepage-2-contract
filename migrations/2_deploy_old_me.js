var OldeMillionEther = artifacts.require("./OldeMillionEther.sol");
var OwnershipLedger = artifacts.require("./OwnershipLedger.sol");
var ModerationLedger = artifacts.require("./ModerationLedger.sol");
var OracleProxy = artifacts.require("./OracleProxy.sol");

module.exports = function(deployer) {
  deployer.deploy(OwnershipLedger);
  deployer.deploy(ModerationLedger);
  deployer.deploy(OldeMillionEther);
  deployer.deploy(OracleProxy);
};
