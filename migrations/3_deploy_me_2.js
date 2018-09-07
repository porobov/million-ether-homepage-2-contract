module.exports = function(deployer, network) {
    var Ads = artifacts.require("./Ads.sol");
    var OracleProxy = artifacts.require("./mockups/OracleProxy.sol");
    var OracleProxyAddress;
    var OldeMillionEtherAddress;

    if (network == "live") {
        var MEH = artifacts.require("./MEH.sol");
        var Market = artifacts.require("./Market.sol");
        var Rentals = artifacts.require("./Rentals.sol");
        var OldeMillionEther = artifacts.require("./mockups/OldeMillionEtherInterface.sol");
        // OracleProxyAddress = '0x25330a8795371D94bd589a24BDf1c24c407BE626';  // ropsten
        // OldeMillionEtherAddress = '0x662327b1b97954eD3bF34d88892cb86e5E826001';  // ropsten        

        // OracleProxyAddress = '0xa3a45be10d4ac070435f488920dbbc908c25746f';  // rinkeby
        // OldeMillionEtherAddress = '0x47835950085ea8a8e2267b8b7b97a4d2a7378874';  // rinkeby        
        
        OracleProxy.at('0xbae9368d43e0299dc0280132f2c619ee9697e6e4');  // live
        OldeMillionEther.at('0x15dbdB25f870f21eaf9105e68e249E0426DaE916');  // live
    }

    if (network == "rinkeby" || network == "developement") {     
        var MEH = artifacts.require("./mockups/MEHDisposable.sol");
        var Market = artifacts.require("./mockups/MarketDisposable.sol");
        var Rentals = artifacts.require("./mockups/RentalsDisposable.sol");
        var OldeMillionEther = artifacts.require("./mockups/OldeMillionEtherMock.sol");
        OracleProxyAddress = OracleProxy.address;
        OldeMillionEtherAddress = OldeMillionEther.address;
    }

    deployer.deploy(Market, MEH.address, OldeMillionEtherAddress, OracleProxyAddress).then(() => {
        MEH.deployed().then(meh => {
            return meh.adminSetMarket(Market.address);
        });
    });

    deployer.deploy(Rentals, MEH.address).then(() => {
        MEH.deployed().then(meh => {
            return meh.adminSetRentals(Rentals.address);
        });
    });

    deployer.deploy(Ads, MEH.address).then(() => {
        MEH.deployed().then(meh => {
            return meh.adminSetAds(Ads.address);
        });
    });

}
