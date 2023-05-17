pragma solidity ^0.8.13;

import "../../libs/Storage.sol";

contract DiamondFacet1 {
    modifier onlyOnce() {
        bytes32 init_slot = bytes32(
            uint256(keccak256("facet1.initialized")) - 1
        );
        bool init = Storage.getBool(init_slot).v;
        require(!init, "already initialized");
        Storage.setBool(init_slot, true);
        _;
    }

    // this must be called only once
    function initialize_1() public onlyOnce {
        Storage.setUint256(
            bytes32(uint256(keccak256("facet1.number")) - 1),
            42
        );
    }

    // incrments a uint256 stored in a shared facet storage
    function increment_shared() public {
        Storage.Uint256 storage nb = Storage.getUint256(
            bytes32(uint256(keccak256("shared.number")) - 1)
        );
        nb.v++;
    }

    // increments a uint256 stored in a dedicated facet storage
    function increment() public {
        Storage.Uint256 storage nb = Storage.getUint256(
            bytes32(uint256(keccak256("facet1.number")) - 1)
        );
        nb.v++;
    }

    function number_1() public view returns (uint256) {
        return
            Storage
                .getUint256(bytes32(uint256(keccak256("facet1.number")) - 1))
                .v;
    }
}
