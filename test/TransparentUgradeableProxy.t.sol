// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/TargetedImplem.sol";
import "../src/patterns/TransparentUpgradeableProxy.sol";

// TUP interface is basically the admin view of the proxy
//
// We must use an interface to explicit TUP admin functions, not available
// through lookup because of the fallback mechanism
interface TUP {
    function changeAdmin(address newAdmin) external;

    function upgradeTo(address newImplementation) external;

    function getImplem() external view returns (address);

    function getAdmin() external view returns (address);
}

contract TUPTest is Test {
    bytes32 constant VALUE_SLOT = bytes32(uint256(keccak256("number")) - 1);

    event EIP1967Upgraded(address indexed implementation);
    event EIP1967AdminChanged(address previousAdmin, address newAdmin);

    function testInit() public {
        TargetedImplem target = new TargetedImplem();
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(target)
        );
        TargetedImplem wproxy = TargetedImplem(address(proxy));
        // admin cannot call the implem / initialize, so we use random user
        vm.prank(address(0x11111111));
        wproxy.initialize();

        // test initial state
        assertEq(proxy.getImplem(), address(target), "implementation address");
        assertEq(proxy.getAdmin(), address(this), "admin address");
        vm.prank(address(0x11111111));
        assertEq(wproxy.number(), 42, "initial number");
    }

    function testAdminCannotCallImplementation() public {
        TargetedImplem target = new TargetedImplem();
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(target)
        );
        TargetedImplem wproxy = TargetedImplem(address(proxy));
        // admin cannot call the implem / initialize
        vm.expectRevert(bytes("unknown admin function"));
        wproxy.initialize();
    }

    function testChangeImplementation() public {
        TargetedImplem target = new TargetedImplem();
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(target)
        );
        TargetedImplem wproxy = TargetedImplem(address(proxy));
        // admin cannot call the implem / initialize, so we use random user
        vm.prank(address(0x11111111));
        wproxy.initialize();

        TUP wadminProxy = TUP(address(proxy));

        TargetedImplem newTarget = new TargetedImplem();

        // test change implementation
        vm.expectEmit(true, true, true, true);
        emit EIP1967Upgraded(address(newTarget));
        wadminProxy.upgradeTo(address(newTarget));

        vm.prank(address(0x11111111));
        assertEq(proxy.getImplem(), address(newTarget), "new implementation");
        // test that admin fallbacks to view method as well
        assertEq(wadminProxy.getImplem(), address(newTarget), "new admin");
    }

    function testChangeAdmin() public {
        TargetedImplem target = new TargetedImplem();
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(target)
        );
        TargetedImplem wproxy = TargetedImplem(address(proxy));
        // admin cannot call the implem / initialize, so we use random user
        vm.prank(address(0x11111111));
        wproxy.initialize();

        TUP wadminProxy = TUP(address(proxy));

        // test change admin
        address newAdmin = address(0x123);
        vm.expectEmit(true, true, true, true);
        emit EIP1967AdminChanged(address(this), newAdmin);
        wadminProxy.changeAdmin(newAdmin);

        vm.prank(address(0x11111111));
        assertEq(proxy.getAdmin(), newAdmin, "new admin");
        // test that admin fallbacks to view method as well
        assertEq(wadminProxy.getAdmin(), newAdmin, "new admin");
    }

    function testIncrement() public {
        TargetedImplem target = new TargetedImplem();
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(target)
        );
        TargetedImplem wproxy = TargetedImplem(address(proxy));
        // admin cannot call the implem / initialize, so we use random user
        vm.prank(address(0x11111111));
        wproxy.initialize();

        vm.prank(address(0x11111111));
        uint256 initialNumber = wproxy.number();
        // test increment
        // admin cannot call the implem, so we use random user
        vm.prank(address(0x11111111));
        wproxy.increment();
        vm.prank(address(0x11111111));
        assertEq(wproxy.number(), initialNumber + 1, "incremented number");
    }
}
