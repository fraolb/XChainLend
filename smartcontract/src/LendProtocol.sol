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
import {SafeERC20} from
    "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/utils/SafeERC20.sol";
import "./library/Math.sol";

/*
     * @notice This is XChain lend protocol
     * It takes tokens from mulitple chains using chainlink ccip
     * built on ETH hackathon
     */
contract LendProtocol is CCIPReceiver, OwnerIsCreator {
    using Math for uint256;
    using SafeERC20 for IERC20;

    ////////////////////////////
    /////// Errors /////////////
    ////////////////////////////
    error NotEnoughBalance(uint256 currentBalance, uint256 calculatedFees);

    error Error__TokenAddressesAndRoutersAddressesMustBeSameLength();
    error Error__DepositCollateralFailed();
    error Error__DepositLendFailed();
    error Error__BorrowAmountExceedsCollateralValue();
    error Error__BorrowFailed();
    error Error__NeedsMoreThanZero();
    error Error__NotAllowedToken();
    error Error__NoLendMoneyFound();
    error Error__RequestAmountExceedsLendAmount();
    error Error__WithdrawLendFailed();
    error Error__BorrowAmountExceedsLiquidity();
    error Error__PaybackBorrowFailed();
    error DestinationChainNotAllowed(uint64);
    error SourceChainNotAllowed(uint64);
    error SenderNotAllowed(address);

    struct LenderInfo {
        uint256 amount;
        address lendToken;
        uint256 timestamp;
        uint256 interestAccrued;
        Chain chain;
    }

    struct TokenData {
        uint256 totalLiquidity;
        uint256 totalBorrowed;
        uint256 totalInterestAccrued;
    }

    struct BorrowInfo {
        uint256 amount;
        address borrowedToken;
        bool onTheSameChain;
        uint256 timestamp;
        Chain chain;
    }

    struct CollateralInfo {
        uint256 timestamp;
        address collateralToken;
        uint256 collateralAmount;
        Chain chain;
    }

    enum Chain {
        OPTIMISM,
        BASE,
        CELO
    }

    mapping(address => mapping(address => LenderInfo)) public s_lenderInfo; // Lender => Token => Info
    mapping(address => TokenData) public s_tokenData; // Token => Data
    mapping(address => mapping(address => BorrowInfo)) public s_borrowInfo; // Borrower => Token => Info
    mapping(address => mapping(address => CollateralInfo)) public s_collateralInfo; // Borrower collateral => Token => Info

    uint256 public annualInterestRate; // Annual interest rate in basis points

    IERC20[] private s_tokenAddresses;
    // mapped the price feed and the routers to the addresses correspondly
    mapping(address => address) s_priceFeeds;
    mapping(address => IRouterClient) s_routers;
    IRouterClient router;
    uint64 chainSelector;
    Chain protocolChain;

    bytes32 private s_lastReceivedMessageId; // Store the last received messageId.
    address private s_lastReceivedTokenAddress; // Store the last received token address.
    uint256 private s_lastReceivedTokenAmount; // Store the last received amount.
    string private s_lastReceivedText; // Store the last received text.

    // Mapping to keep track of allowlisted destination chains.
    mapping(uint64 => bool) public allowlistedDestinationChains;

    // Mapping to keep track of allowlisted source chains.
    mapping(uint64 => bool) public allowlistedSourceChains;

    // Mapping to keep track of allowlisted senders.
    mapping(address => bool) public allowlistedSenders;

    ////////////////////////
    ///// Events       /////
    ////////////////////////
    // Event emitted when a message is sent to another chain.
    event MessageSent(
        bytes32 indexed messageId,
        uint64 indexed destinationChainSelector,
        address receiver,
        string text,
        address feeToken,
        uint256 fees
    );

    // Event emitted when a message is received from another chain.
    // The chain selector of the source chain.
    // The address of the sender from the source chain.
    // The text that was received.
    // The token address that was transferred.
    // The token amount that was transferred.
    event MessageReceived( // The unique ID of the CCIP message.
        bytes32 indexed messageId,
        uint64 indexed sourceChainSelector,
        address sender,
        string text,
        address token,
        uint256 tokenAmount
    );

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

    /// @dev Modifier that checks if the chain with the given destinationChainSelector is allowlisted.
    /// @param _destinationChainSelector The selector of the destination chain.
    modifier onlyAllowlistedDestinationChain(uint64 _destinationChainSelector) {
        if (!allowlistedDestinationChains[_destinationChainSelector]) {
            revert DestinationChainNotAllowed(_destinationChainSelector);
        }
        _;
    }

    /// @dev Modifier that checks if the chain with the given sourceChainSelector is allowlisted and if the sender is allowlisted.
    /// @param _sourceChainSelector The selector of the destination chain.
    /// @param _sender The address of the sender.
    modifier onlyAllowlisted(uint64 _sourceChainSelector, address _sender) {
        if (!allowlistedSourceChains[_sourceChainSelector]) {
            revert SourceChainNotAllowed(_sourceChainSelector);
        }
        if (!allowlistedSenders[_sender]) revert SenderNotAllowed(_sender);
        _;
    }

    /*
     * @notice The constructor takes the router addresses and the tokens that are transferrable
     * @param _routers takes the addresses of router contracts
     * @param _tokens is the tokens that users lend and borrow
     */
    constructor(
        address _router,
        uint64 _chainSelector,
        address[] memory _tokenAddresses,
        address[] memory priceFeedAddresses,
        Chain chain
    ) CCIPReceiver(_router) {
        if (_tokenAddresses.length != priceFeedAddresses.length) {
            revert Error__TokenAddressesAndRoutersAddressesMustBeSameLength();
        }
        for (uint256 i = 0; i < _tokenAddresses.length; i++) {
            s_priceFeeds[_tokenAddresses[i]] = priceFeedAddresses[i];
            s_tokenAddresses.push(IERC20(_tokenAddresses[i]));
        }
        router = IRouterClient(_router);
        chainSelector = _chainSelector;
        protocolChain = chain;
    }

    /// @dev Updates the allowlist status of a destination chain for transactions.
    /// @notice This function can only be called by the owner.
    /// @param _destinationChainSelector The selector of the destination chain to be updated.
    /// @param allowed The allowlist status to be set for the destination chain.
    function allowlistDestinationChain(uint64 _destinationChainSelector, bool allowed) external onlyOwner {
        allowlistedDestinationChains[_destinationChainSelector] = allowed;
    }

    /**
     * @notice This function is for anyone to lend tokens that are listed, on the same chain
     * @param tokenAddress is the token address of the token to be lend
     * @param amount the amount of token to be lend
     */
    function lendTokenOnTheSameChain(address tokenAddress, uint256 amount)
        external
        isTokenAllowed(tokenAddress)
        amountMoreThanZero(amount)
    {
        LenderInfo storage info = s_lenderInfo[msg.sender][tokenAddress];
        info.amount += amount;
        info.lendToken = tokenAddress;
        info.timestamp = block.timestamp;
        info.chain = protocolChain;

        TokenData storage tokenDataInfo = s_tokenData[tokenAddress];
        tokenDataInfo.totalLiquidity += amount;

        bool success = IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
        if (!success) {
            revert Error__DepositLendFailed();
        }
    }

    function lendTokenFromDifferentChain(address lender, address tokenAddress, uint256 amount, Chain chain)
        internal
        isTokenAllowed(tokenAddress)
    {
        LenderInfo storage info = s_lenderInfo[lender][tokenAddress];
        info.amount += amount;
        info.lendToken = tokenAddress;
        info.timestamp = block.timestamp;
        info.chain = chain;

        TokenData storage tokenDataInfo = s_tokenData[tokenAddress];
        tokenDataInfo.totalLiquidity += amount;
    }

    /// @dev Updates the allowlist status of a source chain
    /// @notice This function can only be called by the owner.
    /// @param _sourceChainSelector The selector of the source chain to be updated.
    /// @param allowed The allowlist status to be set for the source chain.
    function allowlistSourceChain(uint64 _sourceChainSelector, bool allowed) external onlyOwner {
        allowlistedSourceChains[_sourceChainSelector] = allowed;
    }

    /// @dev Updates the allowlist status of a sender for transactions.
    /// @notice This function can only be called by the owner.
    /// @param _sender The address of the sender to be updated.
    /// @param allowed The allowlist status to be set for the sender.
    function allowlistSender(address _sender, bool allowed) external onlyOwner {
        allowlistedSenders[_sender] = allowed;
    }

    /**
     * @notice The function helps users to deposit collateral before borrowing or to earn by lending, on the same chain
     * @param tokenCollateralAddress The addresss of the token user deposit as collateral
     * @param collateralAmount The amount of the token deposited
     */
    function depositCollateralOnTheSameChain(address tokenCollateralAddress, uint256 collateralAmount)
        external
        isTokenAllowed(tokenCollateralAddress)
        amountMoreThanZero(collateralAmount)
    {
        CollateralInfo storage info = s_collateralInfo[msg.sender][tokenCollateralAddress];
        info.collateralToken = tokenCollateralAddress;
        info.collateralAmount = collateralAmount;
        info.timestamp = block.timestamp;
        info.chain = protocolChain;
        // s_collateralDeposit[msg.sender][tokenCollateralAddress] += collateralAmount;
        bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), collateralAmount);
        if (!success) {
            revert Error__DepositCollateralFailed();
        }
    }

    function depositCollateralFromDifferentChain(
        address user,
        address tokenCollateralAddress,
        uint256 collateralAmount,
        Chain chain
    ) internal {
        CollateralInfo storage info = s_collateralInfo[user][tokenCollateralAddress];
        info.collateralToken = tokenCollateralAddress;
        info.collateralAmount = collateralAmount;
        info.timestamp = block.timestamp;
        info.chain = chain;
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
            uint256 collateralAmount = s_collateralInfo[msg.sender][tokenAddress].collateralAmount;
            if (collateralAmount > 0) {
                uint256 amount = getUsdValue(s_priceFeeds[tokenAddress], collateralAmount);

                totalCollateralValue += amount;
            }
        }

        uint256 maxBorrowValue = totalCollateralValue / 2; // 50% LTV

        uint256 amountToBeBorrowedInUsd = getUsdValue(s_priceFeeds[tokenBorrowAddress], borrowAmount);
        if (amountToBeBorrowedInUsd > maxBorrowValue) {
            revert Error__BorrowAmountExceedsCollateralValue();
        }

        TokenData storage tokenDataInfo = s_tokenData[tokenBorrowAddress];
        if (borrowAmount > tokenDataInfo.totalLiquidity) {
            revert Error__BorrowAmountExceedsLiquidity();
        }
        tokenDataInfo.totalLiquidity -= borrowAmount;
        tokenDataInfo.totalBorrowed += borrowAmount;

        s_borrowInfo[msg.sender][tokenBorrowAddress].amount += borrowAmount;
        s_borrowInfo[msg.sender][tokenBorrowAddress].borrowedToken = tokenBorrowAddress;
        bool success = IERC20(tokenBorrowAddress).transfer(msg.sender, borrowAmount);
        if (!success) {
            revert Error__BorrowFailed();
        }
    }

    function withdrawLendTokenOnTheSameChain(address tokenAddress, uint256 amountToBeWithdrawn)
        external
        isTokenAllowed(tokenAddress)
        amountMoreThanZero(amountToBeWithdrawn)
    {
        LenderInfo storage lender = s_lenderInfo[msg.sender][tokenAddress];
        if (lender.amount == 0) {
            revert Error__NoLendMoneyFound();
        }
        if (lender.amount < amountToBeWithdrawn) {
            revert Error__RequestAmountExceedsLendAmount();
        }
        lender.amount -= amountToBeWithdrawn;
        TokenData storage token = s_tokenData[tokenAddress];
        token.totalLiquidity -= amountToBeWithdrawn;
        bool success = IERC20(tokenAddress).transfer(msg.sender, amountToBeWithdrawn);
        if (!success) {
            revert Error__WithdrawLendFailed();
        }
    }

    function paybackBorrowedTokenOnTheSameChain(address tokenAddress, uint256 amountToBePaid)
        external
        isTokenAllowed(tokenAddress)
        amountMoreThanZero(amountToBePaid)
    {
        BorrowInfo storage borrowedInfo = s_borrowInfo[msg.sender][tokenAddress];

        borrowedInfo.amount -= amountToBePaid;
        TokenData storage token = s_tokenData[tokenAddress];
        token.totalLiquidity += amountToBePaid;
        token.totalBorrowed -= amountToBePaid;
        bool success = IERC20(tokenAddress).transferFrom(msg.sender, address(this), amountToBePaid);
        if (!success) {
            revert Error__PaybackBorrowFailed();
        }
    }

    function paybackBorrowedTokenFromDifferentChain(address user, address tokenAddress, uint256 amountToBePaid)
        internal
    {
        BorrowInfo storage borrowedInfo = s_borrowInfo[user][tokenAddress];

        borrowedInfo.amount -= amountToBePaid;
        TokenData storage token = s_tokenData[tokenAddress];
        token.totalLiquidity += amountToBePaid;
        token.totalBorrowed -= amountToBePaid;
    }

    function borrowOnDifferentChain(address receiver, string calldata text) external returns (bytes32 messageId) {
        // Create a tokenTransferMessage struct in memory with necessary information for sending a cross-chain message
        Client.EVM2AnyMessage memory tokenTransferMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver), // ABI-encoded receiver address
            data: abi.encode(text), // ABI-encoded string
            tokenAmounts: new Client.EVMTokenAmount[](0), // Empty array indicating no tokens are being sent
            extraArgs: Client._argsToBytes(
                // Additional arguments, setting gas limit
                Client.EVMExtraArgsV1({gasLimit: 200_000})
            ),
            // Set the feeToken address (e.g., LINK)
            feeToken: address(0) // Replace address(0) with the actual LINK token address
        });

        // Get the fee required to send the message
        uint256 fees = router.getFee(chainSelector, tokenTransferMessage);

        // Ensure the contract has enough LINK tokens to pay the fees
        IERC20 linkToken = IERC20(address(0)); // Replace address(0) with the LINK token address
        uint256 balance = linkToken.balanceOf(address(this));

        if (fees > balance) {
            revert NotEnoughBalance(balance, fees);
        }

        // Approve the Router to transfer LINK tokens on the contract's behalf
        linkToken.approve(address(router), fees);

        // Send the message through the router and store the returned message ID
        messageId = router.ccipSend(chainSelector, tokenTransferMessage);

        // Emit an event with message details
        emit MessageSent(messageId, chainSelector, receiver, text, address(linkToken), fees);

        // Return the message ID
        return messageId;
    }

    /// handle a received message
    function _ccipReceive(Client.Any2EVMMessage memory any2EvmMessage)
        internal
        override
        onlyAllowlisted(any2EvmMessage.sourceChainSelector, abi.decode(any2EvmMessage.sender, (address)))
    {
        s_lastReceivedMessageId = any2EvmMessage.messageId;
        string memory receivedJson = abi.decode(any2EvmMessage.data, (string));

        // Parse the JSON string (assume you have a JSON parsing library or use manual parsing)
        (address user, string memory task) = parseJson(receivedJson);

        s_lastReceivedTokenAddress = any2EvmMessage.destTokenAmounts[0].token;
        s_lastReceivedTokenAmount = any2EvmMessage.destTokenAmounts[0].amount;

        if (keccak256(bytes(task)) == keccak256(bytes("payback"))) {
            paybackBorrowedTokenFromDifferentChain(
                user, any2EvmMessage.destTokenAmounts[0].token, any2EvmMessage.destTokenAmounts[0].amount
            );
        } else if (keccak256(bytes(task)) == keccak256(bytes("lend"))) {
            lendTokenFromDifferentChain(
                user,
                any2EvmMessage.destTokenAmounts[0].token,
                any2EvmMessage.destTokenAmounts[0].amount,
                Chain.OPTIMISM
            );
        } else if (keccak256(bytes(task)) == keccak256(bytes("depositCollateral"))) {
            depositCollateralFromDifferentChain(
                user,
                any2EvmMessage.destTokenAmounts[0].token,
                any2EvmMessage.destTokenAmounts[0].amount,
                Chain.OPTIMISM
            );
        }

        emit MessageReceived(
            any2EvmMessage.messageId,
            any2EvmMessage.sourceChainSelector,
            user,
            task,
            any2EvmMessage.destTokenAmounts[0].token,
            any2EvmMessage.destTokenAmounts[0].amount
        );
    }

    // Example of a basic JSON parser
    function parseJson(string memory json) internal pure returns (address user, string memory task) {
        // Basic string manipulation to extract user and task
        // Assume JSON format is always: {"user":"<address>", "task":"<task>"}

        bytes memory jsonBytes = bytes(json);
        bytes memory addressBytes = new bytes(42); // "0x" + 40 hex characters
        bytes memory taskBytes = new bytes(jsonBytes.length - 55); // Length of task string

        for (uint256 i = 10; i < 52; i++) {
            // Extract the address
            addressBytes[i - 10] = jsonBytes[i];
        }
        user = parseAddress(string(addressBytes));

        for (uint256 i = 55; i < jsonBytes.length - 2; i++) {
            // Extract the task
            taskBytes[i - 55] = jsonBytes[i];
        }
        task = string(taskBytes);
    }

    // Helper function to parse an address string back into an address
    function parseAddress(string memory addressString) internal pure returns (address) {
        bytes memory b = bytes(addressString);
        uint160 result = 0;
        for (uint256 i = 2; i < 2 + 40; i++) {
            uint256 c = uint256(uint8(b[i]));
            if (c >= 97) c -= 87;
            else if (c >= 65) c -= 55;
            else if (c >= 48) c -= 48;
            result = uint160(result * 16 + c);
        }
        return address(result);
    }

    /// @notice Fetches the details of the last received message.
    /// @return messageId The ID of the last received message.
    /// @return text The last received text.
    function getLastReceivedMessageDetails() external view returns (bytes32 messageId, string memory text) {
        return (s_lastReceivedMessageId, s_lastReceivedText);
    }

    /////////////////////////////
    //// view            ///////
    ////////////////////////////

    /**
     * @notice This function helps users to view how much collataral they have on one chain
     * @return First it returns collateral token
     * @return The second array returns the amount of each token collateral
     */
    function getCollateralAmount() public view returns (address[] memory, uint256[] memory) {
        uint256 length = s_tokenAddresses.length;
        address[] memory tokenAddresses = new address[](length);
        uint256[] memory amounts = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            address tokenAddress = address(s_tokenAddresses[i]);
            tokenAddresses[i] = tokenAddress;
            amounts[i] = s_collateralInfo[msg.sender][tokenAddress].collateralAmount;
        }

        return (tokenAddresses, amounts);
    }

    /**
     * @notice This function returns how much user lend a token
     */
    function getLenderTokenData(address tokenAddress)
        public
        view
        returns (uint256 amount, address lendToken, uint256 timestamp, uint256 interestAccrued)
    {
        LenderInfo memory data = s_lenderInfo[msg.sender][tokenAddress];
        return (data.amount, data.lendToken, data.timestamp, data.interestAccrued);
    }

    /**
     * @notice This functino returns the users borrow data, how much they borrowed
     */
    function getBorrowData() public view returns (BorrowInfo[] memory) {
        // Calculate the length of the borrower's active borrowings
        uint256 borrowCount = 0;
        for (uint256 i = 0; i < s_tokenAddresses.length; i++) {
            address tokenAddress = address(s_tokenAddresses[i]);
            uint256 borrowAmount = s_borrowInfo[msg.sender][tokenAddress].amount;
            if (borrowAmount > 0) {
                borrowCount++;
            }
        }

        // Create a dynamic array in memory to store active borrowings
        BorrowInfo[] memory borrowInfo = new BorrowInfo[](borrowCount);
        uint256 index = 0;
        for (uint256 i = 0; i < s_tokenAddresses.length; i++) {
            address tokenAddress = address(s_tokenAddresses[i]);
            BorrowInfo memory borrow = s_borrowInfo[msg.sender][tokenAddress];
            if (borrow.amount > 0) {
                borrowInfo[index] = borrow;
                index++;
            }
        }

        return borrowInfo;
    }

    /**
     * @notice This function helps to get the usd value of a token
     * @param token The token wanted to get the value of
     * @param amount The amount of the token
     */
    function getUsdValue(address token, uint256 amount) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(token);
        (, int256 price,,,) = priceFeed.latestRoundData();
        uint8 decimals = priceFeed.decimals();
        return (uint256(price) * amount) / (10 ** decimals);
    }

    /**
     * @notice This function give info about token
     * @param tokenAddress is the token requied to get data of
     * @return totalLiquidity the total liquidity of the token
     * @return totalBorrowed the total borrowed amount of the token
     * @return totalInterestAccrued the total interest the lender get for supplying the token
     */
    function getTokenData(address tokenAddress)
        public
        view
        returns (uint256 totalLiquidity, uint256 totalBorrowed, uint256 totalInterestAccrued)
    {
        TokenData memory data = s_tokenData[tokenAddress];
        return (data.totalLiquidity, data.totalBorrowed, data.totalInterestAccrued);
    }
}
