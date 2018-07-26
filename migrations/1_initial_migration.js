var Migrations = artifacts.require("./Migrations.sol");

web3.eth.getAccounts((error,result) => {
  console.log(result);
});

module.exports = function(deployer) {
  deployer.deploy(Migrations);
};
