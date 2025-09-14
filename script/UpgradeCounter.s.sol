// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {CounterV1} from "../src/CounterV1.sol";
import {CounterV2} from "../src/CounterV2.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";

contract UpgradeCounter is Script {

    function run() external {
        address proxyAddress = DevOpsTools.get_most_recent_deployment("ERC1967Proxy", block.chainid);
        upgrade(proxyAddress);
    }

    function upgrade(address proxyAddress) public {
        vm.startBroadcast();
        CounterV2 counterV2 = new CounterV2();
        // 这里实际上只是把代理合约的地址用 CounterV1 的 abi 包裹了一下，编译器底层会使用 call
        // 来尝试调用代理合约的函数，最终会走向 fallback 中的 delegatecall，并在代理合约的
        // 上下文中执行升级逻辑
        CounterV1(proxyAddress).upgradeToAndCall(address(counterV2), "");
        // CounterV2 中的 initialize 函数需要用 reinitializer 修饰符，在 initializer 修饰符中
        // 会检查代理是否已经初始化过，如果已经初始化过会报错，由于部署 CounterV1 时已经初始化
        // 过，所以这里如果用 initializer 修饰符肯定会报错
        CounterV2(proxyAddress).initialize(2);
        vm.stopBroadcast();
    }
}