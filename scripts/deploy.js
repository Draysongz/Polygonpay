const hre = require("hardhat");
const { verify } = require("../utils/verify");
const {
  networkConfig,
  developmentChains,
  DECIMALS,
  INITIAL_ANSWER,
} = require("../helper-hardhat-config");

const main = async () => {
  const [owner, address1, address2] = await hre.ethers.getSigners();
  let priceFeedAddress;
  if (developmentChains.includes(hre.network.name)) {
    let aggregator = await hre.ethers.getContractFactory("MockV3Aggregator");
    aggregator = await aggregator.deploy(DECIMALS, INITIAL_ANSWER);
    priceFeedAddress = aggregator.target;
  } else {
    priceFeedAddress =
      networkConfig[String(hre.network.config.chainID)].maticUSDPriceFeed;
  }
  let blockpay = await hre.ethers.getContractFactory("BlockpayFactory");
  blockpay = await blockpay.deploy(priceFeedAddress);

  console.log(`Contract deployed at ${blockpay.target}`);

  if (
    !developmentChains.includes(hre.network.name) &&
    process.env.POLYGONSCAN_API_KEY
  ) {
    verify(blockpay.target, [priceFeedAddress]);
  }
};

main().catch((err) => {
  console.log(err.message);
  process.exit(1);
});
