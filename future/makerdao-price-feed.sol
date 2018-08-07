pragma solidity ^0.4.23;


contract PriceFeed {

    uint128       val;
    uint32 public zzz;

    function peek() external view returns (bytes32,bool)
    {
        return (bytes32(val), now < zzz);
    }

    function read() external view returns (bytes32)
    {
        require(now < zzz);
        return bytes32(val);
    }

}

// price feeds list
// https://makerdao.com/feeds/

// https://etherscan.io/address/0x137Fdd00E9a866631d8DAf1a2116fb8df1ed07A7
// example peek return
// 0: bytes32: 0x000000000000000000000000000000000000000000000016473736a3fe880000
// 1: bool: true
// 16473736a3fe880000 -> 410960000000000000000 (https://www.rapidtables.com/convert/number/hex-to-decimal.html)
// 410,96 - ETHUSD price