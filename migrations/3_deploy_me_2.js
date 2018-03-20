var MillionEther = artifacts.require("./MillionEther.sol");
var MEStorage = artifacts.require("./MEStorage.sol");
var OldeMillionEther = artifacts.require("./OldeMillionEther.sol");

module.exports = function(deployer) {
  deployer.deploy(MillionEther, MEStorage.address, OldeMillionEther.address).then(() => {
    MEStorage.deployed().then(inst => {
        return inst.setPermissions(MillionEther.address, 2);
    });
  });
};
