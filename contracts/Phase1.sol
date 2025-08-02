// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
import "./IStreamingContractV1.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";



contract StreamingContractV1 is IStreamingContractV1{
    
    uint256 public nextStreamId;
    mapping(uint256 => Stream) public streams;

    // Create a new ETH stream (totalAmount comes from msg.value)
    //withdrawnAmount označava koliko ETH je već povučeno iz tog streama do sada.
    function createStream(
        address recipient,
        uint256 startTime,
        uint256 endTime
    ) external payable returns (uint256 streamId){
        require(recipient != address(0), "Invalid recipient");
        require(msg.value > 0, "No ETH sent");
        require(startTime < endTime, "Invalid time range");
        require(startTime >= block.timestamp, "Stream already started");

        streamId = nextStreamId++;

        streams[streamId] = Stream({
            recipient: recipient,
            sender: msg.sender,
            startTime: startTime,
            endTime: endTime,
            totalAmount: msg.value,
            withdrawnAmount: 0,
            tokenAddress: address(0),
            cancelled: false
        });

        emit StreamCreated(
            streamId,
            msg.sender,
            recipient,
            msg.value,
            startTime,
            endTime
        );
        return streamId;
    }

    function createTokenStream(
        address recipient,
        address tokenAddress,
        uint256 totalAmount,
        uint256 startTime,
        uint256 endTime
    ) external returns (uint256 streamId) {
        require(recipient != address(0), "Invalid recipient");
        require(tokenAddress != address(0), "Token address required"); // address(0) je ETH
        require(totalAmount > 0, "Amount must be > 0");
        require(endTime > startTime, "Invalid time range");
        require(startTime >= block.timestamp, "Start time in the past");

        IERC20(tokenAddress).transferFrom(
            msg.sender,
            address(this),
            totalAmount
        );
        streamId = nextStreamId++;
        streams[streamId] = Stream({
            recipient: recipient,
            sender: msg.sender,
            startTime: startTime,
            endTime: endTime,
            totalAmount: totalAmount,
            withdrawnAmount: 0,
            tokenAddress: tokenAddress,
            cancelled: false
        });

        emit StreamCreated(
            streamId,
            msg.sender,
            recipient,
            totalAmount,
            startTime,
            endTime
        );
        return streamId;
    }

    function cancelStream(uint256 streamId) external{
        Stream memory stream = getStream(streamId);
        require(!stream.cancelled, "Stream already cancelled");
        require(msg.sender == stream.sender, "Only sender can cancel");

        uint256 withdrawable = calculateWithdrawableAmount(streamId);
        require(withdrawable > 0, "Nothing to withdraw");

        uint256 amountOwedToRecipient = withdrawable - stream.withdrawnAmount;
        uint256 amountOwedToSender = stream.totalAmount - withdrawable;

        stream.cancelled = true;

        if (amountOwedToRecipient > 0) {
            if (stream.tokenAddress == address(0)) {
                // ETH
                payable(stream.recipient).transfer(amountOwedToRecipient);
            } else {
                IERC20(stream.tokenAddress).transfer(stream.recipient, amountOwedToRecipient);
            }
        }

        if (amountOwedToSender > 0) {
            if (stream.tokenAddress == address(0)) {
                // ETH
                payable(stream.sender).transfer(amountOwedToSender);
            } else {
                IERC20(stream.tokenAddress).transfer(stream.sender, amountOwedToSender);
            }
        }

        emit StreamCancelled(streamId, amountOwedToRecipient, amountOwedToSender);
    }
    // Withdraw available funds from a stream
    //Funkcija dozvoljava recipientu da povuče ETH koji im pripada u ovom trenutku iz streama.
    function withdrawFromStream(uint256 streamId) external{
        Stream memory stream = getStream(streamId);

        require(msg.sender == stream.recipient, "Not the recipient");
        require(block.timestamp >= stream.startTime, "Stream hasn't started yet");
        require(block.timestamp <= stream.endTime, "Stream has ended");

        uint256 withdrawable = calculateWithdrawableAmount(streamId);
        require(withdrawable > 0, "Nothing to withdraw");

        stream.withdrawnAmount += withdrawable;
        (bool sent, bytes memory data) = stream.recipient.call{value: withdrawable}("");
        require(sent, "Failed to send Ether");

        emit Withdrawal(streamId, stream.recipient, withdrawable);
    }

    // View stream details
    function getStream(uint256 streamId) public view returns (Stream memory){
        return streams[streamId];
    }

    // Check withdrawable amount
    function calculateWithdrawableAmount(uint256 streamId) public view returns (uint256){
        Stream memory stream = getStream(streamId);
        if (block.timestamp < stream.startTime) {
            return 0;
        }

        uint256 elapsedTime;
        if (block.timestamp >= stream.endTime) {
            elapsedTime = stream.endTime - stream.startTime;
        } else {
            elapsedTime = block.timestamp - stream.startTime;
        }

        uint256 totalDuration = stream.endTime - stream.startTime;
        uint256 unlockedAmount = (stream.totalAmount * elapsedTime) / totalDuration;

        if (unlockedAmount <= stream.withdrawnAmount) {
            return 0;
        }

        return unlockedAmount - stream.withdrawnAmount;
    }

}