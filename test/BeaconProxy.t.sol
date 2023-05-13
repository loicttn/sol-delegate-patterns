// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/TargetedImplem.sol";
import "../src/patterns/BeaconProxy.sol";

contract Beacon is IBeacon {
    address public implem;

    constructor(address _implementation) {
        implem = _implementation;
    }

    function implementation() public view override returns (address) {
        return implem;
    }
}

contract BPTest is Test {
    function testInit() public {
        TargetedImplem target = new TargetedImplem();
        Beacon beacon = new Beacon(address(target));
        BeaconProxy proxy = new BeaconProxy(address(beacon));
        TargetedImplem wproxy = TargetedImplem(address(proxy));
        wproxy.initialize();

        // test initial state
        assertEq(proxy.getBeacon(), address(beacon), "beacon address");
        assertEq(proxy.getImplementation(), address(target), "implementation");
        assertEq(wproxy.number(), 42, "initial number");
    }

    function testIncrement() public {
        TargetedImplem target = new TargetedImplem();
        Beacon beacon = new Beacon(address(target));
        BeaconProxy proxy = new BeaconProxy(address(beacon));
        TargetedImplem wproxy = TargetedImplem(address(proxy));
        wproxy.initialize();

        uint256 initialNumber = wproxy.number();
        // test increment
        wproxy.increment();
        assertEq(wproxy.number(), initialNumber + 1, "incremented number");
    }
}
