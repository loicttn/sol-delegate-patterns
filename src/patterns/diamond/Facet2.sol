pragma solidity ^0.8.13;

import "../../libs/Storage.sol";

contract DiamondFacet2 {
    modifier onlyOnce() {
        bytes32 init_slot = bytes32(
            uint256(keccak256("facet2.initialized")) - 1
        );
        bool init = Storage.getBool(init_slot).v;
        require(!init, "already initialized");
        Storage.setBool(init_slot, true);
        _;
    }

    // this must be called only once
    function initialize() public onlyOnce {
        Storage.setUint256(
            bytes32(uint256(keccak256("facet2.number")) - 1),
            42
        );
    }

    // decrements a uint256 stored in a shared facet storage
    function decrement_shared() public {
        Storage.Uint256 storage nb = Storage.getUint256(
            bytes32(uint256(keccak256("shared.number")) - 1)
        );
        nb.v--;
    }

    // decrements a uint256 stored in a dedicated facet storage
    function decrement() public {
        Storage.Uint256 storage nb = Storage.getUint256(
            bytes32(uint256(keccak256("facet2.number")) - 1)
        );
        nb.v--;
    }

    function number_2() public view returns (uint256) {
        return
            Storage
                .getUint256(bytes32(uint256(keccak256("facet2.number")) - 1))
                .v;
    }
}
