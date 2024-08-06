// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mock/MockV3Aggregator.sol";
import {ERC20Mock} from
    "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/mocks/ERC20Mock.sol";

contract ProtocolConfig is Script {
    struct NetworkConfig {
        address router;
        uint256 chainSelector;
        address tokenOne;
        address tokenTwo;
        address tokenOnePriceFeed;
        address tokenTwoPriceFeed;
    }

    uint8 public constant DECIMALS = 8;
    int256 public constant USD_PRICE = 1e8;
    int256 public constant ETH_USD_PRICE = 2000e8;
    uint256 public DEFAULT_ANVIL_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 8453) {
            activeNetworkConfig = getBaseConfig();
        } else if (block.chainid == 84532) {
            activeNetworkConfig = getBaseTestnetConfig();
        } else if (block.chainid == 11) {
            activeNetworkConfig = getOptmisimConfig();
        } else if (block.chainid == 11155420) {
            activeNetworkConfig = getOptmisimTestnetConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getBaseConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            router: 0xD3b06cEbF099CE7DA4AcCf578aaebFDBd6e88a93,
            chainSelector: 10344971235874465080,
            tokenOne: 0x036CbD53842c5426634e7929541eC2318f3dCF7e,
            tokenTwo: 0xA98FA8A008371b9408195e52734b1768c0d1Cb5c,
            tokenOnePriceFeed: 0xdd13E55209Fd76AfE204dBda4007C227904f0a81,
            tokenTwoPriceFeed: 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063
        });
    }

    function getBaseTestnetConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            router: 0xD3b06cEbF099CE7DA4AcCf578aaebFDBd6e88a93,
            chainSelector: 10344971235874465080,
            tokenOne: 0x036CbD53842c5426634e7929541eC2318f3dCF7e,
            tokenTwo: 0xA98FA8A008371b9408195e52734b1768c0d1Cb5c,
            tokenOnePriceFeed: 0xd30e2101a97dcbAeBCBC04F14C3f624E67A35165,
            tokenTwoPriceFeed: 0x3c65e28D357a37589e1C7C86044a9f44dDC17134
        });
    }

    function getOptmisimConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            router: 0xD3b06cEbF099CE7DA4AcCf578aaebFDBd6e88a93,
            chainSelector: 10344971235874465080,
            tokenOne: 0x036CbD53842c5426634e7929541eC2318f3dCF7e,
            tokenTwo: 0xA98FA8A008371b9408195e52734b1768c0d1Cb5c,
            tokenOnePriceFeed: 0xdd13E55209Fd76AfE204dBda4007C227904f0a81,
            tokenTwoPriceFeed: 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063
        });
    }

    function getOptmisimTestnetConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            router: 0xD3b06cEbF099CE7DA4AcCf578aaebFDBd6e88a93,
            chainSelector: 10344971235874465080,
            tokenOne: 0x036CbD53842c5426634e7929541eC2318f3dCF7e,
            tokenTwo: 0xA98FA8A008371b9408195e52734b1768c0d1Cb5c,
            tokenOnePriceFeed: 0xdd13E55209Fd76AfE204dBda4007C227904f0a81,
            tokenTwoPriceFeed: 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063
        });
    }

    // op 10

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        vm.startBroadcast();
        MockV3Aggregator ethUsdPriceFeed = new MockV3Aggregator(DECIMALS, ETH_USD_PRICE);
        ERC20Mock wethMock = new ERC20Mock("WETH", "WETH", msg.sender, 1000e8);

        MockV3Aggregator usdPriceFeed = new MockV3Aggregator(DECIMALS, USD_PRICE);
        ERC20Mock usdMock = new ERC20Mock("USD", "USD", msg.sender, 1000e8);
        vm.stopBroadcast();

        return NetworkConfig({
            router: 0xD3b06cEbF099CE7DA4AcCf578aaebFDBd6e88a93,
            chainSelector: 10344971235874465080,
            tokenOne: address(usdMock),
            tokenTwo: address(wethMock),
            tokenOnePriceFeed: address(usdPriceFeed),
            tokenTwoPriceFeed: address(ethUsdPriceFeed)
        });
    }
}
