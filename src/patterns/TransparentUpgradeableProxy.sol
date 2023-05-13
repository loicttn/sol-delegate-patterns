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
                |  |  implem   |  |     if      |  +-----------+  |
                |  |  ...      |  |  not admin  +-----------------+
                |  |  admin    |  |
                |  |  ...      |  |
                |  +-----------+  |  
                +-----------------+            
 */
contract TransparentUpgradeableProxy {
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

    function getImplem() public view returns (address) {
        return Storage.getAddress(IMPLEM_SLOT).v;
    }

    function getAdmin() public view returns (address) {
        return Storage.getAddress(ADMIN_SLOT).v;
    }

    fallback() external payable {
        _fallback();
    }

    receive() external payable {
        _fallback();
    }

    function _fallback() private {
        address impl = Storage.getAddress(IMPLEM_SLOT).v;
        address adm = Storage.getAddress(ADMIN_SLOT).v;

        // If the admin is calling, we redirect to the proxy admin functions
        // or we revert if the function is not implemented
        if (msg.sender == adm) {
            bytes memory ret = "";

            if (msg.sig == bytes4(keccak256("upgradeTo(address)"))) {
                // parse parameter from tx data
                address newImplementation = abi.decode(msg.data[4:], (address));
                _upgradeTo(newImplementation);
            } else if (msg.sig == bytes4(keccak256("changeAdmin(address)"))) {
                // parse parameter from tx data
                address newAdmin = abi.decode(msg.data[4:], (address));
                _changeAdmin(newAdmin);
            } else if (msg.sig == bytes4(keccak256("getImplem()"))) {
                ret = abi.encode(getImplem());
            } else if (msg.sig == bytes4(keccak256("getAdmin()"))) {
                ret = abi.encode(getAdmin());
            } else {
                // admin cannot call implem contract
                revert("unknown admin function");
            }
            assembly {
                return(add(ret, 0x20), mload(ret))
            }
        }
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)

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

    function _upgradeTo(address _implementation) internal {
        // For safety, we require that the new implementation is a contract
        uint256 size;
        assembly {
            size := extcodesize(_implementation)
        }
        require(size > 0, "not a contract");
        Storage.setAddress(IMPLEM_SLOT, _implementation);
        emit EIP1967Upgraded(_implementation);
    }

    function _changeAdmin(address _newAdmin) internal {
        address _previousAdmin = Storage.getAddress(ADMIN_SLOT).v;
        Storage.setAddress(ADMIN_SLOT, _newAdmin);
        emit EIP1967AdminChanged(_previousAdmin, _newAdmin);
    }
}
