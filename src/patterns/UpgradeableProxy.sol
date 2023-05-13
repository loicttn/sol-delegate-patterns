pragma solidity ^0.8.13;

import "../libs/Storage.sol";

/** THIS IS A STUPID, INCOMPLETE AND MOST PROBABLY UNSAFE IMPLEM OF UP, DO NOT USE.


    Upgradeable Proxy (UP) pattern is used to proxy calls to an
    implementation contract. The implementation contract is stored in the 
    proxy's storage. The proxy's storage org is defined by EIP1967.

    UP introduces some admin utilities to change the implementation contract
    and the admin address.


                +-----------------+ .           +-----------------+
                |                 |             | TargetedImplem  |
                | Upgradeable     |             |                 |
      calls     | Proxy           |  delegate   |                 |
   -------->    |                 | ----------> |                 |
                |  +-----------+  |   calls     |  +-----------+  |
                |  |  Storage  |  |     to      |  |  Logic    |  |
                |  |           |  |   implem    |  |           |  |
                |  |  implem   |  |             |  +-----------+  |
                |  |  ...      |  |             +-----------------+
                |  |  admin    |  |
                |  |  ...      |  |
                |  +-----------+  |  
                +-----------------+            
 */
contract UpgradeableProxy {
    // eip1967 defines a standard for which slots to use for proxy config
    bytes32 private constant IMPLEM_SLOT =
        bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);
    bytes32 private constant ADMIN_SLOT =
        bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1);

    event EIP1967Upgraded(address indexed implementation);
    event EIP1967AdminChanged(address previousAdmin, address newAdmin);

    modifier admin() {
        require(msg.sender == Storage.getAddress(ADMIN_SLOT).v, "not admin");
        _;
    }

    constructor(address _implementation) {
        Storage.setAddress(IMPLEM_SLOT, _implementation);
        Storage.setAddress(ADMIN_SLOT, msg.sender);
    }

    function upgradeTo(address _implementation) external admin {
        // For safety, we require that the new implementation is a contract
        uint256 size;
        assembly {
            size := extcodesize(_implementation)
        }
        require(size > 0, "not a contract");
        Storage.setAddress(IMPLEM_SLOT, _implementation);
        emit EIP1967Upgraded(_implementation);
    }

    function changeAdmin(address _newAdmin) external admin {
        address _previousAdmin = Storage.getAddress(ADMIN_SLOT).v;
        Storage.setAddress(ADMIN_SLOT, _newAdmin);
        emit EIP1967AdminChanged(_previousAdmin, _newAdmin);
    }

    function getImplem() external view returns (address) {
        return Storage.getAddress(IMPLEM_SLOT).v;
    }

    function getAdmin() external view returns (address) {
        return Storage.getAddress(ADMIN_SLOT).v;
    }

    function _fallback() internal {
        address _impl = Storage.getAddress(IMPLEM_SLOT).v;
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

    fallback() external payable {
        _fallback();
    }

    receive() external payable {
        _fallback();
    }
}
