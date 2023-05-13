// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./libs/Storage.sol";

contract TargetedImplem {
    function initialize() public {
        Storage.setUint256(bytes32(uint256(keccak256("number")) - 1), 42);
    }

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
