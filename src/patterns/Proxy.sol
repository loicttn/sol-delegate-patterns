pragma solidity ^0.8.13;

import "../libs/Storage.sol";

/** THIS IS A STUPID, INCOMPLETE AND MOST PROBABLY UNSAFE IMPLEM OF P, DO NOT USE.

    Proxy (P) pattern is used to proxy calls to an implementation contract.
    This is the simplest proxy pattern, it does not have any admin utilities
    to change the implementation contract or the admin address.

    The implementation contract is stored in the proxy's storage. The proxy's
    storage org is defined by EIP1967.


                +-----------------+ .           +-----------------+
                |                 |             | TargetedImplem  |
                |                 |             |                 |
      calls     | Proxy           |  delegate   |                 |
   -------->    |                 | ----------> |                 |
                |  +-----------+  |   calls     |  +-----------+  |
                |  |  Storage  |  |             |  |  Logic    |  |
                |  +-----------+  |             |  +-----------+  |
                +-----------------+ .           +-----------------+
 */
contract Proxy {
    // eip1967 defines a standard for which slots to use for proxy config
    bytes32 private constant IMPLEM_SLOT =
        bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);

    constructor(address _implementation) {
        Storage.setAddress(IMPLEM_SLOT, _implementation);
    }

    function getImplem() external view returns (address) {
        return Storage.getAddress(IMPLEM_SLOT).v;
    }

    fallback() external payable {
        _fallback();
    }

    receive() external payable {
        _fallback();
    }

    function _fallback() internal {
        address _impl = Storage.getAddress(IMPLEM_SLOT).v;
        // Fallback to implementation
        // copied from EIP1967
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), _impl, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}
