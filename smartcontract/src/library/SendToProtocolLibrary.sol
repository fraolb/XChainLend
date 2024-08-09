// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {IERC20} from
    "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from
    "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/utils/SafeERC20.sol";

library SendToProtocolLibrary {
    using SafeERC20 for IERC20;

    // Custom errors
    error NotEnoughBalance(uint256 currentBalance, uint256 calculatedFees);
    error NothingToWithdraw();
    error FailedToWithdrawEth(address owner, address target, uint256 value);

    // Events
    event MessageSent(
        bytes32 indexed messageId,
        uint64 indexed destinationChainSelector,
        address receiver,
        string text,
        address token,
        uint256 tokenAmount,
        address feeToken,
        uint256 fees
    );

    function sendMessagePayLINK(
        IRouterClient s_router,
        IERC20 s_linkToken,
        uint64 _destinationChainSelector,
        address _receiver,
        string calldata _text,
        address _token,
        uint256 _amount
    ) external returns (bytes32 messageId) {
        // Create an EVM2AnyMessage struct
        Client.EVM2AnyMessage memory evm2AnyMessage =
            _buildCCIPMessage(_receiver, _text, _token, _amount, address(s_linkToken));

        // Get the fee required to send the CCIP message
        uint256 fees = s_router.getFee(_destinationChainSelector, evm2AnyMessage);

        if (fees > s_linkToken.balanceOf(address(this))) {
            revert NotEnoughBalance(s_linkToken.balanceOf(address(this)), fees);
        }

        // Approve the Router to transfer LINK tokens
        s_linkToken.approve(address(s_router), fees);

        // Approve the Router to spend tokens on the contract's behalf
        IERC20(_token).approve(address(s_router), _amount);

        // Send the message through the router
        messageId = s_router.ccipSend(_destinationChainSelector, evm2AnyMessage);

        // Emit an event
        emit MessageSent(
            messageId, _destinationChainSelector, _receiver, _text, _token, _amount, address(s_linkToken), fees
        );

        return messageId;
    }

    function sendMessagePayNative(
        IRouterClient s_router,
        uint64 _destinationChainSelector,
        address _receiver,
        string calldata _text,
        address _token,
        uint256 _amount
    ) external returns (bytes32 messageId) {
        // Create an EVM2AnyMessage struct
        Client.EVM2AnyMessage memory evm2AnyMessage = _buildCCIPMessage(_receiver, _text, _token, _amount, address(0));

        // Get the fee required to send the CCIP message
        uint256 fees = s_router.getFee(_destinationChainSelector, evm2AnyMessage);

        if (fees > address(this).balance) {
            revert NotEnoughBalance(address(this).balance, fees);
        }

        // Approve the Router to spend tokens on the contract's behalf
        IERC20(_token).approve(address(s_router), _amount);

        // Send the message through the router
        messageId = s_router.ccipSend{value: fees}(_destinationChainSelector, evm2AnyMessage);

        // Emit an event
        emit MessageSent(messageId, _destinationChainSelector, _receiver, _text, _token, _amount, address(0), fees);

        return messageId;
    }

    function _buildCCIPMessage(
        address _receiver,
        string calldata _text,
        address _token,
        uint256 _amount,
        address _feeTokenAddress
    ) private pure returns (Client.EVM2AnyMessage memory) {
        // Set the token amounts
        Client.EVMTokenAmount;
        // tokenAmounts[0] = Client.EVMTokenAmount({token: _token, amount: _amount});
        // Create an EVM2AnyMessage struct
        // return Client.EVM2AnyMessage({
        //     receiver: abi.encode(_receiver),
        //     data: abi.encode(_text),
        //     tokenAmounts: _amount,
        //     extraArgs: Client._argsToBytes(Client.EVMExtraArgsV1({gasLimit: 200_000})),
        //     feeToken: _feeTokenAddress
        // });
    }
}
