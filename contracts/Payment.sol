// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

struct Payments {
    uint256 amountInUSD;
    string firstName;
    string lastName;
    string email;
}

// store payment plans
struct PaymentPlan {
    string planName;
    uint256 amountInUSD;
}
