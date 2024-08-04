// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Counter {
    uint256 public number;

    function setNumber(uint256 newNumber1) public {
        number = newNumber1;
    }

    function increment() public {
        number++;
    }
}
