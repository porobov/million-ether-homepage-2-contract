pragma solidity ^0.4.24;


// ERC721 
import "openzeppelin-solidity/contracts/token/ERC721/ERC721Token.sol";
import "./MEHAccessControl.sol";

/// @title MehERC721: Part of MEH contract responsible for ERC721 token management. Openzeppelin's
///  ERC721 implementation modified for the Million Ether Homepage. 
contract MehERC721 is ERC721Token("MillionEtherHomePage","MEH"), MEHAccessControl {

    /// @dev Checks rights to transfer block ownership. Locks tokens on sale.
    ///  Overrides OpenZEppelin's isApprovedOrOwner function - so that tokens marked for sale can 
    ///  be transferred by Market contract only.
    function isApprovedOrOwner(
        address _spender,
        uint256 _tokenId
    )
        internal
        view
        returns (bool)
    {   
        bool onSale = market.isOnSale(uint16(_tokenId));

        address owner = ownerOf(_tokenId);
        bool spenderIsApprovedOrOwner =
            _spender == owner ||
            getApproved(_tokenId) == _spender ||
            isApprovedForAll(owner, _spender);

        return (
            (onSale && _spender == address(market)) ||
            (!(onSale) && spenderIsApprovedOrOwner)
        );
    }

    /// @dev mints a new block.
    ///  overrides _mint function to add pause/unpause functionality, onlyMarket access,
    ///  restricts totalSupply of blocks to 10000 (as there is only a 100x100 blocks field).
    function _mintCrowdsaleBlock(address _to, uint16 _blockId) external onlyMarket whenNotPaused {
        if (totalSupply() <= 9999) {
        _mint(_to, uint256(_blockId));
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