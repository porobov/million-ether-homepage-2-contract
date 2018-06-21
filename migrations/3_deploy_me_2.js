var OracleProxy = artifacts.require("../test/OracleProxy.sol");
var MEH = artifacts.require("./MEH.sol");
// var OldeMillionEther = artifacts.require("./OldeMillionEther.sol");
var OldeMillionEtherAddr = "0xF51f08910eC370DB5977Cff3D01dF4DfB06BfBe1";
var Market = artifacts.require("./Market.sol");


module.exports = function(deployer) {
  deployer.deploy(Market, MEH.address, OldeMillionEtherAddr, OracleProxy.address).then(() => {
    MEH.deployed().then(meh => {
        return meh.adminSetMarket(Market.address);
    });
    OracleProxy.deployed().then(oracleProxy => {
        return oracleProxy.setClient(Market.address);
    });
  });
};
