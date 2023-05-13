pragma solidity ^0.8.13;

contract UpgradeableBeacon {
    address public implem;
    address private admin;

    modifier onlyAdmin() {
        require(msg.sender == admin, "not admin");
        _;
    }

    constructor(address _implementation) {
        implem = _implementation;
        admin = msg.sender;
    }

    function implementation() public view returns (address) {
        return implem;
    }

    function changeAdmin(address newAdmin) public onlyAdmin {
        admin = newAdmin;
    }

    function upgradeTo(address newImplementation) public onlyAdmin {
        implem = newImplementation;
    }
}
