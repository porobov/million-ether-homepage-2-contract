var MEH = artifacts.require("./MEH.sol");
var OldeMillionEther = artifacts.require("../test/mockups/OldeMillionEther.sol");
var OracleProxy = artifacts.require("../test/mockups/OracleProxy.sol");

module.exports = function(deployer) {
  deployer.deploy(MEH);
  deployer.deploy(OldeMillionEther);
  deployer.deploy(OracleProxy);
};
