var MEStorage = artifacts.require("./OwnershipLedger.sol");
var OldeMillionEther = artifacts.require("./OldeMillionEther.sol");
var MillionEther = artifacts.require("./MillionEther.sol");


contract('MillionEther', function(accounts) {

  var admin = web3.eth.accounts[0]
  var user_1 = web3.eth.accounts[1]
  var user_2 = web3.eth.accounts[2]
  var charityAddress = '0x616c6C20796F75206e656564206973206C6f7665'

  // Helpers

  function getBlockId(x, y) {
    return (y - 1) * 100 + x;
  }

  function logGas(_tx, _tx_name) {
    console.log("       > gasUsed for", _tx_name, _tx.receipt.gasUsed, '|', _tx.receipt.cumulativeGasUsed);
  }

/*
 # Покупаем 1 блок. Алиса покупает 1 блок (buyArea, getBlockPriceAndOwner, incrementBlocksSold)
$1 - 0
Проверяем:
- Она владелец этого блока (getBlockPriceAndOwner)
- Количество проданных блоков увеличилось
- Благотворительность и владелец получили деньги
- Баланс контракта увеличился
*/

  it("should let buy a block 1x1", async () => {
    const me2 = await MillionEther.deployed();
    const me2storage = await MEStorage.deployed();

    const buyer = user_1;
    const blocks_sold_before = await me2.blocksSold.call();
    const admin_bal_before = await me2.balances.call(admin);
    const charity_bal_berore = await me2.balances.call(charityAddress);

    tx = await me2.buyArea(1, 1, 1, 1, {from: buyer, value: web3.toWei(100, 'wei'), gas: 4712388});
    logGas(tx, "buyArea (one block");

    const blocks_sold_after = await me2.blocksSold.call();
    const block_1_1_owner = await me2storage.getBlockOwner.call(1, 1);
    const admin_bal_after = await me2.balances.call(admin);
    const charity_bal_after = await me2.balances.call(charityAddress);

    assert .equal(admin_bal_after.toNumber() - admin_bal_before.toNumber(), web3.toWei(20, 'wei'), 
        "admin balance didn't increase right")
    assert .equal(charity_bal_after.toNumber() - charity_bal_berore.toNumber(), web3.toWei(80, 'wei'),    
        "charity balance didn't increase right")
    assert.equal(blocks_sold_after - blocks_sold_before, 1,    
        "blocksSold didn't increment by 1 (incrementBlocksSold)")
    assert.equal(block_1_1_owner, buyer,                       
        "the block 1x1 owner wasn't set");
  })


  it("should let buy erc blocks", async () => {
    const me2 = await MillionEther.deployed();
    const me2storage = await MEStorage.deployed();

    const buyer = user_1;
    const admin_bal_before = await me2.balances.call(admin);
    const charity_bal_berore = await me2.balances.call(charityAddress);

    tx = await me2.buyERCArea(15, 15, 20, 15, {from: buyer, value: web3.toWei(600, 'wei'), gas: 4712388});
    logGas(tx, "buyArea (one block");

    const admin_bal_after = await me2.balances.call(admin);
    const charity_bal_after = await me2.balances.call(charityAddress);

    assert .equal(admin_bal_after.toNumber() - admin_bal_before.toNumber(), web3.toWei(120, 'wei'), 
        "admin balance didn't increase right");
    assert .equal(charity_bal_after.toNumber() - charity_bal_berore.toNumber(), web3.toWei(480, 'wei'),    
        "charity balance didn't increase right");   
  })



/*
# Много блоков
$1 - 1
- Покупаем много блоков. Боб покупает 6 блоков (buyArea, getBlockPriceAndOwner, incrementBlocksSold, depositToAdminAndCharity, depositTo)
- Внести средств для покупки 16 блоков.
- Проверить, что владелец получил 2 вей, а благотворительность 4 вей, а у Боба осталось 10. 
- Баланс контракта увеличился

- Покупаем много блоков снова. Боб покупает 10 блоков (depositToAdminAndCharity, deductFrom)
- Проверить, что владелец получил 2 эфира, а благотворительность 8
- Проверить, что у Боба баланс равен 0. 
*/

  it("should let buy many block", async () => {
    const me2 = await MillionEther.deployed();
    const me2storage = await MEStorage.deployed();

    const buyer = user_2;
    const blocks_sold_before = await me2.blocksSold.call();
    const contract_balance_before = await web3.eth.getBalance(me2.address);

    const tx = await me2.buyArea(1, 3, 6, 3, {from: buyer, value: web3.toWei(1600, 'wei'), gas: 4712388});
    logGas(tx, "buyArea (6 blocks");

    const blocks_sold_after = await me2.blocksSold.call();
    const block_6_3_owner = await me2storage.getBlockOwner.call(6, 3);
    const buyer_bal_after = await me2.balances.call(buyer);
    const contract_balance_after = await web3.eth.getBalance(me2.address);

    assert.equal(blocks_sold_after.toNumber() - blocks_sold_before.toNumber(), 6, 
        "blocksSold didn't increment right")
    assert.equal(buyer_bal_after.toNumber(), web3.toWei(1000, 'wei'), 
        "buyer balance wasn't calculated right")
    assert.equal(block_6_3_owner, buyer, 
        "the block 6x3 owner wasn't set to buyer");
    assert.equal(contract_balance_after.toNumber() - contract_balance_before.toNumber(), 1600, 
        "contract balance didn't increase right");
    })


// Illegal buy/sell actions

  it("should permit buying block not marked for sale (onlyForSale)", async () => {
    const me2 = await MillionEther.deployed();
    const buyer = user_1;
    var error = "";
    try {
        const tx = await me2.buyArea(1, 3, 1, 3, {from: buyer, value: web3.toWei(1, 'ether'), gas: 4712388});
    } catch (err) {
        error = err
    }
    assert.equal(error.message.substring(43,49), "revert", "allowed buying block not marked for sale!");
  })

  it("should permit buying block beyond 1000x1000 px field (requireLegalCoordinates)", async () => {
    const me2 = await MillionEther.deployed();
    const buyer = user_1;
    var error = "";
    try {
        const tx = await me2.buyArea(100, 101, 100, 101, {from: buyer, value: web3.toWei(1600, 'wei'), gas: 4712388});
    } catch (err) {
        error = err
    }
    assert.equal(error.message.substring(43,49), "revert", "allowed buying block beyond 1000x1000 px field!");
  })

  it("should permit selling other landlord's block (requireBlockOwnership)", async () => {
    const me2 = await MillionEther.deployed();
    const buyer = user_1;
    var error = "";
    try {
        const tx = await me2.sellArea(1, 3, 1, 3, 100, {from: buyer, gas: 4712388});
    } catch (err) {
        error = err
    }
    assert.equal(error.message.substring(43,49), "revert", "allowed selling other landlord's block!");
  })

  it("should permit selling crowdsale block (requireBlockOwnership)", async () => {
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

// # Продажа блоков
// - Выставляем блоки на продажу. Боб выставляет блоки на продажу
// - Проверить, что блоки на продаже (getBlockPriceAndOwner)
// - Покупаем у landlord'a. Алиса покупает 30 блоков, включая блоки боба
// - Проверить баланс Боба и Алисы
// - Снять блок с продажи


// Selling blocks

  it("should let sell blocks", async () => {
    const me2 = await MillionEther.deployed();
    const me2storage = await MEStorage.deployed();

    const seller = user_2;
    const buyer = user_1;
    const seller_bal_before = await me2.balances.call(seller);
    const buyer_bal_before = await me2.balances.call(buyer);
    const blocks_sold_before = await me2.blocksSold.call();

    var tx = await me2.sellArea(1, 3, 6, 3, 200, {from: seller, gas: 4712388});
    // selling and buying from theirown
    tx = await me2.sellArea(1, 1, 1, 1, 100, {from: buyer, gas: 4712388});
    // buy 15 blocks, including her own one, 5 from other landlord, leave block 6x3 on sale
    tx = await me2.buyArea(1, 1, 5, 3, {from: buyer, value: web3.toWei(1900, 'wei'), gas: 4712388});
    logGas(tx, "buyArea (15 blocks, 6 from a landlord");

    const seller_bal_after = await me2.balances.call(seller);
    const buyer_bal_after = await me2.balances.call(buyer);
    const blocks_sold_after = await me2.blocksSold.call();
    const block_5_3_owner = await me2storage.getBlockOwner.call(5, 3);
    

    assert.equal(seller_bal_after.toNumber() - seller_bal_before.toNumber(), 1000, 
        "seller_bal didn't increment right");
    assert.equal(buyer_bal_after.toNumber() - buyer_bal_before.toNumber(), 0,
        "buyer_bal changed");
    assert.equal(blocks_sold_after - blocks_sold_before, 9,    
        "blocksSold didn't increment by 9 (incrementBlocksSold)")
    assert.equal(block_5_3_owner, buyer,                       
        "the block 5x3 owner wasn't set correctly");
  })


  it("should let stop selling blocks", async () => {
    const me2 = await MillionEther.deployed();
    const me2storage = await MEStorage.deployed();

    const seller = user_2;
    const buyer = user_1;

    // mark 6x3 not for sale
    var tx = await me2.sellArea(6, 3, 6, 3, 0, {from: seller, gas: 4712388});
    var error = "";
    try {
        const tx = await me2.buyArea(6, 3, 6, 3, {from: buyer, value: web3.toWei(1900, 'wei'), gas: 4712388});
    } catch (err) {
        error = err
    }
    const block_6_3_owner = await me2storage.getBlockOwner.call(6, 3);

    assert.equal(error.message.substring(43,49), "revert", 
        "allowed selling crowdsale block!");
    assert.equal(block_6_3_owner, seller,                       
        "the block 6x3 owner wasn't set correctly");
  })


  // TODO try mul with mul(322, 0) or mul(0, 322)

  //  function placeImage (uint8 fromX, uint8 fromY, uint8 toX, uint8 toY, string imageSourceUrl, string adUrl, string adText) 

  it("should let place image", function() {

    var buyer_1 = user_1;
    var image_id_before;
    var image_id_after;
    

    return MillionEther.deployed().then(function(instance) {
        me2 = instance;
        return MEStorage.deployed().then(function(instance) {
            me2storage = instance;
            return me2.numImages.call();
        }).then(function(id) {
            image_id_before = id.toNumber();
            return me2.placeImage(1, 1, 8, 9, "sadf","sfa","asdgbb", {from: buyer_1, gas: 4712388});
        }).then(function(tx) {
            logGas(tx, "placeImage");
            return me2.numImages.call();
        }).then(function(id) {
            image_id_after = id.toNumber();

            assert.equal(image_id_after - image_id_before, 1, "the image id wasn't incremented");
        });
    });
  });

});
