// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/TargetedImplem.sol";
import "../src/patterns/Proxy.sol";

contract PTest is Test {
    bytes32 constant VALUE_SLOT = bytes32(uint256(keccak256("number")) - 1);

    function testInit() public {
        TargetedImplem target = new TargetedImplem();
        Proxy proxy = new Proxy(address(target));
        TargetedImplem wproxy = TargetedImplem(address(proxy));
        wproxy.initialize();

        // test initial state
        assertEq(proxy.getImplem(), address(target), "implementation address");
        assertEq(wproxy.number(), 42, "initial number");
    }

    function testIncrement() public {
        TargetedImplem target = new TargetedImplem();
        Proxy proxy = new Proxy(address(target));
        TargetedImplem wproxy = TargetedImplem(address(proxy));
        wproxy.initialize();

        uint256 initialNumber = wproxy.number();
        // test increment
        wproxy.increment();
        assertEq(wproxy.number(), initialNumber + 1, "incremented number");
    }
}
