pragma solidity ^0.8.13;

import "../../libs/Storage.sol";

// Taken from EIP-2535: https://eips.ethereum.org/EIPS/eip-2535 spec
// Every diamond should implement this interface
interface IDiamond {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

/** THIS IS A STUPID, INCOMPLETE AND MOST PROBABLY UNSAFE IMPLEM OF D, DO NOT USE.

    A Diamond (D) is a proxy that forwards all calls to the implementation contracts
    called facets.

    As Diamond is a proxy, it can follow the Proxy, Upgradable Proxy, or Transparent Upgradeable Proxy 
    patterns. For simplicity here we will use the Upgradable Proxy pattern.

                +-----------------+             +-----------------+
                | Diamond         |             | Facet 1         |
                |                 |             |  +-----------+  |
      calls     |                 |  delegate   |  |  Logic    |  |
   -------->    |                 | ----------> |  +-----------+  |
                |  +-----------+  |   calls     +-----------------+
                |  |  Storage1 |  |
                |  +-----------+  |             +-----------------+
                |                 |             | Facet Shared    |
                |  +-----------+  |  delegate   |  +-----------+  |
                |  | Shared 1&2|  | ----------> |  |  Logic    |  |
                |  +-----------+  |   calls     |  +-----------+  |
                |                 |             +-----------------+
                |  +-----------+  |
                |  |  Storage3 |  |   delegate  +-----------------+
                |  +-----------+  | ----------> | Facet 2         |
                +-----------------+    calls    |  +-----------+  |
                                                |  |  Logic    |  |
                                                |  +-----------+  |
                                                +-----------------+
 */
contract DiamondUpgradeableProxy is IDiamond {
    // this is used to store the method selectors of the functions we want to
    // delegatecall to the facets implementation contracts
    mapping(bytes4 => address) public selectorTofacet;

    bytes32 private constant ADMIN_SLOT =
        bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1);

    modifier onlyAdmin() {
        require(msg.sender == _getAdmin(), "not admin");
        _;
    }

    constructor() {
        Storage.setAddress(ADMIN_SLOT, msg.sender);
    }

    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external onlyAdmin {
        for (uint256 cutIndex; cutIndex < _diamondCut.length; cutIndex++) {
            if (_diamondCut[cutIndex].action == FacetCutAction.Add) {
                _addDiamondCut(_diamondCut[cutIndex]);
            } else if (_diamondCut[cutIndex].action == FacetCutAction.Replace) {
                _replaceDiamondCut(_diamondCut[cutIndex]);
            } else if (_diamondCut[cutIndex].action == FacetCutAction.Remove) {
                _removeDiamondCut(_diamondCut[cutIndex]);
            } else {
                revert("unknown FacetCutAction");
            }
            // delegate call to init the diamond cut with _calldata as argument
            // this will allow to init the Facet after its selectors have been
            // processed
            _init.delegatecall(_calldata);
        }
    }

    fallback() external payable {
        _fallback();
    }

    receive() external payable {
        _fallback();
    }

    function _addDiamondCut(FacetCut calldata _cut) internal {
        for (uint256 i; i < _cut.functionSelectors.length; i++) {
            selectorTofacet[_cut.functionSelectors[i]] = _cut.facetAddress;
        }
    }

    function _removeDiamondCut(FacetCut calldata _cut) internal {
        for (uint256 i; i < _cut.functionSelectors.length; i++) {
            delete selectorTofacet[_cut.functionSelectors[i]];
        }
    }

    function _replaceDiamondCut(FacetCut calldata _cut) internal {
        for (uint256 i; i < _cut.functionSelectors.length; i++) {
            selectorTofacet[_cut.functionSelectors[i]] = _cut.facetAddress;
        }
    }

    function _getAdmin() internal view returns (address) {
        return Storage.getAddress(ADMIN_SLOT).v;
    }

    // Taken from EIP-2535 spec
    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    function _fallback() internal {
        // get facet from function selector
        address facet = selectorTofacet[msg.sig];
        require(facet != address(0), "Diamond: Function does not exist");
        // Execute external function from facet using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}
