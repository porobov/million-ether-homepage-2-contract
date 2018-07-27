pragma solidity ^0.4.24;


// ERC721 
import "openzeppelin-solidity/contracts/token/ERC721/ERC721Token.sol";
import "./MEHAccessControl.sol";

/// @title MehERC721: Part of MEH contract responsible for ERC721 token management. Openzeppelin's
///  ERC721 implementation modified for the Million Ether Homepage. 
contract MehERC721 is ERC721Token("MillionEtherHomePage","MEH"), MEHAccessControl {

    /// @dev Checks rights to transfer block ownership. Locks tokens on sale.
    ///  Overrides OpenZEppelin's canTransfer modifier - so that tokens marked for sale can 
    ///  be transferred by Market contract only.
    modifier canTransfer(uint256 _blockId) {
        bool onSale = market.isOnSale(uint16(_blockId));
        require (
            (onSale && msg.sender == address(market)) ||
            (!(onSale)) && isApprovedOrOwner(msg.sender, _blockId)
        );
        _;
    }

    /// @dev mints a new block.
    ///  overrides _mint function to add pause/unpause functionality, onlyMarket access,
    ///  restricts totalSupply of blocks to 10000 (as there is only a 100x100 blocks field).
    function _mintCrowdsaleBlock(address _to, uint16 _blockId) external onlyMarket whenNotPaused {
        if (totalSupply() <= 9999) {
        _mint(_to, _blockId);
        }
    }

    /// @dev overrides approve function to add pause/unpause functionality
    function approve(address _to, uint256 _tokenId) public whenNotPaused {
        super.approve(_to, _tokenId);
    }
 
    /// @dev overrides setApprovalForAll function to add pause/unpause functionality
    function setApprovalForAll(address _to, bool _approved) public whenNotPaused {
        super.setApprovalForAll(_to, _approved);
    }    

    /// @dev overrides transferFrom function to add pause/unpause functionality
    ///  affects safeTransferFrom functions as well
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        public
        whenNotPaused
    {
        super.transferFrom(_from, _to, _tokenId);
    }
}