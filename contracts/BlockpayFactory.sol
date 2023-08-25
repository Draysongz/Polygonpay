// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../Blockpay.sol";

contract BlockpayFactory {

    // create new Blockpay contracts
    // assign the creator address to each contract
    address public factoryDeployer;
    address private priceFeedAddress;

    mapping (address =>  Blockpay[]) addressToContract;

    constructor(address _priceFeedAddress){
        factoryDeployer = msg.sender;
        priceFeedAddress = _priceFeedAddress;
    }

    // create a new contract for each payment link 
    // map the contract to the creator's address to keep track of 
    // all his/her contracts
    function createPaymentBF(string memory _planName, uint256 _amountInUSD) public {
        Blockpay blockpayContract = new Blockpay(priceFeedAddress);
        blockpayContract.createPaymentPlan(_planName, _amountInUSD);
        addressToContract[msg.sender].push(blockpayContract);
    }
}
