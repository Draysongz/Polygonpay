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
    event CreatedPaymentPlanBpF(
        Blockpay blockPayContract,
        string planName,
        uint256 amount,
        uint256 contractIndex
    );
    event ReceivedPAymentBpF(
        address planCreator,
        uint256 contractIndex,
        string firstname,
        string lastname,
        string email
    );
    event WithdrawnBpF(
        address planCreator,
        uint256 contractIndex,
        uint256 withdrawnAmount
    );
    address public factoryDeployer;

    uint256 count = 0;
    AggregatorV3Interface public priceFeedAddress;

    mapping(address => Blockpay[]) addressToContract;
    mapping(address => mapping(Blockpay => uint256)) creatorToContractAddressToContractIndex;

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
        creatorToContractAddressToContractIndex[msg.sender][
            blockpayContract
        ] = count;
        emit CreatedPaymentPlanBpF(
            blockpayContract,
            _planName,
            _amountInUSD,
            count
        );
        count += 1;
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
            emit ReceivedPAymentBpF(
                _contractCreator,
                _contractIndex,
                _firstName,
                _lastname,
                _email
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

    // get the index of a blockpay contract
    function getContractIndex(
        address _contractCreator,
        address blockpayAddress
    ) public view returns (uint256) {
        Blockpay blockpayContract = Blockpay(payable(blockpayAddress));
        return
            creatorToContractAddressToContractIndex[_contractCreator][
                blockpayContract
            ];
    }

    function getPaymentplans(
        address _contractCreator
    ) public view returns (PaymentPlan[] memory) {
        PaymentPlan[] memory _paymentPlans = new PaymentPlan[](
            addressToContract[_contractCreator].length
        );
        for (
            uint256 i = 0;
            i < addressToContract[_contractCreator].length;
            i++
        ) {
            _paymentPlans[i] = addressToContract[_contractCreator][i]
                .getPaymentPlan();
        }

        return _paymentPlans;
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
        emit WithdrawnBpF(
            _contractCreator,
            _contractIndex,
            address(this).balance
        );
    }
}
