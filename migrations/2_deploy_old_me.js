var OldeMillionEther = artifacts.require("./OldeMillionEther.sol");
var MEStorage = artifacts.require("./MEStorage.sol");
var Owned = artifacts.require("./Owned.sol");

module.exports = function(deployer) {
  deployer.deploy(MEStorage);
  deployer.deploy(Owned);
  deployer.deploy(OldeMillionEther);
};
