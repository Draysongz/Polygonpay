require("@nomicfoundation/hardhat-toolbox");
const dotenv = require("dotenv")
dotenv.config()

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.18",
  networks: {
    // mumbai:{
    //   url: process.env.MUMBAI_URL || "",
    //   accounts: [process.env.PRIVATE_KEY],
    //   chainID: '',
    //   blockConfirmations: 6
    // }
  }
};
