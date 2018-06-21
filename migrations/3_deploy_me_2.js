var OracleProxy = artifacts.require("./OracleProxy.sol");
var MEH = artifacts.require("./MEH.sol");
var OldeMillionEther = artifacts.require("./OldeMillionEther.sol");
var Market = artifacts.require("./Market.sol");

module.exports = function(deployer) {
  deployer.deploy(Market, MEH.address, OldeMillionEther.address, OracleProxy.address).then(() => {
    MEH.deployed().then(meh => {
        return meh.adminSetMarket(Market.address);
    });
    OracleProxy.deployed().then(oracleProxy => {
        return oracleProxy.setClient(Market.address);
    });
  });
};
