var OldeMillionEther = artifacts.require("../test/mockups/OldeMillionEther.sol");
var MillionEther = artifacts.require("./MEH.sol");
var Market = artifacts.require("./Market.sol");
var Ads = artifacts.require("./Ads.sol");
var Rentals = artifacts.require("../test/mockups/RentalsDisposable.sol");
var OracleProxy = artifacts.require("../test/mockups/OracleProxy.sol");

var OracleProxyStub = artifacts.require("../test/mockups/OracleProxyStub.sol");
var MarketStub = artifacts.require("../test/mockups/MarketStub.sol");


const BASIC = false;
const ERC721 = false;
const BUY_SELL_5_BLOCKS = false;
const BUY_MIXED_BLOCKS = false;
const RENT = false;
const ADS = false;
const ADMIN = false;
const CHECK_PRICE_DOUBLING = false;

contract('MillionEther', function(accounts) {

  var admin = web3.eth.accounts[0];
  var user_1 = web3.eth.accounts[1];
  var user_2 = web3.eth.accounts[2];
  var user_3 = web3.eth.accounts[3];
  var charityAddress = '0x616c6C20796F75206e656564206973206C6f7665';

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
    assert.equal(after.blocks_sold - before.blocks_sold, deltas.blocks_sold,    
        "totalSupply delta was wrong");
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
  }

  const no_changes = {
        user_1_bal: 0,
        user_2_bal: 0,
        admin_bal: 0,
        charity_bal: 0,
        contract_bal: 0,
        contract_bal_eth: 0,
        blocks_sold: 0
    }

  async function assertThrows(foo, msg) {
    var error = {};
    error.message = "";
    try {
        const tx = await foo;
    } catch (err) {
        error = err;
    }
    console.log(error.message);
    assert.equal(error.message.substring(43,49), "revert", msg);
  }

  //credits https://github.com/OpenZeppelin/openzeppelin-solidity/blob/f4228f1b49d6d505d3311e5d962dfb0febdf61df/test/Bounty.test.js#L82-L109
  function awaitEvent (event, handler) {
      return new Promise((resolve, reject) => {
        function wrappedHandler (...args) {
          Promise.resolve(handler(...args)).then(resolve).catch(reject);
        }
        event.watch(wrappedHandler);
      });
  }

  // console.log(web3.eth.getBlock(tx.receipt.blockNumber));


if (BASIC) {
// buy 1 block (1, 1)
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

// sell 1 block (1, 1)
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

// Illegal buy/sell actions (1, 1) 

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
    const before = await mehState(me2);
    var error = "";
    try {
        const tx = await me2.sellArea(1, 1, 1, 1, 100, {from: seller, gas: 4712388});
    } catch (err) {
        error = err
    }

    const after = await mehState(me2);
    checkStateChange(before, after, no_changes);
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

// withdraw(1, 3)
  it("should let withdraw funds", async () => {
    const me2 = await MillionEther.deployed();
    const buyer = user_1;
    // put excessive ammount
    var tx = await me2.buyArea(1, 3, 1, 3, {from: buyer, value: web3.toWei(10, 'ether'), gas: 4712388});

    const before = await mehState(me2);
    const buyer_eth_bal_before = await web3.eth.getBalance(buyer);

    tx = await me2.withdraw({from: buyer, gas: 4712388}); 
    paid_for_gas = web3.toWei(tx.receipt.gasUsed * 100, 'Shannon');  // 100 Shannon - default gas price in Truffle. TODO prepare for Rinkeby
    const after = await mehState(me2);
    var deltas = {
        user_1_bal: -before.user_1_bal,
        contract_bal_eth: -before.user_1_bal,
        user_2_bal: 0, admin_bal: 0, charity_bal: 0, contract_bal: 0, blocks_sold: 0
    }
    const buyer_eth_bal_after = await web3.eth.getBalance(buyer);

    assert.equal(buyer_eth_bal_after.minus(buyer_eth_bal_before).toNumber(), before.user_1_bal.minus(paid_for_gas).toNumber(),                       
        "buyer didn't recieve all funds");
    })
}

if (ERC721) {
// ERC721. Transfer ownership by landlord (Cannot transfer when on sale) (10, 1)
  it("should let transfer block ownership (and permit when on sale)", async () => {
    const me2 = await MillionEther.deployed();
    const buyer = user_1;
    const new_landlord = user_2;
    var tx = await me2.buyArea(10, 1, 10, 1, {from: buyer, value: web3.toWei(2000, 'wei'), gas: 4712388});

    var before = await mehState(me2);
    console.log("blocks_sold", before.blocks_sold);
    tx = await me2.safeTransferFrom(buyer, new_landlord, getBlockId(10, 1), {from: buyer, gas: 4712388});
    var after = await mehState(me2);
    checkStateChange(before, after, no_changes);

    before = await mehState(me2);
    tx = await me2.sellArea(10, 1, 10, 1, 5, {from: new_landlord, gas: 4712388});
        var error = "";
    try {
        tx = await me2.safeTransferFrom(new_landlord, buyer, getBlockId(10, 1), {from: new_landlord, gas: 4712388});
    } catch (err) {
        error = err
    }
    after = await mehState(me2);
    checkStateChange(before, after, no_changes);
    assert.equal(error.message.substring(43,49), "revert", "allowed buying own block!");
    assert.equal(await me2.getBlockOwner.call(10, 1), new_landlord,                       
        "the block owner wasn't set");  
  })

// ERC721. Transfer ownership by approved (Cannot transfer when on sale) (11, 1)
  it("should let transfer block ownership by an approved party (and permit when on sale)", async () => {
    const me2 = await MillionEther.deployed();
    const buyer = user_1;
    const new_landlord = user_2;
    const third_party = user_3;
    var tx = await me2.buyArea(11, 1, 11, 1, {from: buyer, value: web3.toWei(2000, 'wei'), gas: 4712388});

    var before = await mehState(me2);
    tx = await me2.approve(third_party, getBlockId(11, 1), {from: buyer, gas: 4712388});
    tx = await me2.safeTransferFrom(buyer, new_landlord, getBlockId(11, 1), {from: third_party, gas: 4712388});
    var after = await mehState(me2);
    checkStateChange(before, after, no_changes);

    before = await mehState(me2);
    tx = await me2.sellArea(11, 1, 11, 1, 5, {from: new_landlord, gas: 4712388});
    tx = await me2.approve(third_party, getBlockId(11, 1), {from: new_landlord, gas: 4712388});
        var error = "";
    try {
        tx = await me2.safeTransferFrom(new_landlord, buyer, getBlockId(11, 1), {from: third_party, gas: 4712388});
    } catch (err) {
        error = err
    }
    after = await mehState(me2);
    checkStateChange(before, after, no_changes);
    assert.equal(error.message.substring(43,49), "revert", "allowed buying own block!");
    assert.equal(await me2.getBlockOwner.call(11, 1), new_landlord,                       
        "the block owner wasn't set");  
  })

// ERC721. Transfer ownership by approvedForAll (Cannot transfer when on sale) (12, 1)
  it("should let transfer block ownership by an approvedForAll party (and permit when on sale)", async () => {
    const me2 = await MillionEther.deployed();
    const buyer = user_1;
    const new_landlord = user_2;
    const third_party = user_3;
    var tx = await me2.buyArea(12, 1, 12, 1, {from: buyer, value: web3.toWei(2000, 'wei'), gas: 4712388});

    var before = await mehState(me2);
    tx = await me2.setApprovalForAll(third_party, true, {from: buyer, gas: 4712388});
    tx = await me2.safeTransferFrom(buyer, new_landlord, getBlockId(12, 1), {from: third_party, gas: 4712388});
    var after = await mehState(me2);
    checkStateChange(before, after, no_changes);

    before = await mehState(me2);
    tx = await me2.sellArea(12, 1, 12, 1, 5, {from: new_landlord, gas: 4712388});
    tx = await me2.setApprovalForAll(third_party, true, {from: new_landlord, gas: 4712388});
        var error = "";
    try {
        tx = await me2.safeTransferFrom(new_landlord, buyer, getBlockId(12, 1), {from: third_party, gas: 4712388});
    } catch (err) {
        error = err
    }
    after = await mehState(me2);
    checkStateChange(before, after, no_changes);
    assert.equal(error.message.substring(43,49), "revert", "allowed buying own block!");
    assert.equal(await me2.getBlockOwner.call(12, 1), new_landlord,                       
        "the block owner wasn't set");  
  })
}

if (BUY_SELL_5_BLOCKS) {
// buy 5 blocks (96, 100) - (100,100)
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

// sell 5 blocks (96, 100)
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
}

if (BUY_MIXED_BLOCKS) {
// buy mixed blocks (1, 98) - (5,100)
  it("should let buy mixed blocks (from crowdsale and from a landlord)", async () => {
    const me2 = await MillionEther.deployed();
    const seller = user_1;
    const buyer = user_2;
    const before = await mehState(me2);

    var tx = await me2.buyArea(1, 99, 5, 99, {from: seller, value: web3.toWei(5000, 'wei'), gas: 4712388});
    tx = await me2.sellArea(1, 99, 5, 99, 2000, {from: seller, gas: 4712388});
    tx = await me2.buyArea(1, 98, 5, 100, {from: buyer, value: web3.toWei(20000, 'wei'), gas: 4712388});

    const after = await mehState(me2);
    const deltas = {
        user_1_bal: 10000,
        user_2_bal: 0,
        admin_bal: web3.toWei(3000, 'wei'),
        charity_bal: web3.toWei(12000, 'wei'),
        contract_bal: 0,
        contract_bal_eth: 25000,
        blocks_sold: 15
    }
    checkStateChange(before, after, deltas);

    assert.equal(await me2.getBlockOwner.call(1, 98), buyer,                       
        "first block owner wasn't set"); 
    assert.equal(await me2.getBlockOwner.call(5, 100), buyer,                       
        "last block owner wasn't set"); 
  })
}















if (RENT) {
// RENT OUT AND RENT BLOCKS ** // (70,1) - (80, 5)

const MAX_RENT_PERIODS = 90;

async function checkRentState(blockID, expected) {
    var rentals = await Rentals.deployed();
    var rent_price = await rentals.blockIdToRentPrice.call(blockID);
    var rent_deal = await rentals.blockIdToRentDeal.call(blockID);

    assert.equal(rent_price, expected.rent_price, "Rent price wasn't set correctly!");
    assert.equal(rent_deal[0], expected.renter, "Renter wasn't set correctly!"); 
    assert.equal(rent_deal[2].toNumber(), expected.numberOfPeriods, "Number of periods wasn't set correctly!"); 
}

// should let rent out and rent area (check balances as well) (70,1) - (71, 2)
  it("should let rent out and rent area", async () => {
    const me2 = await MillionEther.deployed();
    const landlord = user_1;
    const renter = user_2;
    var tx = await me2.buyArea(70, 1, 71, 2, {from: landlord, value: web3.toWei(4000, 'wei'), gas: 4712388});

    var before = await mehState(me2);
    tx = await me2.rentOutArea(70, 1, 71, 2, 200, {from: landlord});
    tx = await me2.rentArea(70, 1, 71, 2, 2, {from: renter, value: web3.toWei(1600, 'wei'), gas: 4712388});
    var after = await mehState(me2);
    var deltas = no_changes; deltas.user_1_bal = 1600; deltas.contract_bal_eth = 1600;
    checkStateChange(before, after, deltas);
    var expected_rent_params = {
        rent_price: web3.toWei(200, 'wei'),
        renter: renter,
        rentedFrom: 0,
        numberOfPeriods: 2
    }
    checkRentState(getBlockId(70, 1), expected_rent_params);
  })

// should permit illegal rent actions (72,1) - (72, 1)
  it("should permit illegal rent out and rent actions", async () => {
    const me2 = await MillionEther.deployed();
    const landlord = user_1;
    const some_guy = user_2;
    const renter = user_3;
    assertThrows(me2.rentOutArea(72, 1, 72, 1, 200, {from: some_guy, gas: 4712388}), 
        "Rented out crowdsale block!");
    assertThrows(me2.rentArea(72, 1, 72, 1, 1, {from: some_guy, value: web3.toWei(1, 'ether'), gas: 4712388}), 
        "Rented crowdsale block!");

    var tx = await me2.buyArea(72, 1, 72, 1, {from: landlord, value: web3.toWei(1000, 'wei'), gas: 4712388});
    assertThrows(me2.rentOutArea(72, 1, 72, 1, 200, {from: some_guy, gas: 4712388}), 
        "Rented out other landlords blocks!");
    assertThrows(me2.rentArea(72, 1, 72, 1, 1, {from: some_guy, value: web3.toWei(1, 'ether'), gas: 4712388}), 
        "Rented block which is not for rent yet!");

    tx = await me2.rentOutArea(72, 1, 72, 1, 200, {from: landlord, gas: 4712388});
    assertThrows(me2.rentArea(72, 1, 72, 1, 1, {from: landlord, value: web3.toWei(1, 'ether'), gas: 4712388}), 
        "Rented own block!");
    await assertThrows(me2.rentArea(72, 1, 72, 1, MAX_RENT_PERIODS + 1, {from: renter, value: web3.toWei(1, 'ether'), gas: 4712388}), 
        "Rented for more than max rent periods!");

    tx = await me2.rentArea(72, 1, 72, 1, 1, {from: renter, value: web3.toWei(1600, 'wei'), gas: 4712388});
    assertThrows(me2.rentArea(72, 1, 72, 1, 1, {from: some_guy, value: web3.toWei(1, 'ether'), gas: 4712388}), 
        "Rented block which is already rented!");
  })


// should let stop rent (73,1) - (73, 1)
  it("should let stop rent", async () => {
    const me2 = await MillionEther.deployed();
    const rentMock = await Rentals.deployed();
    const landlord = user_1;
    const some_guy = user_2;
    const renter = user_3;

    var tx = await me2.buyArea(73, 1, 73, 1, {from: landlord, value: web3.toWei(1000, 'wei'), gas: 4712388});
    tx = await me2.rentOutArea(73, 1, 73, 1, 200, {from: landlord, gas: 4712388});
    tx = await me2.rentOutArea(73, 1, 73, 1, 0, {from: landlord, gas: 4712388});
    assertThrows(me2.rentArea(73, 1, 73, 1, 1, {from: some_guy, value: web3.toWei(1, 'ether'), gas: 4712388}), 
        "Rented block which is not for rent already!");

    tx = await me2.rentOutArea(73, 1, 73, 1, 200, {from: landlord, gas: 4712388});
    tx = await me2.rentArea(73, 1, 73, 1, 2, {from: renter, value: web3.toWei(400, 'wei'), gas: 4712388});
    tx = await me2.rentOutArea(73, 1, 73, 1, 0, {from: landlord, gas: 4712388});
    var expected_rent_params = {
        rent_price: web3.toWei(0, 'wei'),
        renter: renter,
        rentedFrom: 0,
        numberOfPeriods: 2
    }
    checkRentState(getBlockId(73, 1), expected_rent_params);
    tx = await rentMock.fastforwardRent(getBlockId(73, 1), {from: landlord, gas: 4712388});
    assertThrows(me2.rentArea(73, 1, 73, 1, 1, {from: some_guy, value: web3.toWei(1, 'ether'), gas: 4712388}), 
        "Rented block which is not for rent already!");
  })

// should let rent area after previous rent expires (74, 1) - (74, 2)
  it("should let rent area again after previous rent expires", async () => {
    const me2 = await MillionEther.deployed();
    const rentMock = await Rentals.deployed();
    const landlord = user_1;
    const some_guy = user_2;
    const renter = user_3;
    var tx = await me2.buyArea(74, 1, 74, 2, {from: landlord, value: web3.toWei(1000, 'wei'), gas: 4712388});
    
    var before = await mehState(me2);

    tx = await me2.rentOutArea(74, 1, 74, 2, 200, {from: landlord, gas: 4712388});
    tx = await me2.rentArea(74, 1, 74, 2, 2, {from: renter, value: web3.toWei(800, 'wei'), gas: 4712388})
    assertThrows(me2.rentArea(74, 1, 74, 2, 1, {from: some_guy, value: web3.toWei(1, 'ether'), gas: 4712388}), 
        "Rented block which is rented already!");
    tx = await rentMock.fastforwardRent(getBlockId(74, 1), {from: landlord, gas: 4712388});
    assertThrows(me2.rentArea(74, 1, 74, 2, 1, {from: some_guy, value: web3.toWei(1, 'ether'), gas: 4712388}), 
        "Rented block which is rented already!");
    tx = await rentMock.fastforwardRent(getBlockId(74, 2), {from: landlord, gas: 4712388});
    tx = await me2.rentArea(74, 1, 74, 2, 2, {from: some_guy, value: web3.toWei(800, 'wei'), gas: 4712388});
    var after = await mehState(me2);
    var deltas = no_changes; deltas.user_1_bal = 1600; deltas.contract_bal_eth = 1600;
    checkStateChange(before, after, deltas);
    var expected_rent_params = {
        rent_price: web3.toWei(200, 'wei'),
        renter: some_guy,
        rentedFrom: 0,
        numberOfPeriods: 2
    }
    checkRentState(getBlockId(74, 1), expected_rent_params);
  })

// should let rent area after previous rent expires (75, 1) - (75, 2)
  it("should let landlord place images only when current rent expires", async () => {
    const me2 = await MillionEther.deployed();
    const rentMock = await Rentals.deployed();
    const landlord = user_1;
    const renter = user_3;
    var tx = await me2.buyArea(75, 1, 75, 2, {from: landlord, value: web3.toWei(1000, 'wei'), gas: 4712388});
    
    tx = await me2.rentOutArea(75, 1, 75, 2, 200, {from: landlord, gas: 4712388});
    tx = await me2.rentArea(75, 1, 75, 2, 2, {from: renter, value: web3.toWei(800, 'wei'), gas: 4712388})
    assertThrows(me2.placeImage(75, 1, 75, 2, "imageSourceUrl", "adUrl", "adText",  {from: landlord, gas: 4712388}),
        "Landlord was able to place image when rent is not expired!");
    tx = await me2.placeImage(75, 1, 75, 2, "imageSourceUrl", "adUrl", "adText",  {from: renter, gas: 4712388});
    tx = await rentMock.fastforwardRent(getBlockId(75, 1), {from: landlord, gas: 4712388});
    tx = await rentMock.fastforwardRent(getBlockId(75, 2), {from: landlord, gas: 4712388});
    assertThrows(me2.placeImage(75, 1, 75, 2, "imageSourceUrl", "adUrl", "adText",  {from: renter, gas: 4712388}),
        "Landlord was able to place image when rent is not expired!");
    tx = await me2.placeImage(75, 1, 75, 2, "imageSourceUrl", "adUrl", "adText",  {from: landlord, gas: 4712388});
  })
}

if (ADS) {
// ** PLACE ADS ** //

// Place Ads (50, 1) - (54, 4)
// should let renter place ads - covered at rent section
// should permit owner place ads on rented property - covered at rent section
// should let owner place ads after rent period is over - covered at rent section
  it("should let landlord place images", async () => {
    const me2 = await MillionEther.deployed();
    const advertiser = user_1;
    const some_guy = user_2;

    await me2.buyArea(50, 1, 54, 4, {from: advertiser, value: web3.toWei(20000, 'wei'), gas: 4712388});
    assertThrows(me2.placeImage(50, 1, 54, 4, "imageSourceUrl", "adUrl", "adText",  {from: some_guy, gas: 4712388}),
        "Should've permited anybody to place ads!");
    await me2.placeImage(50, 1, 54, 4, "imageSourceUrl", "adUrl", "adText",  {from: advertiser, gas: 4712388});

  })


// place image in mixed area
  it("should let place image in mixed area (owned and rented)", async () => {
    const me2 = await MillionEther.deployed();
    const ads = await Ads.deployed();
    const advertiser = user_1;
    const some_guy = user_2;

    let event = ads.LogImage({});
    
    let watcher = async function (err, result) {
        event.stopWatching();
        if (err) { throw err; }
        assert.equal(result.event, "LogImage", "Wrong event!")
        assert.equal(result.args.publisher, advertiser, "Wrong publisher!")
    }

    await me2.buyArea(55, 1, 56, 2, {from: advertiser, value: web3.toWei(4000, 'wei'), gas: 4712388});
    await me2.buyArea(55, 3, 56, 4, {from: some_guy, value: web3.toWei(4000, 'wei'), gas: 4712388});
    await me2.rentOutArea(55, 3, 56, 4, 200, {from: some_guy, gas: 4712388});
    await me2.rentArea(55, 3, 56, 4, 2, {from: advertiser, value: web3.toWei(1600, 'wei'), gas: 4712388})
    await me2.placeImage(55, 1, 56, 4, "imageSourceUrl", "adUrl", "adText",  {from: advertiser, gas: 4712388});
    await awaitEvent(event, watcher);
    
  })
}








if (CHECK_PRICE_DOUBLING) {
// buy 10% of blocks (1, 8) - (40, 25)
  it("should double price after 10% of blocks sold", async () => {
    const me2 = await MillionEther.deployed();
    const very_rich_buyer = user_1;
    const before = await mehState(me2);

    const blocks_to_buy = 1000 - before.blocks_sold;
    const number_of_40_block_packs = Math.trunc(blocks_to_buy/40);
    var i; var tx;
    for (i = 0; i < number_of_40_block_packs; i++) { 
        tx = await me2.buyArea(1, 10+i, 40, 10+i, {from: very_rich_buyer, value: web3.toWei(40000, 'wei'), gas: 6721975});
    }
    logGas(tx, "buyArea from owner (40 block");

    const number_of_1_block_packs = blocks_to_buy % 40;
    if (number_of_1_block_packs > 0) {
       tx = await me2.buyArea(1, 9, number_of_1_block_packs, 9, {from: very_rich_buyer, value: web3.toWei(number_of_1_block_packs * 1000, 'wei'), gas: 6721975}); 
    }

    // buy block number 1001 at a doubled priced
    tx = await me2.buyArea(1, 8, 1, 8, {from: very_rich_buyer, value: web3.toWei(2000, 'wei'), gas: 6721975}); 

    const after = await mehState(me2);
    const deltas = {
        user_1_bal: 0,
        user_2_bal: 0,
        admin_bal: web3.toWei(blocks_to_buy * 200 + 2 * 200, 'wei') ,  // +1 one block at 2 USD
        charity_bal: web3.toWei(blocks_to_buy * 800 + 2 * 800, 'wei'),  // +1 one block at 2 USD
        contract_bal: 0,
        contract_bal_eth: blocks_to_buy * 1000 + 2 * 1000,  // +1 one block at 2 USD
        blocks_sold: blocks_to_buy + 1 // +1 one block at 2 USD
    }
    checkStateChange(before, after, deltas);
  })
}


if(ADMIN) {
// Admin import old block (19, 19) - (20, 20)
  it("should import old block", async () => {
    const me2 = await MillionEther.deployed();
    const market = await Market.deployed();
    const buyer = user_1;
    const oldOwner = "0xca9f7d9ad4127e374cdab4bd0a884790c1b03946";

    await me2.buyArea(20, 20, 20, 20, {from: buyer, value: web3.toWei(1000, 'wei'), gas: 4712388});
    assertThrows(market.adminImportOldMEBlock(20, 20, {from: admin, gas: 4712388}),
        "Imported on top of an owned block!");
    assertThrows(market.adminImportOldMEBlock(20, 20, {from: admin, gas: 4712388}),
        "Imported block with no landlord!");
    assertThrows(market.adminImportOldMEBlock(19, 19, {from: buyer, gas: 4712388}),
        "Only admin can import blocks!");
    var tx = await market.adminImportOldMEBlock(19, 19, {from: admin, gas: 4712388});
    logGas(tx, "Import OldME Block");
    
    const first_block_owner = await me2.getBlockOwner.call(19, 19);
    assert.equal(first_block_owner, oldOwner,                       
        "first_block owner wasn't set correctly");
    })

// Paused (1, 30) - (1, 31)
  it("should pause-unpause contracts", async () => {
    const me2 = await MillionEther.deployed();
    const market = await Market.deployed();
    const rentals = await Rentals.deployed();
    const ads = await Ads.deployed();
    const buyer = user_1;
    const renter = user_2;

    // deposit explicitly excessive funds to test withdrawal
    tx = await me2.buyArea(1, 30, 1, 30, {from: buyer, value: web3.toWei(10000, 'wei'), gas: 4712388});
    tx = await me2.rentOutArea(1, 30, 1, 30, 200, {from: buyer, gas: 4712388});

    assertThrows(me2.pause({from: buyer, gas: 4712388}),
        "Paused me2 by some guy!");
    assertThrows(market.pause({from: buyer, gas: 4712388}),
        "Paused market by some guy!");
    assertThrows(rentals.pause({from: buyer, gas: 4712388}),
        "Paused rentals by some guy!");
    assertThrows(ads.pause({from: buyer, gas: 4712388}),
        "Paused ads by some guy!");

    // pause-unpause modules
    await market.pause({from: admin, gas: 4712388});
    await rentals.pause({from: admin, gas: 4712388});
    await ads.pause({from: admin, gas: 4712388});
    assertThrows(me2.placeImage(1, 30, 1, 30, "imageSourceUrl", "adUrl", "adText",  {from: buyer, gas: 4712388}),
        "Should've permited to place ads when paused!");
    assertThrows(me2.sellArea(1, 30, 1, 30, 2, {from: buyer, gas: 4712388}),
        "Sold a block when paused!");
    assertThrows(me2.rentOutArea(1, 30, 1, 30, 100, {from: buyer}),
        "Rented out a block when paused!");
    assertThrows(me2.rentArea(1, 30, 1, 30, 2, {from: renter, value: web3.toWei(1600, 'wei'), gas: 4712388}),
        "Rented a block when paused!");
    assertThrows(me2.buyArea(1, 31, 1, 31, {from: buyer, value: web3.toWei(1000, 'wei'), gas: 4712388}),
        "Bought a block when paused!");
    await market.unpause({from: admin, gas: 4712388});
    await rentals.unpause({from: admin, gas: 4712388});
    await ads.unpause({from: admin, gas: 4712388});

    // pause-unpause main
    await me2.pause({from: admin, gas: 4712388});
    assertThrows(me2.withdraw({from: buyer, gas: 4712388}),
        "withdrawed when paused!");
    assertThrows(me2.placeImage(1, 30, 1, 30, "imageSourceUrl", "adUrl", "adText",  {from: buyer, gas: 4712388}),
        "Should've permited to place ads when paused!");
    assertThrows(me2.safeTransferFrom(buyer, renter, getBlockId(1, 30), {from: buyer, gas: 4712388}),
        "Safe Transfered block when paused!");    
    assertThrows(me2.approve(renter, getBlockId(1, 30), {from: buyer, gas: 4712388}),
        "Approved block transfer when paused!");    
    assertThrows(me2.setApprovalForAll(renter, true, {from: buyer, gas: 4712388}),
        "Set Approval For All when paused!");
    assertThrows(me2.sellArea(1, 30, 1, 30, 2, {from: buyer, gas: 4712388}),
        "Sold a block when paused!");
    assertThrows(me2.rentOutArea(1, 30, 1, 30, 100, {from: buyer}),
        "Rented out a block when paused!");
    assertThrows(me2.rentArea(1, 30, 1, 30, 2, {from: renter, value: web3.toWei(1600, 'wei'), gas: 4712388}),
        "Rented a block when paused!");
    assertThrows(me2.buyArea(1, 31, 1, 31, {from: buyer, value: web3.toWei(1000, 'wei'), gas: 4712388}),
        "Bought a block when paused!");
    await me2.unpause({from: admin, gas: 4712388});  //TODO why doesn't work without this line?
    })
}

// Admin: settings

// TODO admin setMaxRentPeriod
  it("Should let admin (and oonly admin) adjust settings", async () => {
    const me2 = await MillionEther.deployed();
    const market = await Market.deployed();
    
    // const rentals = await Rentals.deployed();
    // const ads = await Ads.deployed();
    const buyer = user_1;
    const renter = user_2;

    // set Oracle
    const new_oracle_proxy = await OracleProxyStub.deployed();
    assertThrows(market.adminSetOracle(OracleProxyStub.address, {from: buyer, gas: 4712388}),
        "Some guy just set new Oracle!");
    await market.adminSetOracle(OracleProxyStub.address, {from: admin, gas: 4712388});
    // todo - check price from meh assert.equal(await new_oracle_proxy.oneCentInWei.call(), 12345, "Wrond one Cent In Wei from new oracle");
    await market.adminSetOracle(OracleProxy.address, {from: admin, gas: 4712388});

    // set Market
    const new_market = await MarketStub.deployed(); 
    assertThrows(me2.adminSetMarket(new_market.address, {from: buyer, gas: 4712388}),
        "Some guy just set new Oracle!");
    await me2.adminSetMarket(new_market.address, {from: admin, gas: 4712388});
    // todo - try some foo from meh assert.equal(await new_market.charityPayed.call(), 12345, "Wrond one Cent In Wei from new oracle");
    await me2.adminSetMarket(market.address, {from: admin, gas: 4712388});

    // adminSetRentals
    // adminSetAds
  })

  it("Following best programming practicies, just some random empty test without which assertThrows just doesn't work properly for some unknown reason...", async () => {
  })

// transfer charity

// Admin: emergency
// adminRescueFunds

// Admin: transfer ownreship


// TODO check all necessary events


});
