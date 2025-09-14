// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {CounterV1} from "../src/CounterV1.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployCounter is Script {

    function run() external {
        deploy();
    }

    function deploy() public returns (address implementationAddress, address proxyAddress) {
        vm.startBroadcast();
        CounterV1 counter = new CounterV1();
        ERC1967Proxy proxy = new ERC1967Proxy(address(counter), "");
        CounterV1(address(proxy)).initialize(1);
        vm.stopBroadcast();
        return (address(counter), address(proxy));
    }

}