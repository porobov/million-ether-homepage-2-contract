var HDWalletProvider = require("truffle-hdwallet-provider");

var secrets = require('./secrets.js');
var infura_apikey = secrets.infura_api;
var mnemonic = secrets.mnemonic;

module.exports = {
  // timeouts are too short for rinkeby (or other real networks). 
  mocha: {
    enableTimeouts: false
  },
  
  networks: {
    development: {
      host: '127.0.0.1',
      port: 7545,
      gas: 7721975,
      network_id: 0 //'*' // Match any network id
    },
    // ropsten: {
    //   // https://github.com/trufflesuite/truffle/issues/1022#issuecomment-397758751
    //   provider: () => {
    //     return new HDWalletProvider(mnemonic, "https://ropsten.infura.io/v3/"+infura_apikey, 0, 5)
    //     // return new HDWalletProvider(mnemonic, "https://rinkeby.infura.io/"+infura_apikey)
    //   },
    //   network_id: 3,
    //   from: "0x0230c6dd5db1d3f871386a3ce1a5a836b2590044"
    // },
    rinkeby: {
      // https://github.com/trufflesuite/truffle/issues/1022#issuecomment-397758751
      provider: () => {
        return new HDWalletProvider(mnemonic, "https://rinkeby.infura.io/v3/"+infura_apikey, 0, 5)
        // return new HDWalletProvider(mnemonic, "https://rinkeby.infura.io/"+infura_apikey)
      },
      network_id: 4,
      from: "0x0230c6dd5db1d3f871386a3ce1a5a836b2590044"
    },
    // kovan: {
    //   // https://github.com/trufflesuite/truffle/issues/1022#issuecomment-397758751
    //   provider: () => {
    //     return new HDWalletProvider(mnemonic, "https://kovan.infura.io/v3/"+infura_apikey, 0, 5)
    //     // return new HDWalletProvider(mnemonic, "https://rinkeby.infura.io/"+infura_apikey)
    //   },
    //   network_id: 42,
    //   from: "0x0230c6dd5db1d3f871386a3ce1a5a836b2590044"
    // }
  }
};