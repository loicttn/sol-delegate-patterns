// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/** THIS IS A STUPID, INCOMPLETE AND MOST PROBABLY UNSAFE IMPLEM, DO NOT USE.

    Evm slots are 256 bits long and are used to store contract variables.

    A practice often used with delegatecall patterns, is to used unstructured storage
    to store variables. This is done by using the keccak256 hash of the variable name
    as the slot key. This prevents storage collisions between different contracts.

    Some standards are defined like EIP1967 to define some standard slots to store
    proxy configs for example.
    
    This library provides a way to store and retrieve values in evm slots.

    Example of a delegate call storage being modified by an implem.

    +-----------------+ .           +-----------------+
    | Proxy           |             | TargetedImplem  |
    |                 |             |                 |
    |                 |  delegate   |                 |
    |  Slot 1         | ----------> |                 |
    |  +-----------+  |   calls     |                 |
    |  |  Address  |  |             |     Logic       |
    |  +-----------+  |             |  write aa to s1 |
    | Slot 2          |             |  write 42 to s4 |
    |  +-----------+  |             |  s4 += 1        |
    |  |  Uint256  |  |             |  ...            |
    |  +-----------+  |             |                 |
    |                 |             |                 |
    | ...             |             |                 |
    |                 |             |                 |
    | Slot 43         |             |                 |
    |  +-----------+  |             |                 |
    |  |  Uint256  |  |             |                 |
    |  +-----------+  |             |                 |
    | Slot 44         |             |                 |
    |  +-----------+  |             |                 |
    |  |  Uint256  |  |             |                 |
    |  +-----------+  |             |                 |
    |                 |             |                 |
    +-----------------+ .           +-----------------+

*/
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
