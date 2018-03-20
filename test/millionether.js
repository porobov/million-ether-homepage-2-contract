var MEStorage = artifacts.require("./MEStorage.sol");
var OldeMillionEther = artifacts.require("./OldeMillionEther.sol");
var MillionEther = artifacts.require("./MillionEther.sol");

// contract('OldeMillionEther', function(accounts) {

//   var owner = web3.eth.accounts[0]
//   var user_1 = web3.eth.accounts[1]
//   var user_2 = web3.eth.accounts[2]


//   it("Should let set initial state", function() {

//     return OldeMillionEther.deployed().then(function(instance) {
//         me = instance;
//         return me.signIn(owner, {from: user_1, gas: 4712388});
//     }).then(function(tx) {
//         return me.getUserInfo.call(owner);
//     }).then(function(user_info) {
//         return me.set_current_state({from: owner, gas: 4712388});
//     }).then(function(tx) {
//         return me.getBlockInfo.call(19, 19);
//     }).then(function(blockInfo) {
//         block_owner_1 = blockInfo[0];
//         assert.equal(block_owner_1.toLowerCase(), "0xCA9f7D9aD4127e374cdaB4bd0a884790C1B03946".toLowerCase(), "old ME was not set correctly");
//     });
//   });

// });


contract('MillionEther', function(accounts) {

  var owner = web3.eth.accounts[0]
  var user_1 = web3.eth.accounts[1]
  var user_2 = web3.eth.accounts[2]

  // Helpers

  function getBlockId(x, y) {
    return (y - 1) * 100 + x;
  }

  function logGas(_tx, _tx_name) {
    console.log("       > gasUsed for", _tx_name, _tx.receipt.gasUsed, '|', _tx.receipt.cumulativeGasUsed);
  }

/*
  it("Should let set initial state", function() {

    return OldeMillionEther.deployed().then(function(instance) {
        me = instance;
        return me.signIn(owner, {from: user_1, gas: 4712388});
    }).then(function(tx) {
        return me.getUserInfo.call(owner);
    }).then(function(user_info) {
        return me.set_current_state({from: owner, gas: 4712388});
    }).then(function(tx) {
        return me.getBlockInfo.call(19, 19);
    }).then(function(blockInfo) {
        block_owner_1 = blockInfo[0];
        assert.equal(block_owner_1.toLowerCase(), "0xCA9f7D9aD4127e374cdaB4bd0a884790C1B03946".toLowerCase(), "old ME was not set correctly");
    });
  });
    
  it("should let import old ME", function() {

    return MillionEther.deployed().then(function(instance) {
        me2 = instance;
        return MEStorage.deployed().then(function(instance) {
            me2storage = instance;
            return me2.import_old_me(19, 19, {from: owner, gas: 4712388});
        }).then(function(tx) {
            logGas(tx, "import_old_me")
            return me2storage.blocks.call(19, 19);
        }).then(function(blockInfo) {
            block_owner_1 = blockInfo[0];
            assert.equal(block_owner_1.toLowerCase(), "0xCA9f7D9aD4127e374cdaB4bd0a884790C1B03946".toLowerCase(), "old ME was not imported correctly");
        });
    });
  });
*/
  it("should set storage permission", function() {

    return MillionEther.deployed().then(function(instance) {
        me2 = instance;
        return MEStorage.deployed().then(function(instance) {
            me2storage = instance;
            return me2storage.accessLevel.call(me2.address);
        }).then(function(access) {
            assert.equal(access.toNumber(), 2, "storage permissions was not set correctly");
        });
    });
  });

  it("should let set and get landlord", function() {

    return MillionEther.deployed().then(function(instance) {
        me2 = instance;
        return MEStorage.deployed().then(function(instance) {
            me2storage = instance;
            return me2.setNewBlockOwner(20, 20, user_1, {from: owner, gas: 4712388});
        }).then(function(tx) {
            logGas(tx, "setBlockOwner");
            return me2storage.getBlockOwner.call(20, 20);
        }).then(function(blockOwner) {
            block_owner_1 = blockOwner;
            assert.equal(block_owner_1, user_1, "old ME was not set correctly");
        });
    });
  });

  it("should set owner", function() {

    return MillionEther.deployed().then(function(instance) {
        return instance.owner.call();
    }).then(function(balance) {
        assert.equal(balance.valueOf(), owner, "owner was not set correctly");
    });
  });
    
  it("should double block price in USD every 1000 blocks sold (crowdsaleUSDPrice private in future)", function() {

    var start_price;
    var price_before_1000;
    var price_after_1000;
    var price_before_10000;

    return MillionEther.deployed().then(function(instance) {
        me2 = instance;
        return me2.crowdsaleUSDPrice.call(0);
    }).then(function(blockPrice) {
        start_price = blockPrice.toNumber();
        return me2.crowdsaleUSDPrice.call(999);
    }).then(function(blockPrice) {
        price_before_1000 = blockPrice.toNumber();
        return me2.crowdsaleUSDPrice.call(1000);
    }).then(function(blockPrice) {
        price_after_1000 = blockPrice.toNumber();
        return me2.crowdsaleUSDPrice.call(9999);
    }).then(function(blockPrice) {
        price_before_10000 = blockPrice.toNumber();

        assert.equal(start_price, 1, "the price wasn't 1 USD at start");
        assert.equal(price_before_1000, 1, "the price wasn't 1 USD at 999 blocks sold");
        assert.equal(price_after_1000, 2, "the price wasn't 2 USD at 1000 blocks sold");
        assert.equal(price_before_10000, 512, "the price wasn't 512 USD at 9999 blocks sold");
    });
  });








  it("should convert dollars to ether (convertUSDtoWEI private in future)", function() {

    var ethUSDcents = 100000;
    var converted_1_USD;
    var converted_2_USD;
    var converted_512_USD;

    return MillionEther.deployed().then(function(instance) {
        me2 = instance;
        return me2.convertUSDtoWEI.call(1, ethUSDcents);
    }).then(function(priceInWei) {
        converted_1_USD = priceInWei.toNumber();
        return me2.convertUSDtoWEI.call(2, ethUSDcents);
    }).then(function(priceInWei) {
        converted_2_USD = priceInWei.toNumber();
        return me2.convertUSDtoWEI.call(512, ethUSDcents);
    }).then(function(priceInWei) {
        converted_512_USD = priceInWei.toNumber();

        assert.equal(converted_1_USD, web3.toWei(0.001, 'ether'), "1 USD wasn't converted to 0.001 ETH");
        assert.equal(converted_2_USD, web3.toWei(0.002, 'ether'), "2 USD wasn't converted to 0.002 ETH");
        assert.equal(converted_512_USD, web3.toWei(0.512, 'ether'), "512 USD wasn't converted to 0.512 ETH");
    });
  });
  








  it("should calculate charity percent (charityPercent private in future)", function() {

    var charity_percent_at_start;
    var charity_before_1000;
    var charity_after_1000;
    var charity_before_10000;

    return MillionEther.deployed().then(function(instance) {
        me2 = instance;
        return me2.charityPercent.call(0);
    }).then(function(percent) {
        charity_percent_at_start = percent.toNumber();
        return me2.charityPercent.call(999);
    }).then(function(percent) {
        charity_before_1000 = percent.toNumber();
        return me2.charityPercent.call(1000);
    }).then(function(percent) {
        charity_after_1000 = percent.toNumber();
        return me2.charityPercent.call(8999);
    }).then(function(percent) {
        charity_before_9000 = percent.toNumber();
        return me2.charityPercent.call(9999);
    }).then(function(percent) {
        charity_before_10000 = percent.toNumber();

        assert.equal(charity_percent_at_start, 0, "the charity percent wasn't 0 % at start");
        assert.equal(charity_before_1000, 0, "the charity percent wasn't 0 % at 999 blocks sold");
        assert.equal(charity_after_1000, 10, "the charity percent wasn't 10 % at 1000 blocks sold");
        assert.equal(charity_before_9000, 80, "the charity percent wasn't 80 % at 8999 blocks sold");
        assert.equal(charity_before_10000, 90, "the charity percent wasn't 90 % at 9999 blocks sold");
    });
  });









  it("should deposit and deduct funds (depositTo/deductFrom, private in production)", function() {

    var recipient = user_1;
    var balance_before;
    var deposit = web3.toWei(1, 'ether');
    var deduct = web3.toWei(0.5, 'ether');
    var balance_after_deposit;
    var balance_after_deduction;

    return MillionEther.deployed().then(function(instance) {
        me2 = instance;
        return MEStorage.deployed().then(function(instance) {
            me2storage = instance;
            return me2storage.balances.call(recipient);
        }).then(function(bal) {
            balance_before = bal.toNumber();
            return me2.depositTo(recipient, deposit, {from: recipient, gas: 4712388});
        }).then(function(tx) {
            return me2storage.balances.call(recipient);
        }).then(function(bal) {
            balance_after_deposit = bal.toNumber();
            return me2.deductFrom(recipient, deduct, {from: recipient, gas: 4712388});
        }).then(function(tx) {
            return me2storage.balances.call(recipient);
        }).then(function(bal) {
            balance_after_deduction = bal.toNumber();

            deposited = balance_after_deposit - balance_before;
            deducted = balance_after_deposit - balance_after_deduction;
            assert.equal(deposited, deposit, "funds weren't deposited correctly");
            assert.equal(deducted, deduct, "funds weren't deducted correctly");
        });
    });
  });







  it("should increment blocksSold (incrementBlocksSold, private in production)", function() {
    
    var blocksSold_before;
    var increment_by = 100;
    var blocksSold_after;

    return MillionEther.deployed().then(function(instance) {
        me2 = instance;
        return MEStorage.deployed().then(function(instance) {
            me2storage = instance;
            return me2storage.numBlocksSold.call();
        }).then(function(blcks) {
            blocksSold_before = blcks.toNumber();
            return me2.incrementBlocksSold(0, {from: user_1, gas: 4712388});
        }).then(function(tx) {
            return me2.incrementBlocksSold(increment_by, {from: user_1, gas: 4712388});
        }).then(function(tx) {
            return me2storage.numBlocksSold.call();
        }).then(function(blcks) {
            blocksSold_after = blcks.toNumber();

            incremented_by = blocksSold_after - blocksSold_before
            assert.equal(incremented_by, increment_by, "blocksSold wasn't incremented correctly");
        });
    });
  });








  it("should pay contact owner and charity (payOwnerAndCharity, private in production)", function() {

    var owner_bal_before;
    var char_bal_before;
    var owner_bal_1;
    var char_bal_1;
    var owner_bal_2;
    var char_bal_2;
    var amount_1 = web3.toWei(1, 'ether');
    var amount_2 = web3.toWei(10, 'ether');
    var owner_to_recieve_2 = web3.toWei(9, 'ether');
    var border = 1000;  // number of blocks

    return MillionEther.deployed().then(function(instance) {
        me2 = instance;
        return MEStorage.deployed().then(function(instance) {
            me2storage = instance;
            //initial conditions
            return me2storage.balances.call(owner);
        }).then(function(bal) {
            owner_bal_before = bal.toNumber();
            return me2storage.charityBalance.call();
        }).then(function(bal) {
            char_bal_before = bal.toNumber();
            return me2storage.numBlocksSold.call();
        }).then(function(blcks) {
            //1st round
            increment_by = border - blcks.toNumber() - 1;  // to make it 999
            return me2.incrementBlocksSold(increment_by, {from: user_1, gas: 4712388});
        }).then(function(tx) {
            return me2.payOwnerAndCharity(amount_1);
        }).then(function(tx) {
            return me2storage.balances.call(owner);
        }).then(function(bal) {
            owner_bal_1 = bal.toNumber();
            return me2storage.charityBalance.call();
        }).then(function(bal) {
            char_bal_1 = bal.toNumber();        
            //2nd round
            increment_by = 1;  // to make it 999
            return me2.incrementBlocksSold(increment_by, {from: user_1, gas: 4712388});
        }).then(function(tx) {
            return me2.payOwnerAndCharity(amount_2);
        }).then(function(tx) {
            return me2storage.balances.call(owner);
        }).then(function(bal) {
            owner_bal_2 = bal.toNumber();
            return me2storage.charityBalance.call();
        }).then(function(bal) {
            char_bal_2 = bal.toNumber();

            owner_recieved_1 = owner_bal_1 - owner_bal_before;
            charity_recieved_1 = char_bal_1 - char_bal_before;
            owner_recieved_2 = owner_bal_2 - owner_bal_1;
            charity_recieved_2 = char_bal_2 - char_bal_1;
            assert.equal(owner_recieved_1, amount_1, "owner didn't recieve full amount durinng round 1");
            assert.equal(charity_recieved_1, 0, "charity recieve something durinng round 1");
            assert.equal(owner_recieved_2, owner_to_recieve_2, "owner didn't recieve 90% durinng round 2");
            assert.equal(charity_recieved_2, amount_2 - owner_to_recieve_2, "charity didn't recieve 10% durinng round 2");
        });
    });
  });




  it("should pay blockPrice to blockOwner (payBlockOwner, private in production)", function() {
    
    var block_owner = user_1;
    var zero_address = "0x0000000000000000000000000000000000000000";
    var amount = web3.toWei(10, 'ether');
    var owner_to_recieve = web3.toWei(9, 'ether');

    return MillionEther.deployed().then(function(instance) {
        me2 = instance;
        return MEStorage.deployed().then(function(instance) {
            me2storage = instance;
            // initial state
            return me2storage.balances.call(owner);
        }).then(function(bal) {
            contract_owner_bal_before = bal.toNumber();
            return me2storage.balances.call(block_owner);
        }).then(function(bal) {
            block_owner_bal_before = bal.toNumber();
            return me2storage.charityBalance.call();
        }).then(function(bal) {
            char_bal_before = bal.toNumber();
            return me2storage.numBlocksSold.call();
        }).then(function(blcks) {
            // round 1
            return me2.payBlockOwner(block_owner, amount, {from: user_1, gas: 4712388});
        }).then(function(tx) {
            return me2storage.balances.call(block_owner);
        }).then(function(bal) {
            block_owner_bal_after = bal.toNumber();
            // round 2
            return me2.payBlockOwner(zero_address, amount, {from: user_1, gas: 4712388});
        }).then(function(tx) {
            return me2storage.balances.call(owner);
        }).then(function(bal) {
            contract_owner_bal_after = bal.toNumber();
            return me2storage.charityBalance.call();
        }).then(function(bal) {
            char_bal_after = bal.toNumber();

            block_owner_recieved = block_owner_bal_after - block_owner_bal_before;
            contract_owner_recieved = contract_owner_bal_after - contract_owner_bal_before;
            char_recieved = char_bal_after - char_bal_before;
            assert.equal(block_owner_recieved, amount, "block_owner didn't recieve correct amount");
            assert.equal(contract_owner_recieved, owner_to_recieve, "contract_owner didn't recieve correct amount");
            assert.equal(char_recieved, amount - owner_to_recieve, "charity didn't recieve correct amount");
        });
    });
  });






  it("should set new block owner 2 (private in future)", function() {

    var xy = 51;
    var buer_1 = user_1;
    var buer_2 = user_2;
    var block_owner_1;
    var block_owner_2;
    var blocksSold_init;
    var blocksSold_1st_buy;
    var blocksSold_2nd_buy;



    return MillionEther.deployed().then(function(instance) {
        me2 = instance;
        return MEStorage.deployed().then(function(instance) {
            me2storage = instance;
            return me2.setNewBlockOwner(xy, xy, buer_1, {from: buer_1, gas: 4712388});
        }).then(function(tx) {
            logGas(tx, "setNewBlockOwner");
            return me2storage.blocks.call(xy, xy);
        }).then(function(blockInfo) {
            block_owner_1 = blockInfo[0];
        //     return me2.blocksSold.call();
        // }).then(function(blocksSold) {
        //     blocksSold_1st_buy = blocksSold.toNumber();

            //new owner for the same block
            return me2.setNewBlockOwner(xy, xy, buer_2, {from: buer_2, gas: 4712388});
        }).then(function(tx) {
            logGas(tx, "resetNewBlockOwner");
            return me2storage.blocks.call(xy, xy);
        }).then(function(blockInfo) {
            block_owner_2 = blockInfo[0];
        //     return me2.blocksSold.call();
        // }).then(function(blocksSold) {
        //     blocksSold_2nd_buy = blocksSold.toNumber();

            //assert.equal(blocksSold_1st_buy - blocksSold_init, 1, "the blocksSold didn't increment");
            assert.equal(block_owner_1, buer_1, "the block owner wasn't set");
            // assert.equal(blocksSold_1st_buy - blocksSold_2nd_buy, 0, "the blocksSold incremented when buying from owner");
            assert.equal(block_owner_2, buer_2, "the block owner wasn't reset");
        });
    });
  });

  it("should let buy blocks", function() {

    var buer_1 = user_1;
    var block_owner_1_1;
    var block_owner_2_2;

    return MillionEther.deployed().then(function(instance) {
        me2 = instance;
        return MEStorage.deployed().then(function(instance) {
            me2storage = instance;
            return me2storage.blocks.call(1, 1);
        }).then(function(blockInfo) {
            console.log( blockInfo[0]);

            return me2.buyBlocks(1, 1, 8, 9, {from: buer_1, value: web3.toWei(1, 'ether'), gas: 4712388});
        }).then(function(tx) {
            logGas(tx, "buyBlocks");
            return me2storage.blocks.call(1, 1);
        }).then(function(blockInfo) {
            block_owner_1_1 = blockInfo[0];
            return me2storage.blocks.call(2, 2);
        }).then(function(blockInfo) {
            block_owner_2_2 = blockInfo[0];

            assert.equal(block_owner_1_1, buer_1, "the block 1x1 owner wasn't set");
            assert.equal(block_owner_2_2, buer_1, "the block 2x2 owner wasn't set");
        });
    });
  });

  //  function placeImage (uint8 fromX, uint8 fromY, uint8 toX, uint8 toY, string imageSourceUrl, string adUrl, string adText) 

  it("should let place image", function() {

    var buer_1 = user_1;
    var image_id;

    return MillionEther.deployed().then(function(instance) {
        me2 = instance;
        return MEStorage.deployed().then(function(instance) {
            me2storage = instance;
            return me2.placeImage(1, 1, 8, 9, "sadf","sfa","asdgbb", {from: buer_1, gas: 4712388});
        }).then(function(tx) {
            logGas(tx, "placeImage");
            return me2storage.numImages.call();
        }).then(function(id) {
            image_id = id.toNumber();

            assert.equal(image_id, 1, "the image id wasn't incremented");
        });
    });
  });

});


/*
  it("should calculate block ID", function() {

    var block_ID_1_1;
    var block_ID_1_2;
    var block_ID_100_1;
    var block_ID_100_100;

    return MillionEther.deployed().then(function(instance) {
        me2 = instance;
        return me2.getBlockID.call(1, 1);
    }).then(function(block_ID) {
        block_ID_1_1 = block_ID.toNumber();
        return me2.getBlockID.call(1, 2);
    }).then(function(block_ID) {
        block_ID_1_2 = block_ID.toNumber();
        return me2.getBlockID.call(100, 1);
    }).then(function(block_ID) {
        block_ID_100_1 = block_ID.toNumber();
        return me2.getBlockID.call(100, 100);
    }).then(function(block_ID) {
        block_ID_100_100 = block_ID.toNumber();

        assert.equal(block_ID_1_1, 1, "The ID for block 1x1 wasn't calculated correctly");
        assert.equal(block_ID_1_2, 101, "The ID for block 1x2 wasn't calculated correctly");
        assert.equal(block_ID_100_1, 100, "The ID for block 100x1 wasn't calculated correctly");
        assert.equal(block_ID_100_100, 10000, "The ID for block 100x100 wasn't calculated correctly");
    });
  });
*/