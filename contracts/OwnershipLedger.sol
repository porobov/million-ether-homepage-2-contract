pragma solidity ^0.4.18;

import "./Storage.sol";
import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-solidity/contracts/token/ERC721/ERC721Basic.sol";
import "openzeppelin-solidity/contracts/token/ERC721/ERC721Token.sol";

contract OwnershipLedger is ERC721Token("MillionEtherHomePage","MEH"), Storage {


    // Blocks
    struct Block {           //Blocks are 10x10 pixel areas. There are 10 000 blocks.
        address landlord;    //block owner
        uint sellPrice;      //price if willing to sell, 0 if not
    }
    Block[101][101] public blocks; 

    mapping(uint16 => uint) public blockPrices;

    // SETTERS
    function _setMEHApprovalForAll(address _landlord) internal {
        // client == MEH
        if (!(isApprovedForAll(_landlord, client))) {
            require(_landlord != msg.sender);
            // require(msg.sender == client);
            operatorApprovals[_landlord][client] = true;
            emit ApprovalForAll(_landlord, client, true);
        }
    }

    function mint(address to, uint256 tokenId) public onlyClient {
        if (totalSupply() <= 9999) {
        _mint(to, tokenId);
        _setMEHApprovalForAll(to);
        }
    }

    function setBlockOwner(uint8 _x, uint8 _y, address _newOwner) external onlyClient returns (bool) {
        blocks[_x][_y].landlord = _newOwner;
        return true;
    } 

    function setSellPrice(uint8 _x, uint8 _y, uint _sellPrince) external onlyClient returns (bool) {
        blocks[_x][_y].sellPrice = _sellPrince;
        return true;
    }

    function setPrice(uint16 _id, uint _sellPrince) external onlyClient {
        blockPrices[_id] = _sellPrince;
    }

    // GETTERS

    function getPrice(uint16 _id) external view returns (uint) {
        return blockPrices[_id];
    }

    function getBlockOwner(uint8 _x, uint8 _y) external view returns (address) {
        return blocks[_x][_y].landlord;
    } 

    function getSellPrice(uint8 _x, uint8 _y) external view returns (uint) {
        return blocks[_x][_y].sellPrice;
    } 
}