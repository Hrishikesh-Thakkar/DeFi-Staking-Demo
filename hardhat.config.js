/**
 * @type import('hardhat/config').HardhatUserConfig
 */
require("@nomiclabs/hardhat-waffle")
require("hardhat-deploy")
module.exports = {
  solidity: "0.8.7",
  namedAccounts: {
    deployer: {
        default: 0,
    }
  }
};
