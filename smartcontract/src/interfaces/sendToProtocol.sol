// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface sendToProtocol {
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

    error NotEnoughBalance(uint256 currentBalance, uint256 calculatedFees);
    error NothingToWithdraw();
    error FailedToWithdrawEth(address owner, address target, uint256 value);
    error DestinationChainNotAllowed(uint64 destinationChainSelector);

    function allowlistDestinationChain(uint64 _destinationChainSelector, bool allowed) external;

    function sendMessagePayLINK(
        uint64 _destinationChainSelector,
        address _receiver,
        string calldata _text,
        address _token,
        uint256 _amount
    ) external returns (bytes32 messageId);

    function sendMessagePayNative(
        uint64 _destinationChainSelector,
        address _receiver,
        string calldata _text,
        address _token,
        uint256 _amount
    ) external returns (bytes32 messageId);

    function withdraw(address _beneficiary) external;

    function withdrawToken(address _beneficiary, address _token) external;
}
