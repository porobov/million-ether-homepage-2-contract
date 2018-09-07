# The Million Ether Homepage 2
Decentralized advertising platform.

### Main features
- A 1000x1000 pixel field is displayed at TheMillionEtherHomepage.com. 
- Anyone can buy, sell, rent or rent out pixels, place ads within owned or rented area.
- Price doubles after every 10% of pixels sold. Starting price is $1 per 10x10 pixel block.
- 80% of initial sale income goes to charity.
- A 10x10 pixel block is an ERC721 token.

### Your benefits 
- Buy pixels early and sell, when the price goes up.
- Buy pixels and rent them out to advertisers.
- Advertise your own product.

### Smart contracts on Ethereum mainnet:
- [Million Ether Homepage 2 (MEH)](https://etherscan.io/address/0xCEf41878Db032586C835eE0890484399402A64f6#code) - main user interface contract, immutable, stores ether and ERC721 token balances.
- [Market](https://etherscan.io/address/0xa77ab358361d0f6ae1014cb071563138be3b94c3#code) - upgradable module, responsible for buy-sell operations and charity.
- [Rentals](https://etherscan.io/address/0x9f5280418d7a2a7df838a946fccbbf4f2f018233#code) - upgradable module, responsible for rent operations.
- [Ads](https://etherscan.io/address/0x8382c376d1a72ba8846ab03a3dce2bd94632f7dc#code) - upgradable module, responsible for placing ads.
- [OracleProxy](https://etherscan.io/address/0xbae9368d43e0299dc0280132f2c619ee9697e6e4) - fetches ETHUSD price from Kraken.com through Oracalize.

### Smart contracts on Rinkeby testnet:

- [Million Ether Homepage 2 (MEH)](https://rinkeby.etherscan.io/address/0x355f45a82ef3b2c2ceb634a86edd7600158db21b#code) - main user interface contract, immutable, stores ether and ERC721 token balances.
- [Market](https://rinkeby.etherscan.io/address/0xec4e2f32848c4f3d338e7e296868a10a32042336#code) - upgradable module, responsible for buy-sell operations and charity.
- [Rentals](https://rinkeby.etherscan.io/address/0x5bd303b75eaf596b6af0fd5746563329951768bb#code) - upgradable module, responsible for rent operations.
- [Ads](https://rinkeby.etherscan.io/address/0x11aa617c5d94f6223c6ea5a6fd904b722aab3c75#code) - upgradable module, responsible for placing ads.
- [OracleProxy](https://rinkeby.etherscan.io/address/0xa3a45be10d4ac070435f488920dbbc908c25746f) - fetches ETHUSD price from Kraken.com through Oracalize.

See code comments for tech details.

### Links:

- [White paper and documentation](http://docs.themillionetherhomepage.com/)
- [Reddit](https://www.reddit.com/r/MillionEther/)
- [Old version of The Million Ether Homepage](https://github.com/porobov/MillionEtherHomepage)