pragma solidity ^0.8.1;

import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol';
import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/Pausable.sol';

contract NFT is Ownable, Pausable {

  function setRandomProvider(address _contract) onlyOwner public {
    _randomProvider = _contract;
  }

  address private _randomProvider;
  uint256 private _totalSold;
  uint16 private _serieCounter;
  mapping (address => Tshirt[]) tshirts;
  mapping (address => uint) tshirtCounters;
  mapping (uint16 => Serie) series;
  mapping (string => uint8) elementsDict;
  mapping (string => uint8) actionsDict;

  struct Serie {
    bool active;
    string serieName;
    uint256 sold;
    uint256 price;
    uint8 layers;
    uint256 tokenReward;
    string[] elements;
    string[] actions;
    mapping (uint32 => address) owners;
  }

  struct Tshirt {
    uint32 code;
    uint16 serie;
    // NFT params:
      uint8 power;
      uint8 speed;
      uint8 brains;
      string ability;
  }


  event TshirtTransfer(uint16 serie, uint32 code, address to);
  event SerieLaunch(uint256 serieId);



  // view functions
  function ownerOf(uint16 _serie, uint32 _code) public view returns (address) {
    return series[_serie].owners[_code];
  }

  function serie(uint16 _serie)
    public
    view
    returns (string memory, uint256, uint256, uint8, uint256, uint256, uint256)
  {
    return(
      series[_serie].serieName,
      series[_serie].sold,
      series[_serie].price,
      series[_serie].layers,
      series[_serie].tokenReward,
      series[_serie].elements.length,
      series[_serie].actions.length
    );
  }

  function tokenReward(uint16 _serie) public view returns(uint256) {
    return series[_serie].tokenReward;
  }

  function serieElements(uint16 _serie, uint256 i)
    public
    view
    returns(string memory)
  {
    return series[_serie].elements[i];
  }

  function serieActions(uint16 _serie, uint256 i)
    public
    view
    returns(string memory)
  {
    return series[_serie].actions[i];
  }
  function elementValue(string memory _element) public view returns(uint8) {
    return elementsDict[_element];
  }
  function actionValue(string memory _action) public view returns(uint8) {
    return actionsDict[_action];
  }
  function serieCounter() public view returns (uint16) {
    return _serieCounter;
  }

  function serieStatus(uint16 _serie) public view returns (bool) {
    return series[_serie].active;
  }

  function ownedTshirts(address _owner) public view returns (uint256) {
    return tshirtCounters[_owner];
  }

  function tshirtOfOwnerByIndex(address _owner, uint256 _index)
    public
    view
    returns(uint32, uint16, uint8, uint8, uint8, string memory)
  {
    return(
      tshirts[_owner][_index].code,
      tshirts[_owner][_index].serie,
      tshirts[_owner][_index].power,
      tshirts[_owner][_index].speed,
      tshirts[_owner][_index].brains,
      tshirts[_owner][_index].ability
    );
  }

  // internal functions
  function _random() internal view returns(uint256) {
    bool success;
    bytes memory data;
    (success, data) = _randomProvider.staticcall(abi.encodeWithSignature("_rand()"));
    if (success == true) {
      return _bytesToUint(data);
    } else {
      return 0;
    }
  }

  function _bytesToUint(bytes memory bs) internal pure returns (uint256) {
    uint256 x;
    assembly {
      x := mload(add(bs, add(0x20, 0)))
    }
    return x;
  }

  function _range(uint256 _number, uint8 _r) internal pure returns (uint8) {
    uint8 n = uint8((_number - ((_number / _r) * _r)));
    return n;
  }

  function _power(uint256 seed) internal pure returns (uint8) {
    return _range(seed, 10)+1;
  }

  function _speed(uint256 seed) internal view returns (uint8) {
    uint256 rand = (seed+seed)/block.timestamp;
    return _range(rand, 10)+1;
  }

  function _brains(uint256 seed) internal view returns (uint8) {
    uint256 rand = (seed/block.timestamp)+seed;
    return _range(rand, 10)+1;
  }

  function _ability(uint256 seed, uint16 _serie)
    internal
    view
    returns (string memory)
  {
    uint256 rand = seed+block.timestamp;
    uint256 rand2 = (seed*2)/(seed-block.timestamp)+seed;
    uint8 noOfElements = uint8(series[_serie].elements.length);
    uint8 noOfActions = uint8(series[_serie].actions.length);
    string memory element = series[_serie].elements[_range(rand, noOfElements)];
    string memory ability = series[_serie].actions[_range(rand2, noOfActions)];
    return string(abi.encodePacked(element, ' ', ability));
  }

  function _calculateParams(uint16 _serie)
    internal
    view
    returns (uint8, uint8, uint8, string memory)
  {
    uint256 seed = _random();

    return(
      _power(seed),
      _speed(seed),
      _brains(seed),
      _ability(seed, _serie)
    );
  }



  // NFT ACTIONS
  function newSerie(
    string memory _serieName,
    uint256 _price,
    uint8 _layers,
    uint256 _tokenReward,
    string[] memory _elements,
    string[] memory _actions
  )
    onlyOwner
    public
    returns (bool)
  {
    require(_price * _layers != 0);
    series[_serieCounter].serieName = _serieName;
    series[_serieCounter].sold = 0;
    series[_serieCounter].price = _price;
    series[_serieCounter].layers = _layers;
    series[_serieCounter].tokenReward = _tokenReward;
    series[_serieCounter].elements = _elements;
    series[_serieCounter].actions = _actions;
    series[_serieCounter].active = true;
    emit SerieLaunch(_serieCounter);
    _serieCounter++;
    return true;
  }
  function addToElementsDict(string memory _element, uint8 _value)
    onlyOwner
    public
    returns (bool)
  {
    require(elementsDict[_element] == 0 && _value > 0);
    elementsDict[_element] = _value;
    return true;
  }
  function addToActionsDict(string memory _action, uint8 _value)
    onlyOwner
    public
    returns (bool)
  {
    require(actionsDict[_action] == 0 && _value > 0);
    actionsDict[_action] = _value;
    return true;
  }

  function tshirtTransfer(
    uint16 _tshirtIndex,
    uint16 _serie,
    uint32 _code,
    address _to
  )
    whenNotPaused
    public
    returns (bool)
  {
    require(
      series[_serie].owners[_code] == _msgSender()
      && tshirts[_msgSender()][_tshirtIndex].code == _code
      && tshirts[_msgSender()][_tshirtIndex].serie == _serie
    );
    series[_serie].owners[_code] = _to;
    tshirts[_to].push(tshirts[_msgSender()][_tshirtIndex]);
    tshirtCounters[_to]++;
    tshirtCounters[_msgSender()]--;
    delete tshirts[_msgSender()][_tshirtIndex];
    emit TshirtTransfer(_serie, _code, _to);
    return true;
  }

  function serieSwitch(uint16 _serie, bool _state)
    onlyOwner
    public
    returns (bool)
  {
    require(_state != series[_serie].active);
    series[_serie].active = _state;
    return true;
  }


  function _createTshirt(address _buyer, uint16 _serie, uint32 _code)
    internal
    returns (bool)
  {
    require(
      series[_serie].active == true
      &&_code < 10**uint256(series[_serie].layers)
      && _code >= 0
      && series[_serie].owners[_code] == address(0)
    );

    uint8 _p; // power
    uint8 _s; // speed
    uint8 _b; // brains
    string memory _a; // ability
    (_p, _s, _b, _a) = _calculateParams(_serie);
    Tshirt memory tshirt = Tshirt(_code, _serie, _p, _s, _b, _a);
    tshirts[_buyer].push(tshirt);
    series[_serie].owners[_code] = _buyer;
    tshirtCounters[_buyer]++;
    _totalSold++;
    series[_serie].sold++;
    return true;
  }

}
