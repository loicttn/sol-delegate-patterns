pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/patterns/diamond/DiamondUpgradeableProxy.sol";
import "../src/patterns/diamond/Facet1.sol";
import "../src/patterns/diamond/Facet2.sol";
import "../src/patterns/diamond/FacetShared.sol";

interface IWDiamond {
    function increment() external;

    function number_1() external view returns (uint256);

    function decrement() external;

    function number_2() external view returns (uint256);

    function number_shared() external view returns (uint256);

    function increment_shared() external;
}

contract UDTest is Test {
    function testAddFacet() public {
        DiamondUpgradeableProxy proxy = new DiamondUpgradeableProxy();
        DiamondFacet1 facet1 = new DiamondFacet1();
        DiamondFacet2 facet2 = new DiamondFacet2();
        DiamondFacetShared facetShared = new DiamondFacetShared();

        // create diamond cuts

        bytes4[] memory selectors1 = new bytes4[](4);
        selectors1[0] = bytes4(keccak256(bytes("initialize_1()")));
        selectors1[1] = bytes4(keccak256(bytes("number_1()")));
        selectors1[2] = bytes4(keccak256(bytes("increment()")));
        selectors1[3] = bytes4(keccak256(bytes("increment_shared()")));
        IDiamond.FacetCut[] memory cut1 = new IDiamond.FacetCut[](1);
        cut1[0] = IDiamond.FacetCut(
            address(facet1),
            IDiamond.FacetCutAction.Add,
            selectors1
        );

        bytes4[] memory selectors2 = new bytes4[](4);
        selectors2[0] = bytes4(keccak256(bytes("initialize_2()")));
        selectors2[1] = bytes4(keccak256(bytes("number_2()")));
        selectors2[2] = bytes4(keccak256(bytes("decrement()")));
        selectors2[3] = bytes4(keccak256(bytes("decrement_shared()")));
        IDiamond.FacetCut[] memory cut2 = new IDiamond.FacetCut[](1);
        cut2[0] = IDiamond.FacetCut(
            address(facet2),
            IDiamond.FacetCutAction.Add,
            selectors2
        );

        bytes4[] memory selectors3 = new bytes4[](2);
        selectors3[0] = bytes4(keccak256(bytes("initialize_shared()")));
        selectors3[1] = bytes4(keccak256(bytes("number_shared()")));
        IDiamond.FacetCut[] memory cut3 = new IDiamond.FacetCut[](1);
        cut3[0] = IDiamond.FacetCut(
            address(facetShared),
            IDiamond.FacetCutAction.Add,
            selectors3
        );

        // execute diamond cut
        proxy.diamondCut(
            cut1,
            address(facet1),
            abi.encodeWithSignature("initialize_1()")
        );
        proxy.diamondCut(
            cut2,
            address(facet2),
            abi.encodeWithSignature("initialize_2()")
        );
        proxy.diamondCut(
            cut3,
            address(facetShared),
            abi.encodeWithSignature("initialize_shared()")
        );

        IWDiamond wproxy = IWDiamond(address(proxy));

        // test initial state
        assertEq(wproxy.number_1(), 42, "initial number 1");
        assertEq(wproxy.number_2(), 42, "initial number 2");
        assertEq(wproxy.number_shared(), 42, "initial number shared");

        // test increment
        wproxy.increment();
        assertEq(wproxy.number_1(), 43, "incremented number 1");
        // test decrement
        wproxy.decrement();
        assertEq(wproxy.number_2(), 41, "decremented number 2");
        // test increment shared
        wproxy.increment_shared();
        wproxy.increment_shared();
        assertEq(wproxy.number_shared(), 44, "incremented number shared");
    }

    function testRemoveFacet() public {
        DiamondUpgradeableProxy proxy = new DiamondUpgradeableProxy();
        DiamondFacet1 facet1 = new DiamondFacet1();
        DiamondFacet2 facet2 = new DiamondFacet2();
        DiamondFacetShared facetShared = new DiamondFacetShared();

        // create diamond cuts

        bytes4[] memory selectors1 = new bytes4[](4);
        selectors1[0] = bytes4(keccak256(bytes("initialize_1()")));
        selectors1[1] = bytes4(keccak256(bytes("number_1()")));
        selectors1[2] = bytes4(keccak256(bytes("increment()")));
        selectors1[3] = bytes4(keccak256(bytes("increment_shared()")));
        IDiamond.FacetCut[] memory cut1 = new IDiamond.FacetCut[](1);
        cut1[0] = IDiamond.FacetCut(
            address(facet1),
            IDiamond.FacetCutAction.Add,
            selectors1
        );

        bytes4[] memory selectors2 = new bytes4[](4);
        selectors2[0] = bytes4(keccak256(bytes("initialize_2()")));
        selectors2[1] = bytes4(keccak256(bytes("number_2()")));
        selectors2[2] = bytes4(keccak256(bytes("decrement()")));
        selectors2[3] = bytes4(keccak256(bytes("decrement_shared()")));
        IDiamond.FacetCut[] memory cut2 = new IDiamond.FacetCut[](1);
        cut2[0] = IDiamond.FacetCut(
            address(facet2),
            IDiamond.FacetCutAction.Add,
            selectors2
        );

        bytes4[] memory selectors3 = new bytes4[](2);
        selectors3[0] = bytes4(keccak256(bytes("initialize_shared()")));
        selectors3[1] = bytes4(keccak256(bytes("number_shared()")));
        IDiamond.FacetCut[] memory cut3 = new IDiamond.FacetCut[](1);
        cut3[0] = IDiamond.FacetCut(
            address(facetShared),
            IDiamond.FacetCutAction.Add,
            selectors3
        );

        // execute diamond cut
        proxy.diamondCut(
            cut1,
            address(facet1),
            abi.encodeWithSignature("initialize_1()")
        );
        proxy.diamondCut(
            cut2,
            address(facet2),
            abi.encodeWithSignature("initialize_2()")
        );
        proxy.diamondCut(
            cut3,
            address(facetShared),
            abi.encodeWithSignature("initialize_shared()")
        );

        IWDiamond wproxy = IWDiamond(address(proxy));

        // test initial state
        assertEq(wproxy.number_1(), 42, "initial number 1");
        assertEq(wproxy.number_2(), 42, "initial number 2");
        assertEq(wproxy.number_shared(), 42, "initial number shared");

        // remove facet 1
        bytes4[] memory selectors4 = new bytes4[](1);
        selectors4[0] = bytes4(keccak256(bytes("increment()")));
        IDiamond.FacetCut[] memory cut4 = new IDiamond.FacetCut[](1);
        cut4[0] = IDiamond.FacetCut(
            address(facet1),
            IDiamond.FacetCutAction.Remove,
            selectors4
        );
        proxy.diamondCut(cut4, address(0), "");

        vm.expectRevert("Diamond: Function does not exist");
        wproxy.increment();
    }
}
