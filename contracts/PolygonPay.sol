// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract PolygonPay {
    // create Payment plans (subscription)
    // struct for paid users
    // struct for payment plans
    // receive > emit event
    // constructor function - admin
    // initialize

    event ReceivedPayment(
        uint256 paymentPlanIndex,
        uint256 amount,
        string firstName,
        string lastname,
        string email
    );

    mapping(address => mapping(uint256 => Payments[]))
        public addressToplanIndexToPayments;

    address public deployer;

    constructor() {
        deployer = msg.sender;
    }

    modifier onlyDeployer() {
        require(msg.sender == deployer, "You are not the deployer");
        _;
    }

    // store payment plans
    struct PaymentPlans {
        string planName;
        uint256 amount;
        string interval;
        string renewalSequence;
    }

    struct Payments {
        uint256 paymentPlanIndex;
        uint256 amount;
        string firstName;
        string lastName;
        string email;
    }

    PaymentPlans[] public paymentPlans;
    Payments[] public payments;

    // create payment plan
    function createPaymentPlan(
        string memory _planName,
        uint256 _amount,
        string memory _interval,
        string memory _renewalSequence
    ) public onlyDeployer {
        paymentPlans.push(
            PaymentPlans(_planName, _amount, _interval, _renewalSequence)
        );
    }

    // receive payment for certain payment plan

    function receivePayment(
        uint256 _paymentPlanIndex,
        string memory _firstName,
        string memory _lastname,
        string memory _email
    ) public payable {
        // get plan amount
        uint256 planAmount = paymentPlans[_paymentPlanIndex].amount;
        require(msg.value >= planAmount, "Insufficient matic sent");
        payments.push(
            Payments(
                _paymentPlanIndex,
                msg.value,
                _firstName,
                _lastname,
                _email
            )
        );

        mapPaymentsToAddress(
            _paymentPlanIndex,
            Payments(
                _paymentPlanIndex,
                msg.value,
                _firstName,
                _lastname,
                _email
            )
        );
    }

    function mapPaymentsToAddress(
        uint256 _paymentPlanIndex,
        Payments memory _payment
    ) public {
        addressToplanIndexToPayments[msg.sender][_paymentPlanIndex].push(
            _payment
        );
    }

    // withdraw
    function withdraw() public onlyDeployer {
        (bool sent, ) = msg.sender.call{value: address(this).balance}("");
        require(sent, "Withdrawal failed");
    }
}
