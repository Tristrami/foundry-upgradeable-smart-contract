// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract CounterV1 is UUPSUpgradeable, OwnableUpgradeable {

    uint256 internal counter;
    uint256 internal version;

    function initialize(uint256 _version) public initializer {
        __UUPSUpgradeable_init();
        __Ownable_init(msg.sender);
        version = _version;
    }

    function increment() external {
        counter += 1;
    }

    function getCounter() external view returns (uint256) {
        return counter;
    }

    function getVersion() external view returns (uint256) {
        return version;
    }

    function _authorizeUpgrade(address newImplementation) internal override {

    }
}