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

    struct BorrowInfo {
        uint256 amount;
        address borrowedToken;
        bool onTheSameChain;
        uint256 timestamp;
    }

    address router;
    uint256 chainSelector;
    address[] tokens;
    address[] tokenPriceFeeds;

    address public USER = makeAddr("user");
    address public USER2 = makeAddr("user");
    uint256 public constant AMOUNT_COLLATERAL = 10 ether;

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
        ERC20Mock(tokens[0]).mint(USER, 10 ether);
        vm.startPrank(USER);
        ERC20Mock(tokens[0]).approve(address(lendProtocol), 10 ether);
        lendProtocol.lendToken(tokens[0], 1 ether);

        // Use the getter function to retrieve TokenData
        (uint256 totalLiquidity, uint256 totalBorrowed, uint256 totalInterestAccrued) =
            lendProtocol.getTokenData(tokens[0]);

        // Assert that totalLiquidity is 1
        assertEq(1 ether, totalLiquidity);
    }

    /// test deposit collateral
    function testDepositCollateral() public {
        ERC20Mock(tokens[0]).mint(USER, 10 ether);
        vm.startPrank(USER);
        ERC20Mock(tokens[0]).approve(address(lendProtocol), 10 ether);
        lendProtocol.depositCollateral(tokens[0], 1 ether);

        (, uint256[] memory amounts) = lendProtocol.getCollateralAmount();

        assertEq(1 ether, amounts[0]);
    }

    function testMultipleDepositCollateral() public {
        ERC20Mock(tokens[0]).mint(USER, 10 ether);
        ERC20Mock(tokens[1]).mint(USER, 10 ether);
        vm.startPrank(USER);
        ERC20Mock(tokens[0]).approve(address(lendProtocol), 10 ether);
        ERC20Mock(tokens[1]).approve(address(lendProtocol), 10 ether);
        lendProtocol.depositCollateral(tokens[0], 1 ether);
        lendProtocol.depositCollateral(tokens[1], 2 ether);

        (, uint256[] memory amounts) = lendProtocol.getCollateralAmount();

        assertEq(1 ether, amounts[0]);
        assertEq(2 ether, amounts[1]);
    }

    /// test borrow function
    modifier depositedLend() {
        // Mint some mock tokens for the lender
        ERC20Mock(tokens[0]).mint(USER2, 100 ether);
        ERC20Mock(tokens[1]).mint(USER2, 100 ether);

        vm.startPrank(USER2);
        ERC20Mock(tokens[0]).approve(address(lendProtocol), 100 ether);
        ERC20Mock(tokens[1]).approve(address(lendProtocol), 100 ether);
        lendProtocol.lendToken(tokens[0], 50 ether);
        lendProtocol.lendToken(tokens[1], 50 ether);
        vm.stopPrank();
        _;
    }

    function testCanBorrowOnSameChain() public depositedLend {
        // Mint some mock tokens for the user
        ERC20Mock(tokens[0]).mint(USER, 100 ether);
        ERC20Mock(tokens[1]).mint(USER, 100 ether);

        // User deposits collateral
        vm.startPrank(USER);
        ERC20Mock(tokens[0]).approve(address(lendProtocol), 100 ether);
        ERC20Mock(tokens[1]).approve(address(lendProtocol), 100 ether);
        lendProtocol.depositCollateral(tokens[1], 10 ether);

        // Check the collateral amount
        (, uint256[] memory amounts) = lendProtocol.getCollateralAmount();
        assertEq(amounts[1], AMOUNT_COLLATERAL);

        // User borrows token
        lendProtocol.borrowOnSameChain(tokens[0], 1 ether);

        // Verify the borrowing
        (uint256 totalLiquidity, uint256 totalBorrowed, uint256 totalInterestAccrued) =
            lendProtocol.getTokenData(tokens[0]);
        console.log("the total liq ", totalLiquidity);
        console.log("the total borrowed  ", totalBorrowed);

        assertEq(totalBorrowed, 1 ether);

        // Verify user's borrow data
        LendProtocol.BorrowInfo[] memory borrowInfo = lendProtocol.getBorrowData();
        assertEq(borrowInfo.length, 1);
        assertEq(borrowInfo[0].borrowedToken, tokens[0]);
        assertEq(borrowInfo[0].amount, 1 ether);

        vm.stopPrank();
    }

    function testGetUsdValue() public view {
        uint256 MOCK_PRICE = 2000 * 10 ** 8; // Mock price of 2000 USD with 8 decimals
        uint8 DECIMALS = 8;
        uint256 amount = 1 ether; // 1 token with 18 decimals

        // Call getUsdValue function
        uint256 usdValue = lendProtocol.getUsdValue(tokenPriceFeeds[1], amount);

        // Calculate the expected USD value
        uint256 expectedUsdValue = (MOCK_PRICE * amount) / (10 ** DECIMALS);

        console.log("the expected val is ", expectedUsdValue);
        console.log("the value is ", usdValue);

        // Assert that the returned value is equal to the expected value
        assertEq(usdValue, expectedUsdValue);
    }

    /// test withdraw lend function
    function testWithdrawLendToken() public {
        // Mint some mock tokens for the user
        ERC20Mock(tokens[0]).mint(USER, 100 ether);

        // User lends token
        vm.startPrank(USER);
        ERC20Mock(tokens[0]).approve(address(lendProtocol), 100 ether);

        lendProtocol.lendToken(tokens[0], 50 ether);

        // User withdraws lend token
        lendProtocol.withdrawLendToken(tokens[0], 20 ether);

        // Check user's lend data
        (uint256 amount, address lendToken, uint256 timestamp, uint256 interestAccrued) =
            lendProtocol.getLenderTokenData(tokens[0]);
        assertEq(amount, 30 ether);

        // Check the token data
        (uint256 totalLiquidity, uint256 totalBorrowed, uint256 totalInterestAccrued) =
            lendProtocol.getTokenData(tokens[0]);
        assertEq(totalLiquidity, 30 ether);
        assertEq(totalBorrowed, 0 ether);
    }

    /// test re pay the borrow function
    function testPaybackBorrowedToken() public depositedLend {
        // Mint some mock tokens for the user
        ERC20Mock(tokens[0]).mint(USER, 100 ether);
        ERC20Mock(tokens[1]).mint(USER, 100 ether);

        // User deposits collateral
        vm.startPrank(USER);
        ERC20Mock(tokens[0]).approve(address(lendProtocol), 100 ether);
        ERC20Mock(tokens[1]).approve(address(lendProtocol), 100 ether);
        lendProtocol.depositCollateral(tokens[1], 10 ether);

        // User borrows token
        lendProtocol.borrowOnSameChain(tokens[0], 2 ether);

        // User repays back the token
        lendProtocol.paybackBorrowedToken(tokens[0], 1 ether);

        // Check user's borrowed data
        LendProtocol.BorrowInfo[] memory borrowInfo = lendProtocol.getBorrowData();
        assertEq(borrowInfo.length, 1);
        assertEq(borrowInfo[0].borrowedToken, tokens[0]);
        assertEq(borrowInfo[0].amount, 1 ether);

        // Check the token data
        // Verify the borrowing
        (uint256 totalLiquidity, uint256 totalBorrowed, uint256 totalInterestAccrued) =
            lendProtocol.getTokenData(tokens[0]);
        assertEq(totalLiquidity, 49 ether); // Since 2 ether borrowed and 1 ether repaid, and 50 ether is in the lend
        assertEq(totalBorrowed, 1 ether); // Since 2 ether borrowed and 1 ether repaid
    }
}
