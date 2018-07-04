var MEH = artifacts.require("./MEH.sol");
var Market = artifacts.require("./Market.sol");
var Rentals = artifacts.require("./Rentals.sol");
var Ads = artifacts.require("./Ads.sol");

module.exports = function(deployer) {
  Ads.deployed().then(ads => {
    return ads.adminSetRentals(Rentals.address);
  });
}