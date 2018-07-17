// module.exports = {
//   // See <http://truffleframework.com/docs/advanced/configuration>
//   // to customize your Truffle configuration!
//   //   networks: {
//   //   development: {
//   //     host: "127.0.0.1",
//   //     port: 8545,
//   //     network_id: "*", // Match any network id
//   //     gas: 100000000
//   //   }
//   // }
// };
// import { secrets } from './ignored.js';


var HDWalletProvider = require("truffle-hdwallet-provider");

var secrets = require('./ignored.js');
var infura_apikey = secrets.infura_api;
var mnemonic = secrets.mnemonic;

module.exports = {
  networks: {
    // development: {
    //   host: "localhost",
    //   port: 8545,
    //   network_id: "*" // Match any network id
    // },
    rinkeby: {
      // https://github.com/trufflesuite/truffle/issues/1022#issuecomment-397758751
      provider: () => {
        return new HDWalletProvider(mnemonic, "https://rinkeby.infura.io/"+infura_apikey)
      },
      network_id: 4,
      from: "0x0230c6dd5db1d3f871386a3ce1a5a836b2590044"
    }
  }
};