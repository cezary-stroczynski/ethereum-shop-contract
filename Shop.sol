pragma solidity ^0.8.1;

import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol';
import './NFT.sol';
import './Identity.sol';



contract TshirtShop is ERC20, NFT, Identity {


  constructor() ERC20('crypto T-shirt coin', 'xCTSC') {
    addToElementsDict('antimatter', 9);
    addToElementsDict('quark', 7);
    addToElementsDict('proton', 7);
    addToElementsDict('neutron', 5);
    addToElementsDict('electron', 4);

    addToActionsDict('reactor', 100);
    addToActionsDict('attractor', 30);
    addToActionsDict('absorber', 10);
    addToActionsDict('accumulator', 5);

    _mint(_msgSender(), 1000000);
  }
  function decimals() public override pure returns(uint8) { return 0; }

  event Purchase(
    address indexed _buyer,
    uint16 _serie,
    uint32 _code,
    uint256 _value
  );

  mapping (address => bool) public coupons;

  function grantCoupon(address _receiver) public onlyOwner {
    coupons[_receiver] = true;
  }

  function denyCoupon(address _receiver) public onlyOwner {
    coupons[_receiver] = false;
  }

  function checkForCoupon(address _user) public view returns(bool) {
    return coupons[_user];
  }

  function buy(uint16 _serie, uint32 _code, bytes32 _userName)
    whenNotPaused
    public
    payable
    returns (bool)
  {
    require(msg.value == series[_serie].price);
    address payable _owner = payable(owner());
    _owner.transfer(msg.value);
    _createTshirt(_msgSender(), _serie, _code);
    _mint(_msgSender(), tokenReward(_serie));
    _registerUser(_msgSender(), _userName);
    emit Purchase(_msgSender(), _serie, _code, msg.value);
    return true;
  }

  function buyWithCoupon(uint16 _serie, uint32 _code, bytes32 _userName)
    whenNotPaused
    public
    returns (bool)
  {
    require(coupons[_msgSender()] == true);
    coupons[_msgSender()] = false;
    _createTshirt(_msgSender(), _serie, _code);
    _mint(_msgSender(), tokenReward(_serie));
    _registerUser(_msgSender(), _userName);
    emit Purchase(_msgSender(), _serie, _code, 0);
    return true;
  }

  function pauseControl(bool status) public onlyOwner {
    if (status == true) {
      _pause();
    } else {
      _unpause();
    }
  }
}
