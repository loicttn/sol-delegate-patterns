pragma solidity ^0.8.13;

import "../libs/Storage.sol";

interface IBeacon {
    function implementation() external view returns (address);
}

/** THIS IS A STUPID, INCOMPLETE AND MOST PROBABLY UNSAFE IMPLEM OF UBP, DO NOT USE.

    A BeaconProxy with an admin that can change the beacon address at anytime.

                +-----------------+             +--------------------+
                | Beacon Proxy 1  |             | Beacon             |
                |                 |             |                    |
    1. calls    |                 |  2. fetch   | |implementation|   |
   -------->    |                 | ----------> | |   address    |   |
                |  +-----------+  |   implem    +--------------------+
                |  |  Storage  |  |   address
                |  |           |  |
                |  |    ...    |  |
                |  |   admin   |  |
                |  |    ...    |  |
                |  |   beacon  |  |
                |  |           |  |
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
contract UpgradeableBeaconProxy {
    // eip1967 defines a standard for which slots to use for proxy config
    bytes32 private constant BEACON_SLOT =
        bytes32(uint256(keccak256("eip1967.proxy.beacon")) - 1);
    bytes32 private constant ADMIN_SLOT =
        bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1);

    event EIP1967BeaconUpgraded(address indexed beacon);
    event EIP1967AdminChanged(address previousAdmin, address newAdmin);

    modifier admin() {
        require(msg.sender == Storage.getAddress(ADMIN_SLOT).v, "not admin");
        _;
    }

    // should also take a `bytes memory _data` parameter
    // to call the initializer of the implementation contract
    // with an upgradeToAndCall function if _data is not empty
    constructor(address _beacon) {
        Storage.setAddress(BEACON_SLOT, _beacon);
        Storage.setAddress(ADMIN_SLOT, msg.sender);
    }

    // should also take a `bytes memory _data` parameter
    // to call the initializer of the implementation contract
    // with an upgradeToAndCall function if _data is not empty
    function setBeacon(address _newBeacon) external admin {
        // For safety, we require that the new beacon is a contract
        uint256 size;
        assembly {
            size := extcodesize(_newBeacon)
        }
        require(size > 0, "not a contract");
        Storage.setAddress(BEACON_SLOT, _newBeacon);
        emit EIP1967BeaconUpgraded(_newBeacon);
    }

    function changeAdmin(address _newAdmin) external admin {
        address _previousAdmin = Storage.getAddress(ADMIN_SLOT).v;
        Storage.setAddress(ADMIN_SLOT, _newAdmin);
        emit EIP1967AdminChanged(_previousAdmin, _newAdmin);
    }

    function getImplementation() external view returns (address) {
        return _implementation();
    }

    function getBeacon() external view returns (address) {
        return address(_getBeacon());
    }

    function getAdmin() external view returns (address) {
        return Storage.getAddress(ADMIN_SLOT).v;
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
