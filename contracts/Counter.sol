// SPDX-License-Identifier: MIT
pragma solidity  0.8.30;

contract Counter {
    uint256 count;
    error CantDecrementZeroCounter();

    function increment()  external {
        count++;
    }

    function decrement() external {
        validate();
        //require(count > 0, "Count is currently zero");

        count--;
    }

    function getCount() external view returns (uint256) {
        return count;
    }

    function validate() internal view{
         if(count == 0) {
            revert CantDecrementZeroCounter();
        }
    }    
}
