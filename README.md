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

### Smart contracts at Rinkeby testnet (Etherscan):

- [Million Ether Homepage 2](https://rinkeby.etherscan.io/address/0x98de3f35e9a3c39e6489e81ebbaa87b9fdf3bb79#code) - main user interface contract, immutable, stores ether and ERC721 token balances.
- [Market](https://rinkeby.etherscan.io/address/0xd14e6edd741c591628703e0f9248511216aed221#code) - upgradable module, responsible for buy-sell operations and charity.
- [Rentals](https://rinkeby.etherscan.io/address/0x988e534db317c660478905f3fdeab5ea621b7546#code) - upgradable module, responsible for rent operations.
- [Ads](https://rinkeby.etherscan.io/address/0x52714f934eee585a98a2af8545c607cc6ab2b8f9#code) - upgradable module, responsible for placing ads.

See code comments for tech details.

### Links:

- [White paper and documentation](http://docs.themillionetherhomepage.com/) (outdated - new version comming soon)
- [Reddit](https://www.reddit.com/r/MillionEther/)
- [Old version of The Million Ether Homepage](https://github.com/porobov/MillionEtherHomepage)