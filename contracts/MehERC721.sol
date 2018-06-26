pragma solidity ^0.4.24;


// ERC721 
import "openzeppelin-solidity/contracts/token/ERC721/ERC721Token.sol";
import "./MEHAccessControl.sol";

contract MehERC721 is ERC721Token("MillionEtherHomePage","MEH"), MEHAccessControl {

    /// @dev Check rights to transfer block ownership
    /// @notice Overrides basic modifier - locks tokens on sale
    modifier canTransfer(uint256 _blockId) {
        bool onSale = market.isOnSale(uint16(_blockId));
        require (
            (onSale && msg.sender == address(market)) ||
            (!(onSale)) && isApprovedOrOwner(msg.sender, _blockId)
        );
        _;
    }

    /// @dev mint new blockId
    /// @notice override _mint function to add pause/unpause, onlyMarket access,
    ///  restricts totalSupply of blocks down to 10000
    function _mintCrowdsaleBlock(address _to, uint16 _blockId) external onlyMarket whenNotPaused {
        if (totalSupply() <= 9999) {
        _mint(_to, _blockId);
        }
    }

    /// @dev override approve function to add pause/unpause functionality
    function approve(address _to, uint256 _tokenId) public whenNotPaused {
        super.approve(_to, _tokenId);
    }
 
    /// @dev override setApprovalForAll function to add pause/unpause functionality
    function setApprovalForAll(address _to, bool _approved) public whenNotPaused {
        super.setApprovalForAll(_to, _approved);
    }    

    /// @dev override transferFrom to add pause/unpause functionality
    /// @notice affects both safeTransferFrom functions as well
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