const {
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("PolygonPay", () => {
  const deployPolygonPay = async () => {
    const [owner, address1, address2] = await ethers.getSigners();
    const polygonPay = await ethers.deployContract("PolygonPay");
    polygonPay.waitForDeployment();
    const contract = polygonPay;
    return { contract, owner, address1, address2 };
  };

  describe("deployment", () => {
    it("should set the correct owner address", async () => {
      const { contract, owner } = await loadFixture(deployPolygonPay);
      const deployer = await contract.deployer();

      expect(deployer).to.equal(owner.address);
    });
  });

  describe("create payment plans", () => {
    it("should revert not owners calls", async () => {
      const { contract, owner, address1 } = await loadFixture(deployPolygonPay);
      const createPP = contract
        .connect(address1)
        .createPaymentPlan(
          "Top Tier plan",
          ethers.parseEther("1"),
          "monthly",
          "none"
        );
      await expect(createPP).to.be.revertedWith("You are not the deployer");
    });

    it("should create payment plan if caller is deployer", async () => {
      const { contract } = await loadFixture(deployPolygonPay);
      const createPP = await contract.createPaymentPlan(
        "Top Tier plan",
        ethers.parseEther("1"),
        "monthly",
        "none"
      );
      const paymentPlan = await contract.paymentPlans(0);
      expect(ethers.parseEther("1")).to.equal(paymentPlan[1]);
    });
  });

  describe("receive payment", () => {
    it("should fail if required price not sent", async () => {
      const { contract } = await loadFixture(deployPolygonPay);
      const createPP = await contract.createPaymentPlan(
        "Top Tier plan",
        ethers.parseEther("1"),
        "monthly",
        "none"
      );
      const pay = contract.receivePayment(
        0,
        "John",
        "Okhakumhe",
        "okhakumheknowledge@gmail.com"
      );

      await expect(pay).to.be.revertedWith("Insufficient matic sent");
    });

    it("should succeed if required price is sent", async () => {
      const { contract, owner } = await loadFixture(deployPolygonPay);
      const createPP = await contract.createPaymentPlan(
        "Top Tier plan",
        ethers.parseEther("1"),
        "monthly",
        "none"
      );
      const pay = await contract.receivePayment(
        0,
        "John",
        "Okhakumhe",
        "okhakumheknowledge@gmail.com",
        { value: ethers.parseEther("1") }
      );

      expect(await contract.payments(0)[1]).to.equal(
        await contract.paymentPlans(0)[1]
      );
    });
  });
});
