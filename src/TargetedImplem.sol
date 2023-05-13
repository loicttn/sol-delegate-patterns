pragma solidity ^0.8.13;

import "./libs/Storage.sol";

contract TargetedImplem {
    modifier onlyOnce() {
        bytes32 init_slot = bytes32(uint256(keccak256("initialized")) - 1);
        bool init = Storage.getBool(init_slot).v;
        require(!init, "already initialized");
        Storage.setBool(init_slot, true);
        _;
    }

    // this must be called only once
    function initialize() public onlyOnce {
        Storage.setUint256(bytes32(uint256(keccak256("number")) - 1), 42);
    }

    // increments a uint256 stored in a specific storage slot
    function increment() public {
        Storage.Uint256 storage nb = Storage.getUint256(
            bytes32(uint256(keccak256("number")) - 1)
        );
        nb.v++;
    }

    function number() public view returns (uint256) {
        return Storage.getUint256(bytes32(uint256(keccak256("number")) - 1)).v;
    }
}
