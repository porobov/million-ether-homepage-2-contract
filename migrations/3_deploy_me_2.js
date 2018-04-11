var OracleProxy = artifacts.require("./OracleProxy.sol");
var OwnershipLedger = artifacts.require("./OwnershipLedger.sol");
var ModerationLedger = artifacts.require("./ModerationLedger.sol");
var OldeMillionEther = artifacts.require("./OldeMillionEther.sol");
var MillionEther = artifacts.require("./MillionEther.sol");

module.exports = function(deployer) {
  deployer.deploy(MillionEther, OwnershipLedger.address, OldeMillionEther.address, OracleProxy.address, ModerationLedger.address).then(() => {
    OwnershipLedger.deployed().then(inst => {
        return inst.setPermissions(MillionEther.address, 2);
    });
  });
};
