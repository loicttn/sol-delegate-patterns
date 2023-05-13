// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library Storage {
    ////////////////////////
    // ADDRESS
    ////////////////////////

    struct Address {
        address v;
    }

    function getAddress(
        bytes32 slot
    ) internal pure returns (Address storage pointer) {
        assembly {
            pointer.slot := slot
        }
    }

    function setAddress(bytes32 slot, address value) internal {
        assembly {
            sstore(slot, value)
        }
    }

    ////////////////////////
    // UINT256
    ////////////////////////

    struct Uint256 {
        uint256 v;
    }

    function getUint256(
        bytes32 slot
    ) internal pure returns (Uint256 storage pointer) {
        assembly {
            pointer.slot := slot
        }
    }

    function setUint256(bytes32 slot, uint256 value) internal {
        assembly {
            sstore(slot, value)
        }
    }
}
