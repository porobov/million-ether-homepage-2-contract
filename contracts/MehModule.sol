pragma solidity ^0.4.18;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/ownership/HasNoEther.sol";
import "openzeppelin-solidity/contracts/lifecycle/Destructible.sol";
import "openzeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "./MEH.sol";

contract MehModule is Ownable, Pausable, Destructible, HasNoEther {

    MEH  meh;

    constructor(address _mehAddress) public {
        adminSetMeh(_mehAddress);
    }
    
    modifier onlyMeh() {
        require(msg.sender == address(meh));
        _;
    }

    function adminSetMeh(address _address) internal onlyOwner {
        MEH candidateContract = MEH(_address);
        require(candidateContract.isMEH());
        meh = candidateContract;
    }

    function depositTo(address _recipient, uint _amount) internal {
        return meh.operatorDepositTo(_recipient, _amount);
    }

    function deductFrom(address _payer, uint _amount) internal {
        return meh.operatorDeductFrom(_payer, _amount);
    }

    function exists(uint16 _blockId) internal view  returns (bool) {
        return meh.exists(_blockId);
    }

    function ownerOf(uint16 _blockId) internal view returns (address) {
        return meh.ownerOf(_blockId);
    }


    // https://github.com/seedom-io/seedom-solidity/blob/574e52349755ec9e28111c3a182638e73d4eb635/contract/fundraiser.sol#L482
    // recover() allows the owner to recover ERC20 tokens sent to this contract, for later
    // distribution back to their original holders, upon request
    // function recover(address _token) public onlyOwner {
    //     ERC20 _erc20 = ERC20(_token);
    //     uint256 _balance = _erc20.balanceOf(this);
    //     require(_erc20.transfer(deployment._owner, _balance));
    // }
}