var OldeMillionEther = artifacts.require("./OldeMillionEther.sol");
var MEStorage = artifacts.require("./MEStorage.sol");

module.exports = function(deployer) {
  deployer.deploy(MEStorage);
  deployer.deploy(OldeMillionEther);
};
