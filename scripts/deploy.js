const hre = require("hardhat");

const main = async () => {
  const [owner, address1, address2] = await hre.ethers.getSigners();
  const polygon = await hre.ethers.deployContract("Blockpay");

  polygon.waitForDeployment();

  console.log(`Contract deployed at ${polygon.target}`);
};

main().catch((err) => {
  console.log(err.message);
  process.exit(1);
});
