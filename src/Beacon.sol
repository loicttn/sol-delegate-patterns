pragma solidity ^0.8.13;

contract Beacon {
    address public implem;

    constructor(address _implementation) {
        implem = _implementation;
    }

    function implementation() public view returns (address) {
        return implem;
    }
}
