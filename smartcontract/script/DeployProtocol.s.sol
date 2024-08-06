// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {ProtocolConfig} from "./ProtocolConfig.s.sol";
import {LendProtocol} from "../src/LendProtocol.sol";

contract DeployProtocol is Script {
    struct NetworkConfig {
        address router;
        uint256 chainSelector;
        address[] tokens;
        address[] tokenPriceFeeds;
    }

    function run() external returns (LendProtocol, ProtocolConfig) {
        ProtocolConfig config = new ProtocolConfig();
        ProtocolConfig.NetworkConfig memory networkConfig = config.getActiveNetworkConfig();

        vm.startBroadcast();

        LendProtocol lendProtocol = new LendProtocol(
            networkConfig.router, networkConfig.chainSelector, networkConfig.tokens, networkConfig.tokenPriceFeeds
        );

        vm.stopBroadcast();

        return (lendProtocol, config);
    }
}
