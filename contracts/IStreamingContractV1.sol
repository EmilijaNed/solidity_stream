// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

interface IStreamingContractV1 {
    struct Stream {
        address recipient;
        address sender;
        uint256 startTime;
        uint256 endTime;
        uint256 totalAmount;
        uint256 withdrawnAmount;
        address tokenAddress; // address(0) for ETH
        bool cancelled;
    }

    event StreamCreated(
        uint256 indexed streamId,
        address indexed sender,
        address indexed recipient,
        uint256 totalAmount,
        uint256 startTime,
        uint256 endTime
    );

    event StreamCancelled(
    uint256 indexed streamId,
    uint256 recipientBalance,
    uint256 senderBalance
    );
    
    event Withdrawal(
        uint256 indexed streamId,
        address indexed recipient,
        uint256 amount
    );

    // Create a new ETH stream (totalAmount comes from msg.value)
    function createStream(
        address recipient,
        uint256 startTime,
        uint256 endTime
    ) external payable returns (uint256 streamId);

    // Create a stream with ERC-20 tokens
    function createTokenStream(
        address recipient,
        address tokenAddress,
        uint256 totalAmount,
        uint256 startTime,
        uint256 endTime
    ) external returns (uint256 streamId);

    // Cancel a stream (only sender can call)
    function cancelStream(uint256 streamId) external;

    // Withdraw available funds from a stream
    function withdrawFromStream(uint256 streamId) external;

    // View stream details
    function getStream(uint256 streamId) external view returns (Stream memory);

    // Check withdrawable amount
    function calculateWithdrawableAmount(uint256 streamId) external view returns (uint256);
}