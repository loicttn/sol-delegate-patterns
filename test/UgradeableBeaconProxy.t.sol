// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/TargetedImplem.sol";
import "../src/patterns/UpgradeableBeaconProxy.sol";
import "../src/Beacon.sol";

contract UBPTest is Test {
    event EIP1967BeaconUpgraded(address indexed beacon);
    event EIP1967AdminChanged(address previousAdmin, address newAdmin);

    function testInit() public {
        TargetedImplem target = new TargetedImplem();
        Beacon beacon = new Beacon(address(target));
        UpgradeableBeaconProxy proxy = new UpgradeableBeaconProxy(
            address(beacon)
        );
        TargetedImplem wproxy = TargetedImplem(address(proxy));
        wproxy.initialize();

        // test initial state
        assertEq(proxy.getBeacon(), address(beacon), "beacon address");
        assertEq(proxy.getAdmin(), address(this), "admin address");
        assertEq(proxy.getImplementation(), address(target), "implementation");
        assertEq(wproxy.number(), 42, "initial number");
    }

    function testIncrement() public {
        TargetedImplem target = new TargetedImplem();
        Beacon beacon = new Beacon(address(target));
        UpgradeableBeaconProxy proxy = new UpgradeableBeaconProxy(
            address(beacon)
        );
        TargetedImplem wproxy = TargetedImplem(address(proxy));
        wproxy.initialize();

        uint256 initialNumber = wproxy.number();
        // test increment
        wproxy.increment();
        assertEq(wproxy.number(), initialNumber + 1, "incremented number");
    }

    function testSetBeacon() public {
        TargetedImplem target = new TargetedImplem();
        Beacon beacon = new Beacon(address(target));
        UpgradeableBeaconProxy proxy = new UpgradeableBeaconProxy(
            address(beacon)
        );
        TargetedImplem wproxy = TargetedImplem(address(proxy));
        wproxy.initialize();
        wproxy.increment();

        TargetedImplem newTarget = new TargetedImplem();
        Beacon newBeacon = new Beacon(address(newTarget));

        // test change implementation
        vm.expectEmit(true, true, true, true);
        emit EIP1967BeaconUpgraded(address(newBeacon));
        proxy.setBeacon(address(newBeacon));
        // do not initialize to not override storage slots

        assertEq(proxy.getBeacon(), address(newBeacon), "new beacon");
        assertEq(
            proxy.getImplementation(),
            address(newTarget),
            "new implementation"
        );
        assertEq(wproxy.number(), 43, "number is still there");
    }

    function testChangeAdmin() public {
        TargetedImplem target = new TargetedImplem();
        Beacon beacon = new Beacon(address(target));
        UpgradeableBeaconProxy proxy = new UpgradeableBeaconProxy(
            address(beacon)
        );
        TargetedImplem wproxy = TargetedImplem(address(proxy));
        wproxy.initialize();
        wproxy.increment();

        // test change admin
        vm.expectEmit(true, true, true, true);
        emit EIP1967AdminChanged(address(this), address(0xdead));
        proxy.changeAdmin(address(0xdead));

        assertEq(proxy.getAdmin(), address(0xdead), "new admin");
        assertEq(wproxy.number(), 43, "number is still there");
    }
}
