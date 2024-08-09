import "../interfaces/sendToProtocol.sol";

abstract contract lendToken is sendToProtocol {
    // Implement the interface functions here

    function sendMessagePayLINK(
        uint64 _destinationChainSelector,
        address _receiver,
        string calldata _text,
        address _token,
        uint256 _amount
    ) external override returns (bytes32 messageId) {
        // Implementation logic here
    }

    function sendMessagePayNative(
        uint64 _destinationChainSelector,
        address _receiver,
        string calldata _text,
        address _token,
        uint256 _amount
    ) external override returns (bytes32 messageId) {
        // Implementation logic here
    }

    // Other functions implementation
}
