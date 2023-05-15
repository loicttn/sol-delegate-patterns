pragma solidity ^0.8.13;

import "../../libs/Storage.sol";

contract DiamondFacetShared {
    modifier onlyOnce() {
        bytes32 init_slot = bytes32(
            uint256(keccak256("shared.initialized")) - 1
        );
        bool init = Storage.getBool(init_slot).v;
        require(!init, "already initialized");
        Storage.setBool(init_slot, true);
        _;
    }

    // this must be called only once
    function initialize() public onlyOnce {
        Storage.setUint256(
            bytes32(uint256(keccak256("shared.number")) - 1),
            42
        );
    }

    function number_shared() public view returns (uint256) {
        return
            Storage
                .getUint256(bytes32(uint256(keccak256("shared.number")) - 1))
                .v;
    }
}
