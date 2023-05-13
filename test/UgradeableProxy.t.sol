// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/TargetedImplem.sol";
import "../src/patterns/UpgradeableProxy.sol";

contract UPTest is Test {
    bytes32 constant VALUE_SLOT = bytes32(uint256(keccak256("number")) - 1);

    event EIP1967Upgraded(address indexed implementation);
    event EIP1967AdminChanged(address previousAdmin, address newAdmin);

    function testInit() public {
        TargetedImplem target = new TargetedImplem();
        UpgradeableProxy proxy = new UpgradeableProxy(address(target));
        TargetedImplem wproxy = TargetedImplem(address(proxy));
        wproxy.initialize();

        // test initial state
        assertEq(proxy.getImplem(), address(target), "implementation address");
        assertEq(proxy.getAdmin(), address(this), "admin address");
        assertEq(wproxy.number(), 42, "initial number");
    }

    function testIncrement() public {
        TargetedImplem target = new TargetedImplem();
        UpgradeableProxy proxy = new UpgradeableProxy(address(target));
        TargetedImplem wproxy = TargetedImplem(address(proxy));
        wproxy.initialize();

        uint256 initialNumber = wproxy.number();
        // test increment
        wproxy.increment();
        assertEq(wproxy.number(), initialNumber + 1, "incremented number");
    }

    function testChangeImplementation() public {
        TargetedImplem target = new TargetedImplem();
        UpgradeableProxy proxy = new UpgradeableProxy(address(target));
        TargetedImplem wproxy = TargetedImplem(address(proxy));
        wproxy.initialize();
        wproxy.increment();

        TargetedImplem newTarget = new TargetedImplem();

        // test change implementation
        vm.expectEmit(true, true, true, true);
        emit EIP1967Upgraded(address(newTarget));
        proxy.upgradeTo(address(newTarget));
        // do not initialize to not override storage slots

        assertEq(proxy.getImplem(), address(newTarget), "new implementation");
        assertEq(wproxy.number(), 43, "number is still there");
    }

    function testChangeAdmin() public {
        TargetedImplem target = new TargetedImplem();
        UpgradeableProxy proxy = new UpgradeableProxy(address(target));
        TargetedImplem wproxy = TargetedImplem(address(proxy));
        wproxy.initialize();

        // test change admin
        address newAdmin = address(0x123);
        vm.expectEmit(true, true, true, true);
        emit EIP1967AdminChanged(address(this), newAdmin);
        proxy.changeAdmin(newAdmin);

        assertEq(proxy.getAdmin(), newAdmin, "new admin");
    }
}
