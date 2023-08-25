// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

error CallFromWebsite();

contract Blockpay {
    using PriceConverter for uint256;

    // create Payment plans (subscription)
    // struct for paid users
    // struct for payment plans
    // receive > emit event
    // constructor function - admin
    // initialize
    fallback() external payable {
        revert CallFromWebsite();
    }

    receive() external payable {
        revert CallFromWebsite();
    }

    event ReceivedPayment(
        uint256 amountInUSD,
        string firstName,
        string lastname,
        string email
    );

    mapping(address => Payments[]) public addressToPayments;

    address public immutable i_deployer;
    AggregatorV3Interface public priceFeedAddress;

    constructor(address _priceFeedAddress) {
        i_deployer = msg.sender;
        priceFeedAddress = AggregatorV3Interface(_priceFeedAddress);
    }

    modifier onlyDeployer() {
        require(msg.sender == i_deployer, "You are not the deployer");
        _;
    }

    // store payment plans
    struct PaymentPlan {
        string planName;
        uint256 amountInUSD;
    }

    struct Payments {
        uint256 amountInUSD;
        string firstName;
        string lastName;
        string email;
    }

    PaymentPlan public paymentPlan;
    Payments[] public payments;

    // create payment plan
    function createPaymentPlan(
        string memory _planName,
        uint256 _amountInUSD
    ) public onlyDeployer {
        paymentPlan.amountInUSD = _amountInUSD;
        paymentPlan.planName = _planName;
    }

    // receive payment for certain payment plan
    function receivePayment(
        string memory _firstName,
        string memory _lastname,
        string memory _email
    ) public payable {
        // get plan amount
        uint256 planAmount = paymentPlan.amountInUSD;
        // require the amount of matic sent in USD
        require(
            msg.value.getConversionRate(priceFeedAddress) >= planAmount,
            "Insufficient matic sent"
        );
        payments.push(Payments(msg.value, _firstName, _lastname, _email));

        mapPaymentsToAddress(
            Payments(msg.value, _firstName, _lastname, _email)
        );

        emit ReceivedPayment(msg.value, _firstName, _lastname, _email);
    }

    function mapPaymentsToAddress(Payments memory _payment) public {
        addressToPayments[msg.sender].push(_payment);
    }

    function getPayments() public view returns (Payments[] memory) {
        return addressToPayments[msg.sender];
    }

    // withdraw
    function withdraw() public onlyDeployer {
        (bool sent, ) = msg.sender.call{value: address(this).balance}("");
        require(sent, "Withdrawal failed");
    }
}
