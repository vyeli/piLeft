import "solmate/tokens/ERC20.sol";

contract ERC20Mock is ERC20 {

  constructor(address initialAccount, uint256 initialBalance,string memory _name,
        string memory _symbol,
        uint8 _decimals) ERC20(_name,_symbol,_decimals)public {
    _mint(initialAccount, initialBalance);
  }

  function mint(address account, uint256 amount) public {
    _mint(account, amount);
  }

  function burn(address account, uint256 amount) public {
    _burn(account, amount);
  }


}