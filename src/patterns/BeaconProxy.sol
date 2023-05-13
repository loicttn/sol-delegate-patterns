pragma solidity ^0.8.13;

import "../libs/Storage.sol";

interface IBeacon {
    function implementation() external view returns (address);
}

/** THIS IS A STUPID, INCOMPLETE AND MOST PROBABLY UNSAFE IMPLEM OF BP, DO NOT USE.

    BeaconProxy is a proxy that forwards all calls to the implementation contract
    defined by the beacon contract.

    The beacon contract is defined once in the proxy's storage at deployment time.

                +-----------------+             +--------------------+
                | Beacon Proxy 1  |             | Beacon             |
                |                 |             |                    |
    1. calls    |                 |  2. fetch   | |implementation|   |
   -------->    |                 | ----------> | |   address    |   |
                |  +-----------+  |   implem    +--------------------+
                |  |  Storage  |  |   address
                |  +-----------+  |
                |                 |             +------------------+
                |                 | 3. delegate | TargetedImplem 1 |
                |                 | ----------> |                  |
                |                 |    calls    |                  |
                |                 |             | +--------------+ |
                |                 |             | |  Logic       | |
                |                 |             | +--------------+ |
                |                 |             |                  |
                +-----------------+             +------------------+

 */
contract BeaconProxy {
    // eip1967 defines a standard for which slots to use for proxy config
    bytes32 private constant BEACON_SLOT =
        bytes32(uint256(keccak256("eip1967.proxy.beacon")) - 1);

    // should also take a `bytes memory _data` parameter
    // to call the initializer of the implementation contract
    // with an upgradeToAndCall function if _data is not empty
    constructor(address _beacon) {
        Storage.setAddress(BEACON_SLOT, _beacon);
    }

    function getImplementation() external view returns (address) {
        return _implementation();
    }

    function getBeacon() external view returns (address) {
        return address(_getBeacon());
    }

    fallback() external payable {
        _fallback();
    }

    receive() external payable {
        _fallback();
    }

    function _getBeacon() internal view returns (IBeacon) {
        return IBeacon(Storage.getAddress(BEACON_SLOT).v);
    }

    function _implementation() internal view returns (address) {
        return _getBeacon().implementation();
    }

    function _fallback() internal {
        address _impl = _implementation();
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
