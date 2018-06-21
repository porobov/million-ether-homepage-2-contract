var OldeMillionEther = artifacts.require("../test/mockups/OldeMillionEther.sol");
var MEH = artifacts.require("./MEH.sol");
// /home/petr/Projects/2018-03-02-million-ether-2/Truffle/test/OracleProxyMock.sol
var OracleProxy = artifacts.require("../test/mockups/OracleProxy.sol");

module.exports = function(deployer) {
  deployer.deploy(MEH);
  deployer.deploy(OldeMillionEther);
  deployer.deploy(OracleProxy);
};
