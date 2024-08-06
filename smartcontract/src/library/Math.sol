// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library Math {
    /**
     * @notice Calculates the interest owed by a borrower
     * @param principal The principal amount borrowed
     * @param annualInterestRate The annual interest rate in basis points (e.g., 5% = 500 basis points)
     * @param duration The duration of the borrow in seconds
     * @return The amount of interest owed
     */
    function calculateBorrowInterest(uint256 principal, uint256 annualInterestRate, uint256 duration)
        external
        pure
        returns (uint256)
    {
        uint256 ratePerSecond = annualInterestRate / 365 days;
        return (principal * ratePerSecond * duration) / 10000;
    }

    /**
     * @notice Calculates the interest earned by a lender
     * @param principal The principal amount lent
     * @param annualInterestRate The annual interest rate in basis points (e.g., 5% = 500 basis points)
     * @param duration The duration of the lend in seconds
     * @return The amount of interest earned
     */
    function calculateLendersInterest(uint256 principal, uint256 annualInterestRate, uint256 duration)
        external
        pure
        returns (uint256)
    {
        uint256 ratePerSecond = annualInterestRate / 365 days;
        return (principal * ratePerSecond * duration) / 10000;
    }
}
