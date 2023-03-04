require("@nomiclabs/hardhat-waffle");
require('dotenv').config();
// require('./scripts/hardhat.tasks.js');

const {
    MAINNET_PRIVATE_KEY,
    MAINNET_URL,
    TESTNET_PRIVATE_KEY,
    TESTNET_URL,
} = process.env;

module.exports = {
    defaultNetwork: "hardhat",
    networks: {
        hardhat: {
            // loggingEnabled: true,
        },
        // testnet: {
        //     accounts: [TESTNET_PRIVATE_KEY],
        //     url: TESTNET_URL,
        // },
        // mainnet: {
        //     accounts: [MAINNET_PRIVATE_KEY],
        //     url: MAINNET_URL,
        // }
    },
    paths: {
        sources: "./contracts",
        cache: "./build/cache",
        artifacts: "./build/artifacts",
        tests: "./hhtest",
    },
    solidity: {
        compilers: [
            {
                version: "0.8.10",
                settings: {
                    // optimizer: {
                    //     enabled: true,
                    //     runs: 1000000,
                    // }
                }
            },
        ]
    }
};
