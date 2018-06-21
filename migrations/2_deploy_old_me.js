var OldeMillionEther = artifacts.require("./OldeMillionEther.sol");
var MEH = artifacts.require("./MEH.sol");
var OracleProxy = artifacts.require("./OracleProxy.sol");

module.exports = function(deployer) {
  deployer.deploy(MEH);
  deployer.deploy(OldeMillionEther);
  deployer.deploy(OracleProxy);
};
