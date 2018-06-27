// var MEStorage = artifacts.require("./OwnershipLedger.sol");
// var OldeMillionEther = artifacts.require("./OldeMillionEther.sol");
var MillionEther = artifacts.require("./MEH.sol");
var Market = artifacts.require("./Market.sol");

contract('MillionEther', function(accounts) {

  var admin = web3.eth.accounts[0]
  var user_1 = web3.eth.accounts[1]
  var user_2 = web3.eth.accounts[2]
  var charityAddress = '0x616c6C20796F75206e656564206973206C6f7665'

// Helper functions

  function getBlockId(x, y) {
    return (y - 1) * 100 + x;
  }

  function logGas(_tx, _tx_name) {
    console.log("       > gasUsed for", _tx_name, _tx.receipt.gasUsed, '|', _tx.receipt.cumulativeGasUsed);
  }

  // get most important state variables
  async function mehState(mehInstance) {
    var state = {};
    state.user_1_bal = await mehInstance.balances.call(user_1);
    state.user_2_bal = await mehInstance.balances.call(user_2);
    state.admin_bal = await mehInstance.balances.call(admin);
    state.charity_bal = await mehInstance.balances.call(charityAddress);
    state.contract_bal = 0;  // TODO acounting balance
    state.contract_bal_eth = await web3.eth.getBalance(mehInstance.address);
    state.blocks_sold = await mehInstance.totalSupply.call();
    return state;
  }

  // assert state variables changes
  function checkStateChange(before, after, deltas) {
    assert.equal(after.user_1_bal - before.user_1_bal, deltas.user_1_bal, 
        "user_1 balance delta was wrong");
    assert.equal(after.user_2_bal - before.user_2_bal, deltas.user_2_bal, 
        "user_2 balance delta was wrong");
    assert.equal(after.admin_bal - before.admin_bal, deltas.admin_bal, 
        "admin balance delta was wrong");
    assert.equal(after.charity_bal - before.charity_bal, deltas.charity_bal,    
        "charity balance delta was wrong");
    // state.contract_bal = 0; 
    assert.equal(after.contract_bal_eth - before.contract_bal_eth, deltas.contract_bal_eth,    
        "contract ether balance delta was wrong");
    assert.equal(after.blocks_sold - before.blocks_sold, deltas.blocks_sold,    
        "totalSupply delta was wrong");
    
  }

// buy 1 block
  it("should let buy block 1x1", async () => {
    const me2 = await MillionEther.deployed();
    const buyer = user_1;
    const before = await mehState(me2);

    tx = await me2.buyArea(1, 1, 1, 1, {from: buyer, value: web3.toWei(1000, 'wei'), gas: 4712388});
    logGas(tx, "buyArea (one block");

    const after = await mehState(me2);
    const deltas = {
        user_1_bal: 0,
        user_2_bal: 0,
        admin_bal: web3.toWei(200, 'wei'),
        charity_bal: web3.toWei(800, 'wei'),
        contract_bal: 0,
        contract_bal_eth: 1000,
        blocks_sold: 1
    }
    checkStateChange(before, after, deltas);

    assert.equal(await me2.getBlockOwner.call(1, 1), buyer,                       
        "the block 1x1 owner wasn't set");
  })

// sell 1 block
  it("should let sell block 1x1", async () => {
    const me2 = await MillionEther.deployed();
    const seller = user_1;
    const buyer = user_2;
    const before = await mehState(me2);

    var tx = await me2.sellArea(1, 1, 1, 1, 5, {from: seller, gas: 4712388});
    logGas(tx, "sellArea (1 block");
    tx = await me2.buyArea(1, 1, 1, 1, {from: buyer, value: web3.toWei(5, 'wei'), gas: 4712388});
    logGas(tx, "buyArea from landlord (1 block");

    const after = await mehState(me2);
    const deltas = {
        user_1_bal: 5,
        user_2_bal: 0,
        admin_bal: web3.toWei(0, 'wei'),
        charity_bal: web3.toWei(0, 'wei'),
        contract_bal: 0,
        contract_bal_eth: 5,
        blocks_sold: 0
    }
    checkStateChange(before, after, deltas);

    assert.equal(await me2.getBlockOwner.call(1, 1), buyer,                       
        "the block 1x1 owner wasn't set");  
  })

// Illegal buy/sell actions

  it("should permit buying block not marked for sale", async () => {
    const me2 = await MillionEther.deployed();
    const buyer = user_1;
    const owner = await me2.getBlockOwner.call(1, 1);
    var error = "";
    try {
        const tx = await me2.buyArea(1, 1, 1, 1, {from: buyer, value: web3.toWei(1, 'ether'), gas: 4712388});
    } catch (err) {
        error = err
    }
    assert.equal(await me2.getBlockOwner.call(1, 1), owner, "changed owner of block!");
    assert.equal(error.message.substring(43,49), "revert", "allowed buying block not marked for sale!");
  })

  it("should permit buying block beyond 1000x1000 px field (requireLegalCoordinates)", async () => {
    const me2 = await MillionEther.deployed();
    const buyer = user_1;
    var error = "";
    try {
        const tx = await me2.buyArea(100, 101, 100, 101, {from: buyer, value: web3.toWei(1, 'ether'), gas: 4712388});
    } catch (err) {
        error = err
    }
    assert.equal(await me2.exists.call(getBlockId(100, 101)), false, "minted a block outside 100x100 field!");
    assert.equal(error.message.substring(43,49), "revert", "allowed buying block beyond 100x100 field!");
  })

  it("should permit selling other landlord's block", async () => {
    const me2 = await MillionEther.deployed();
    const seller = user_1;
    var error = "";
    try {
        const tx = await me2.sellArea(1, 1, 1, 1, 100, {from: seller, gas: 4712388});
    } catch (err) {
        error = err
    }
    assert.equal(error.message.substring(43,49), "revert", "allowed selling other landlord's block!");
  })

  it("should permit selling crowdsale block", async () => {
    const me2 = await MillionEther.deployed();
    const buyer = user_1;
    var error = "";
    try {
        const tx = await me2.sellArea(1, 2, 1, 2, 100, {from: buyer, gas: 4712388});
    } catch (err) {
        error = err
    }
    assert.equal(error.message.substring(43,49), "revert", "allowed selling crowdsale block!");
  })


//buy own block(1, 2)
  it("should permit buying own blocks", async () => {
    const me2 = await MillionEther.deployed();
    const buyer = user_1;
    var tx = await me2.buyArea(1, 2, 1, 2, {from: buyer, value: web3.toWei(1000, 'wei'), gas: 4712388});
    tx = await me2.sellArea(1, 2, 1, 2, 1000, {from: buyer, gas: 4712388});
    var error = "";
    try {
        tx = await me2.buyArea(1, 2, 1, 2, {from: buyer, value: web3.toWei(1, 'ether'), gas: 4712388});
    } catch (err) {
        error = err
    }
    assert.equal(error.message.substring(43,49), "revert", "allowed buying own block!");
  })

//stop selling block(1, 2)
  it("should let stop selling blocks", async () => {
    const me2 = await MillionEther.deployed();
    const seller = user_1;
    const buyer = user_2;
    var tx = await me2.sellArea(1, 2, 1, 2, 0, {from: seller, gas: 4712388});

    var error = "";
    try {
        tx = await me2.buyArea(1, 2, 1, 2, {from: buyer, value: web3.toWei(1, 'ether'), gas: 4712388});
    } catch (err) {
        error = err
    }
    assert.equal(error.message.substring(43,49), "revert", "allowed buying own block!");
    const first_block_owner = await me2.getBlockOwner.call(1, 2);
    assert.equal(first_block_owner, seller,                       
        "first block owner wasn't set correctly");
    })

// buy 5 blocks
  it("should let buy 5 blocks (bottom-right)", async () => {
    const me2 = await MillionEther.deployed();
    const buyer = user_1;
    const before = await mehState(me2);

    const tx = await me2.buyArea(96, 100, 100, 100, {from: buyer, value: web3.toWei(5000, 'wei'), gas: 4712388});
    logGas(tx, "buyArea (5 blocks");

    const after = await mehState(me2);
    const deltas = {
        user_1_bal: 0,
        user_2_bal: 0,
        admin_bal: web3.toWei(1000, 'wei'),
        charity_bal: web3.toWei(4000, 'wei'),
        contract_bal: 0,
        contract_bal_eth: 5000,
        blocks_sold: 5
    }
    checkStateChange(before, after, deltas);
    assert.equal(await me2.getBlockOwner.call(100, 100), buyer,                       
        "the block 1x1 owner wasn't set"); 
    })

// sell 5 blocks
  it("should let sell blocks", async () => {
    const me2 = await MillionEther.deployed();
    const seller = user_1;
    const buyer = user_2;
    const before = await mehState(me2);

    var tx = await me2.sellArea(96, 100, 100, 100, 2000, {from: seller, gas: 4712388});
    logGas(tx, "sellArea (5 blocks");
    tx = await me2.buyArea(96, 100, 100, 100, {from: buyer, value: web3.toWei(20000, 'wei'), gas: 4712388});
    logGas(tx, "buyArea (5 blocks from a landlord");

    const after = await mehState(me2);
    const deltas = {
        user_1_bal: 10000,
        user_2_bal: 10000,
        admin_bal: web3.toWei(0, 'wei'),
        charity_bal: web3.toWei(0, 'wei'),
        contract_bal: 0,
        contract_bal_eth: 20000,
        blocks_sold: 0
    }
    checkStateChange(before, after, deltas);

    assert.equal(await me2.getBlockOwner.call(96, 100), buyer,                       
        "first block owner wasn't set"); 
    assert.equal(await me2.getBlockOwner.call(100, 100), buyer,                       
        "last block owner wasn't set"); 
  })

//buy mixed blocks (from crowdsale and from a landlord)




  it("should import old block", async () => {
    const me2 = await MillionEther.deployed();
    const market = await Market.deployed();

    const oldOwner = "0xca9f7d9ad4127e374cdab4bd0a884790c1b03946";

    var tx = await market.adminImportOldMEBlock(19, 19, {from: admin, gas: 4712388});

    const first_block_owner = await me2.getBlockOwner.call(19, 19);

    assert.equal(first_block_owner, oldOwner,                       
        "first_block owner wasn't set correctly");

    })

});
