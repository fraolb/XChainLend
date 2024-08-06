// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {LendProtocol} from "../../src/LendProtocol.sol";
import {ERC20Mock} from
    "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/mocks/ERC20Mock.sol";
import {ProtocolConfig} from "../../script/ProtocolConfig.s.sol";
import {DeployProtocol} from "../../script/DeployProtocol.s.sol";

contract LendProtocolTest is Test {
    LendProtocol lendProtocol;
    ProtocolConfig config;
    DeployProtocol deployer;

    address router;
    uint256 chainSelector;
    address[] tokens;
    address[] tokenPriceFeeds;

    address public USER = makeAddr("user");
    uint256 public constant AMOUNT_COLLATERAL = 1000000000000 ether;

    function setUp() public {
        deployer = new DeployProtocol();
        (lendProtocol, config) = deployer.run();
        ProtocolConfig.NetworkConfig memory networkConfig = config.getActiveNetworkConfig();

        router = networkConfig.router;
        chainSelector = networkConfig.chainSelector;
        tokens = networkConfig.tokens;
        tokenPriceFeeds = networkConfig.tokenPriceFeeds;
    }

    /// Test Lend token function
    function testRevertIfTokenAmountIsZero() public {
        vm.startPrank(USER);
        ERC20Mock(tokens[0]).approve(address(lendProtocol), AMOUNT_COLLATERAL);

        vm.expectRevert(LendProtocol.Error__NeedsMoreThanZero.selector);
        lendProtocol.lendToken(tokens[0], 0);
        vm.stopPrank();
    }

    function testRevertsIfTokenNotFound() public {
        vm.startPrank(USER);
        ERC20Mock(tokens[0]).approve(address(lendProtocol), AMOUNT_COLLATERAL);
        vm.expectRevert(LendProtocol.Error__NotAllowedToken.selector);
        lendProtocol.lendToken(USER, 1);
        vm.stopPrank();
    }

    function testCanLendToken() public {
        vm.startPrank(USER);
        ERC20Mock(tokens[0]).approve(address(lendProtocol), AMOUNT_COLLATERAL);
        lendProtocol.lendToken(tokens[0], 1);

        // Use the getter function to retrieve TokenData
        (uint256 totalLiquidity, uint256 totalBorrowed, uint256 totalInterestAccrued) =
            lendProtocol.getTokenData(tokens[0]);

        // Assert that totalLiquidity is 1
        assertEq(1, totalLiquidity);
    }
}
