var OracleProxy = artifacts.require("./OracleProxy.sol");
var OwnershipLedger = artifacts.require("./OwnershipLedger.sol");
var OldeMillionEther = artifacts.require("./OldeMillionEther.sol");
var MillionEther = artifacts.require("./MillionEther.sol");

module.exports = function(deployer) {
  deployer.deploy(MillionEther, OwnershipLedger.address, OldeMillionEther.address, OracleProxy.address).then(() => {
    OwnershipLedger.deployed().then(ownershipLedger => {
        return ownershipLedger.setClient(MillionEther.address);
    });
    OracleProxy.deployed().then(oracleProxy => {
        return oracleProxy.setClient(MillionEther.address);
    });
  });
};
