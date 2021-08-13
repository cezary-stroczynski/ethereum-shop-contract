pragma solidity ^0.8.1;


contract Identity {

  mapping (address => bytes32) private userNames;
  mapping (address => bool) private registeredUsers;
  mapping (bytes32 => bool) private registeredNames;

  function userName(address _user) public view returns(bytes32) {
    return userNames[_user];
  }

  function registrationStatus(address _user) public view returns(bool) {
    return registeredUsers[_user];
  }

  function nameAvailability(bytes32 _name) public view returns(bool) {
    return !registeredNames[_name];
  }



  function _registerUser(address _user, bytes32 _userName)
    internal
    returns (bool)
  {
    if (!registeredUsers[_user]) {
      require(registeredNames[_userName] == false);
      userNames[_user] = _userName;
      registeredUsers[_user] = true;
      registeredNames[_userName] = true;
      return true;
    } else {
      return true;
    }
  }
}
