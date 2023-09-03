// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./Blockpay.sol";
import "./Payment.sol";

error TransactionNotSent();

contract BlockpayFactory {
    using PriceConverter for uint256;
    // create new Blockpay contracts
    // assign the creator address to each contract

    address public factoryDeployer;
    // address private priceFeedAddress;
    AggregatorV3Interface public priceFeedAddress;

    mapping(address => Blockpay[]) addressToContract;

    constructor(address _priceFeedAddress) {
        factoryDeployer = msg.sender;
        priceFeedAddress = AggregatorV3Interface(_priceFeedAddress);
    }

    // create a new contract for each payment link
    // map the contract to the creator's address to keep track of
    // all his/her contracts
    function createPaymentBpF(
        string memory _planName,
        uint256 _amountInUSD
    ) public {
        Blockpay blockpayContract = new Blockpay(
            priceFeedAddress,
            msg.sender,
            address(this)
        );
        blockpayContract.createPaymentPlan(_planName, _amountInUSD, msg.sender);
        addressToContract[msg.sender].push(blockpayContract);
    }

    // receive payment
    function receivePaymentBpF(
        address _contractCreator,
        uint256 _contractIndex,
        string memory _firstName,
        string memory _lastname,
        string memory _email
    ) public payable {
        Blockpay blockpayContract = getContract(
            _contractCreator,
            _contractIndex
        );
        uint256 _amountInUSD = getPaymentPlanBpF(
            _contractCreator,
            _contractIndex
        ).amountInUSD;
        require(
            msg.value.getConversionRate(priceFeedAddress) >= _amountInUSD,
            "Insufficient Matic sent"
        );
        (bool sent, ) = address(blockpayContract).call{value: msg.value}("");
        if (sent) {
            blockpayContract.receivePayment(
                _firstName,
                _lastname,
                _email,
                msg.value,
                msg.sender
            );
        } else {
            revert TransactionNotSent();
        }
    }

    function getTotalPaymentsBpf(
        address _contractCreator,
        uint256 _contractIndex
    ) public view returns (Payments[] memory) {
        Blockpay blockpayContract = getContract(
            _contractCreator,
            _contractIndex
        );
        return blockpayContract.getPayments();
    }

    function getPaymentsPerAddressBpf(
        address _contractCreator,
        uint256 _contractIndex,
        address _user
    ) public view returns (Payments[] memory) {
        Blockpay blockpayContract = getContract(
            _contractCreator,
            _contractIndex
        );
        return blockpayContract.getPaymentsPerAddress(_user);
    }

    function conversionRateBpf(
        uint256 _maticInWEI
    ) public view returns (uint256) {
        return _maticInWEI.getConversionRate(priceFeedAddress);
    }

    function changePriceFeedAddressBpf(address _newPriceFeedAddress) public {
        priceFeedAddress = AggregatorV3Interface(_newPriceFeedAddress);
    }

    function getPaymentPlanBpF(
        address _contractCreator,
        uint256 _contractIndex
    ) public view returns (PaymentPlan memory) {
        Blockpay blockpayContract = getContract(
            _contractCreator,
            _contractIndex
        );

        return blockpayContract.getPaymentPlan();
    }

    // get contracts based creator and index
    function getContract(
        address _contractCreator,
        uint256 _contractIndex
    ) public view returns (Blockpay) {
        return addressToContract[_contractCreator][_contractIndex];
    }

    function withdrawBpf(
        address _contractCreator,
        uint256 _contractIndex
    ) public {
        Blockpay blockpayContract = getContract(
            _contractCreator,
            _contractIndex
        );
        blockpayContract.withdraw(msg.sender);
    }
}
