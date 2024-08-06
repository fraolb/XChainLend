// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {OwnerIsCreator} from "@chainlink/contracts-ccip/src/v0.8/shared/access/OwnerIsCreator.sol";
import {IAny2EVMMessageReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IAny2EVMMessageReceiver.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {IERC20} from
    "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import {IERC165} from
    "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/utils/introspection/IERC165.sol";
import "./library/Math.sol";

contract LendProtocol is OwnerIsCreator {
    using Math for uint256;

    error Error__TokenAddressesAndRoutersAddressesMustBeSameLength();
    error Error__DepositCollateralFailed();
    error Error__DepositLendFailed();
    error Error__BorrowAmountExceedsCollateralValue();
    error Error__BorrowFailed();
    error Error__NeedsMoreThanZero();
    error Error__NotAllowedToken();

    struct LenderInfo {
        uint256 amount;
        uint256 timestamp;
        uint256 interestAccrued;
    }

    struct TokenData {
        uint256 totalLiquidity;
        uint256 totalBorrowed;
        uint256 totalInterestAccrued;
    }

    struct BorrowInfo {
        uint256 amount;
        uint256 collateralAmount;
        uint256 timestamp;
    }

    mapping(address => mapping(address => LenderInfo)) public s_lenderInfo; // Lender => Token => Info
    mapping(address => TokenData) public s_tokenData; // Token => Data
    mapping(address => mapping(address => BorrowInfo)) public s_borrowInfo; // Borrower => Token => Info

    uint256 public annualInterestRate; // Annual interest rate in basis points

    IERC20[] private s_tokenAddresses;
    // mapped the price feed and the routers to the addresses correspondly
    mapping(address token => address priceFeed) s_priceFeeds;
    mapping(address token => IRouterClient router) s_routers;
    IRouterClient router;
    uint256 chainSelector;

    // Collateral Deposit Address => Deposited Token Address ==> amount
    mapping(address => mapping(address => uint256)) public s_collateralDeposit;
    // Depsitor Address => Deposited Token Address ==> amount
    mapping(address => mapping(address => uint256)) public s_deposits;
    // Depsitor Address => Borrowed Token Address ==> amount
    mapping(address => mapping(address => uint256)) public s_borrowings;

    ///////////////////////
    //// Modifiers ///////
    /////////////////////
    modifier amountMoreThanZero(uint256 amount) {
        if (amount == 0) {
            revert Error__NeedsMoreThanZero();
        }
        _;
    }

    modifier isTokenAllowed(address token) {
        if (s_priceFeeds[token] == address(0)) {
            revert Error__NotAllowedToken();
        }
        _;
    }

    /*
     * @notice The constructor takes the router addresses and the tokens that are transferrable
     * @param _routers takes the addresses of router contracts
     * @param _tokens is the tokens that users lend and borrow
     */
    constructor(
        address _router,
        uint256 _chainSelector,
        address[] memory _tokenAddresses,
        address[] memory priceFeedAddresses
    ) {
        if (_tokenAddresses.length != priceFeedAddresses.length) {
            revert Error__TokenAddressesAndRoutersAddressesMustBeSameLength();
        }
        for (uint256 i = 0; i < _tokenAddresses.length; i++) {
            s_priceFeeds[_tokenAddresses[i]] = priceFeedAddresses[i];
            s_tokenAddresses.push(IERC20(_tokenAddresses[i]));
            //s_routers[_tokenAddresses[i]] = IRouterClient(_routers[i]);
            router = IRouterClient(_router);
        }
        chainSelector = _chainSelector;
    }

    /**
     * @notice This function is for anyone to lend tokens that are listed
     * @param tokenAddress is the token address of the token to be lend
     * @param amount the amount of token to be lend
     */
    function lendToken(address tokenAddress, uint256 amount)
        external
        isTokenAllowed(tokenAddress)
        amountMoreThanZero(amount)
    {
        LenderInfo storage info = s_lenderInfo[msg.sender][tokenAddress];
        info.amount += amount;
        info.timestamp = block.timestamp;

        TokenData storage tokenDataInfo = s_tokenData[tokenAddress];
        tokenDataInfo.totalLiquidity += amount;

        bool success = IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
        if (!success) {
            revert Error__DepositLendFailed();
        }
    }

    function getTokenData(address tokenAddress)
        public
        view
        returns (uint256 totalLiquidity, uint256 totalBorrowed, uint256 totalInterestAccrued)
    {
        TokenData memory data = s_tokenData[tokenAddress];
        return (data.totalLiquidity, data.totalBorrowed, data.totalInterestAccrued);
    }

    /**
     * @notice The function helps users to deposit collateral before borrowing or to earn by lending
     * @param tokenCollateralAddress The addresss of the token user deposit as collateral
     * @param collateralAmount The amount of the token deposited
     */
    function depositCollateral(address tokenCollateralAddress, uint256 collateralAmount)
        external
        isTokenAllowed(tokenCollateralAddress)
        amountMoreThanZero(collateralAmount)
    {
        s_collateralDeposit[msg.sender][tokenCollateralAddress] += collateralAmount;
        bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), collateralAmount);
        if (!success) {
            revert Error__DepositCollateralFailed();
        }
    }

    // Function to borrow tokens
    function borrowToken(address tokenAddress, uint256 amount, uint256 collateralAmount) external {
        // Over-collateralization check and transfer collateral logic here
        BorrowInfo storage info = s_borrowInfo[msg.sender][tokenAddress];
        info.amount += amount;
        info.collateralAmount += collateralAmount;
        info.timestamp = block.timestamp;

        TokenData storage tokenDataInfo = s_tokenData[tokenAddress];
        tokenDataInfo.totalBorrowed += amount;

        IERC20(tokenAddress).transfer(msg.sender, amount);
    }

    /**
     * @notice This function helps users to view how much collataral they have on one chain
     * @return First it returns collateral token
     * @return The second array returns the amount of each token collateral
     */
    function viewMyCollateral() public view returns (address[] memory, uint256[] memory) {
        uint256 length = s_tokenAddresses.length;
        address[] memory tokenAddresses = new address[](length);
        uint256[] memory amounts = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            address tokenAddress = address(s_tokenAddresses[i]);
            tokenAddresses[i] = tokenAddress;
            amounts[i] = s_deposits[msg.sender][tokenAddress];
        }

        return (tokenAddresses, amounts);
    }

    /**
     * @notice The function allows users to borrow tokens based on their collateral on the same chain
     * @param tokenBorrowAddress The address of the token the user wants to borrow
     * @param borrowAmount The amount of the token the user wants to borrow
     */
    function borrowOnSameChain(address tokenBorrowAddress, uint256 borrowAmount) external {
        uint256 totalCollateralValue = 0;

        // Calculate the total collateral value in USD
        for (uint256 i = 0; i < s_tokenAddresses.length; i++) {
            address tokenAddress = address(s_tokenAddresses[i]);
            uint256 collateralAmount = s_deposits[msg.sender][tokenAddress];
            if (collateralAmount > 0) {
                AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[tokenAddress]);
                (, int256 price,,,) = priceFeed.latestRoundData();
                uint8 decimals = priceFeed.decimals();
                totalCollateralValue += uint256(price) * collateralAmount / (10 ** decimals);
            }
        }

        uint256 maxBorrowValue = totalCollateralValue / 2; // 50% LTV
        AggregatorV3Interface borrowPriceFeed = AggregatorV3Interface(s_priceFeeds[tokenBorrowAddress]);
        (, int256 borrowTokenPrice,,,) = borrowPriceFeed.latestRoundData();
        uint8 borrowDecimals = borrowPriceFeed.decimals();
        uint256 borrowValue = uint256(borrowTokenPrice) * borrowAmount / (10 ** borrowDecimals);
        if (borrowValue > maxBorrowValue) {
            revert Error__BorrowAmountExceedsCollateralValue();
        }

        s_borrowings[msg.sender][tokenBorrowAddress] += borrowAmount;
        bool success = IERC20(tokenBorrowAddress).transfer(msg.sender, borrowAmount);
        if (!success) {
            revert Error__BorrowFailed();
        }
    }
}
