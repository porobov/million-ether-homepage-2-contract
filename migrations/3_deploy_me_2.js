var MEH = artifacts.require("./MEH.sol");
var MarketDisposable = artifacts.require("../test/mockups/MarketDisposable.sol");
var RentalsDisposable = artifacts.require("../test/mockups/RentalsDisposable.sol");
var Ads = artifacts.require("./Ads.sol");
var OracleProxy = artifacts.require("../test/mockups/OracleProxy.sol");
var OldeMillionEther = artifacts.require("../test/mockups/OldeMillionEther.sol");
// var OldeMillionEtherAddr = "0xF51f08910eC370DB5977Cff3D01dF4DfB06BfBe1";

module.exports = function(deployer) {
  deployer.deploy(MarketDisposable, MEH.address, OldeMillionEther.address, OracleProxy.address).then(() => {
    MEH.deployed().then(meh => {
        return meh.adminSetMarket(MarketDisposable.address);
    });
    // OracleProxy.deployed().then(oracleProxy => {
    //     return oracleProxy.setClient(Market.address);
    // });
  });

  deployer.deploy(RentalsDisposable, MEH.address).then(() => {
    MEH.deployed().then(meh => {

        return meh.adminSetRentals(RentalsDisposable.address);
    });

  });

  // deployer.deploy(Ads, MEH.address);
  deployer.deploy(Ads, MEH.address).then(() => {
    MEH.deployed().then(meh => {
    return meh.adminSetAds(Ads.address);
    });
  });

}
