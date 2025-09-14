// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {CounterV1} from "../src/CounterV1.sol";
import {CounterV2} from "../src/CounterV2.sol";
import {DeployCounter} from "../script/DeployCounter.s.sol";
import {UpgradeCounter} from "../script/UpgradeCounter.s.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract UpgradeTest is Test {

    DeployCounter private deployer;
    UpgradeCounter private upgrader;
    address private counterV1Address;
    address private proxyAddress;

    function setUp() external {
        deployer = new DeployCounter();
        upgrader = new UpgradeCounter();
        (counterV1Address, proxyAddress) = deployer.deploy();
    }

    function testUpgrade() public {
        assertEq(CounterV1(proxyAddress).getVersion(), 1);
        upgrader.upgrade(proxyAddress);
        assertEq(CounterV2(proxyAddress).getVersion(), 2);
    }
}