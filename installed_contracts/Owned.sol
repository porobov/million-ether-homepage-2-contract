contract Owned {
  address public owner;

  //@dev The Owned constructor sets the original `owner` of the contract to the sender
  //account.
  function Owned() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}